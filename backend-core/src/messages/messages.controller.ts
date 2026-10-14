import { Controller, Get, Query, Param, Post, Body, HttpException, HttpStatus, UseGuards, Request } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('messages')
@UseGuards(JwtAuthGuard)
export class MessagesController {
  constructor(private readonly prisma: PrismaService) {}

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
    const textContent = body.text || body.content || '';

    // Check if sender is premium
    const sender = await this.prisma.user.findUnique({ where: { id: senderId } });
    if (!sender?.isPremium) {
      // Get distinct users the sender has already messaged
      const previousMessages = await this.prisma.message.findMany({
        where: { senderId },
        select: { receiverId: true },
        distinct: ['receiverId'],
      });
      
      const distinctReceivers = previousMessages.map(m => m.receiverId);
      
      // If they have messaged someone, and it's NOT this match, block them!
      if (distinctReceivers.length >= 1 && !distinctReceivers.includes(matchId)) {
        throw new HttpException({ success: false, error: 'FREE_TIER_LIMIT' }, HttpStatus.FORBIDDEN);
      }
    }

    return this.prisma.message.create({
      data: {
        content: textContent,
        senderId,
        receiverId: matchId,
      }
    }).catch(() => ({ success: false }));
  }
}
