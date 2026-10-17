import { Controller, Get, Query, Param, Post, Body, HttpException, HttpStatus, UseGuards, Request, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { MessagesGateway } from './messages.gateway';
import { AIService } from '../ai/ai.service';

@Controller('messages')
@UseGuards(JwtAuthGuard)
export class MessagesController {
  private readonly logger = new Logger(MessagesController.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly gateway: MessagesGateway,
    private readonly aiService: AIService,
  ) {}

  @Get('history')
  async getChatHistory(@Query('userAId') userAId: string, @Query('userBId') userBId: string) {
    return this.prisma.message.findMany({
      where: {
        OR: [
          { senderId: userAId, receiverId: userBId },
          { senderId: userBId, receiverId: userAId },
        ],
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  @Get(':matchId')
  async getMessagesForMatch(@Param('matchId') matchId: string, @Request() req: any) {
    const userId = req.user.id;
    return this.prisma.message.findMany({
      where: {
        OR: [
          { senderId: userId, receiverId: matchId },
          { senderId: matchId, receiverId: userId },
        ],
      },
      orderBy: { createdAt: 'asc' },
    }).catch(() => []);
  }

  @Post()
  async sendDirectMessage(
    @Request() req: any,
    @Body() body: { receiverId?: string; matchId?: string; content?: string; text?: string }
  ) {
    const targetMatchId = body.receiverId || body.matchId;
    if (!targetMatchId) {
      throw new HttpException('Missing receiverId', HttpStatus.BAD_REQUEST);
    }
    return this.sendMessage(targetMatchId, req, { text: body.content || body.text || '' });
  }

  @Post(':matchId')
  async sendMessage(
    @Param('matchId') matchId: string,
    @Request() req: any,
    @Body() body: { text?: string; content?: string }
  ) {
    const senderId = req.user.id;
    const textContent = (body.text || body.content || '').trim();
    if (!textContent) {
      throw new HttpException('Message content cannot be empty', HttpStatus.BAD_REQUEST);
    }

    const sender = await this.prisma.user.findUnique({ where: { id: senderId } });
    if (!sender?.isPremium) {
      const previousMessages = await this.prisma.message.findMany({
        where: { senderId },
        select: { receiverId: true },
        distinct: ['receiverId'],
      });
      const distinctReceivers = previousMessages.map(m => m.receiverId);
      if (distinctReceivers.length >= 20 && !distinctReceivers.includes(matchId)) {
        throw new HttpException({ success: false, error: 'FREE_TIER_LIMIT' }, HttpStatus.FORBIDDEN);
      }
    }

    try {
      const saved = await this.prisma.message.create({
        data: {
          content: textContent,
          senderId,
          receiverId: matchId,
        },
      });
      this.gateway.notifyNewMessage(saved);

      // If the matched candidate is not actively connected on a live WebSocket
      // (e.g. seeded/curated candidate or offline partner), generate an authentic
      // in-character reply so the conversation flows naturally.
      if (!this.gateway.isUserOnline(matchId)) {
        this.triggerCandidateAutoReply(sender, matchId, textContent).catch((err) => {
          this.logger.warn(`Auto-reply notice for match ${matchId}: ${err.message}`);
        });
      }

      return saved;
    } catch (e: any) {
      throw new HttpException(
        { success: false, error: 'SEND_FAILED', message: e.message },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  private async triggerCandidateAutoReply(sender: any, partnerId: string, latestText: string) {
    const partner = await this.prisma.user.findUnique({ where: { id: partnerId } });
    if (!partner) return;

    // Brief human-like typing pause (~1.2s)
    await new Promise((resolve) => setTimeout(resolve, 1200));

    const history = await this.prisma.message.findMany({
      where: {
        OR: [
          { senderId: sender.id, receiverId: partnerId },
          { senderId: partnerId, receiverId: sender.id },
        ],
      },
      orderBy: { createdAt: 'asc' },
      take: 10,
    });

    const replyContent = await this.aiService.generatePartnerReply(
      sender,
      partner,
      history,
      latestText,
    );

    if (!replyContent) return;

    const replySaved = await this.prisma.message.create({
      data: {
        content: replyContent,
        senderId: partnerId,
        receiverId: sender.id,
      },
    });

    this.gateway.notifyNewMessage(replySaved);
  }
}
