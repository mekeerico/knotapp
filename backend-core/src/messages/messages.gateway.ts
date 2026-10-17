import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AIService } from '../ai/ai.service';
import { NotificationsService } from '../services/notifications.service';

@WebSocketGateway({ cors: true })
export class MessagesGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private readonly logger = new Logger(MessagesGateway.name);
  private readonly activeConnections = new Map<string, string>(); // userId -> socketId

  constructor(
    private readonly prisma: PrismaService,
    private readonly aiService: AIService,
    private readonly notificationsService: NotificationsService,
  ) {}

  handleConnection(client: Socket) {
    const userId = (client.handshake.query.userId || client.handshake.auth?.userId) as string;
    if (userId) {
      this.activeConnections.set(userId, client.id);
      this.logger.log(`User ${userId} connected with socket ${client.id}`);
    }
  }

  handleDisconnect(client: Socket) {
    for (const [userId, socketId] of this.activeConnections.entries()) {
      if (socketId === client.id) {
        this.activeConnections.delete(userId);
        this.logger.log(`User ${userId} disconnected`);
        break;
      }
    }
  }

  isUserOnline(userId: string): boolean {
    return this.activeConnections.has(userId);
  }

  /** Push a message saved via REST to both participants if they are online. */
  notifyNewMessage(message: { senderId: string; receiverId: string }) {
    for (const uid of [message.receiverId, message.senderId]) {
      const sid = this.activeConnections.get(uid);
      if (sid) {
        this.server.to(sid).emit('receiveMessage', message);
        this.server.to(sid).emit('messageReceived', message);
      }
    }
  }

  @SubscribeMessage('sendMessage')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { senderId?: string; receiverId: string; content?: string; text?: string },
  ) {
    const content = payload.content || payload.text || '';
    let senderId = payload.senderId;

    if (!senderId) {
      for (const [uid, sid] of this.activeConnections.entries()) {
        if (sid === client.id) {
          senderId = uid;
          break;
        }
      }
      if (!senderId) {
        senderId = (client.handshake.query.userId || client.handshake.auth?.userId) as string;
      }
    }

    if (!senderId || !payload.receiverId || !content.trim()) {
      this.logger.warn(`Invalid message payload: ${JSON.stringify(payload)}`);
      return;
    }

    this.logger.log(`Message from ${senderId} to ${payload.receiverId}`);

    // Fetch previous messages for context moderation
    const history = await this.prisma.message.findMany({
      where: {
        OR: [
          { senderId, receiverId: payload.receiverId },
          { senderId: payload.receiverId, receiverId: senderId },
        ],
      },
      take: 10,
      orderBy: { createdAt: 'desc' },
    });

    const conversationTranscript = history
      .reverse()
      .map((m) => ({
        role: m.senderId === senderId ? 'user' : 'model',
        text: m.content,
      }));
    
    // Add current message to validation context
    conversationTranscript.push({ role: 'user', text: content });

    // AI Real-time Moderation check
    const modResult = await this.aiService.checkModeration(conversationTranscript);

    // Save message to database
    const savedMessage = await this.prisma.message.create({
      data: {
        senderId,
        receiverId: payload.receiverId,
        content,
        aiModerationStatus: modResult.status,
        flagReason: modResult.reason || null,
      },
    });

    // Deduct trust score if flagged
    if (modResult.status === 'FLAGGED') {
      await this.prisma.user.update({
        where: { id: senderId },
        data: {
          trustScore: {
            decrement: modResult.trustDeduction || 20,
          },
        },
      });
    }

    // Emit back to sender (both events for full cross-platform compatibility)
    client.emit('messageReceived', savedMessage);
    client.emit('receiveMessage', savedMessage);

    // Forward to receiver if online
    const receiverSocketId = this.activeConnections.get(payload.receiverId);
    if (receiverSocketId) {
      this.server.to(receiverSocketId).emit('messageReceived', savedMessage);
      this.server.to(receiverSocketId).emit('receiveMessage', savedMessage);
      
      // If message is safe, generate a smart AI Conversation Assistant Icebreaker / Prompter
      if (modResult.status === 'SAFE') {
        const prompterResponse = await this.aiService.getCoachResponse(
          conversationTranscript,
          { name: 'KNOT member' } as any, // Mock passing partial profile context
          "Suggest a subtle, warm conversation prompt or icebreaker about their compatibility traits."
        );
        
        // Emit AI assistant tip
        this.server.to(receiverSocketId).emit('aiMessageTip', {
          tip: prompterResponse,
        });
      }
    } else {
      // Receiver is offline, send push notification
      const receiver = await this.prisma.user.findUnique({
        where: { id: payload.receiverId },
        select: { pushToken: true }
      });
      const sender = await this.prisma.user.findUnique({
        where: { id: senderId },
        select: { firstName: true }
      });

      if (receiver?.pushToken && sender) {
        // Send push notification
        await this.notificationsService.sendPushNotification(
          receiver.pushToken,
          `New message from ${sender.firstName}`,
          content,
          { url: `knot://chat/${senderId}` }
        );
      }
    }
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { senderId: string; receiverId: string; isTyping: boolean },
  ) {
    const receiverSocketId = this.activeConnections.get(payload.receiverId);
    if (receiverSocketId) {
      this.server.to(receiverSocketId).emit('typingStatus', {
        senderId: payload.senderId,
        isTyping: payload.isTyping,
      });
    }
  }
}
