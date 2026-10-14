import { Controller, Get, Post, Body, Param, Put, Query, UseGuards, Request } from '@nestjs/common';
import { MatchesService } from './matches.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { MatchStatus } from '@prisma/client';

@Controller('matches')
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  @UseGuards(JwtAuthGuard)
  @Get('daily')
  async getDaily(@Request() req: any) {
    return this.matchesService.getDailyMatches(req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('potential')
  async getPotential(@Request() req: any) {
    return this.matchesService.getDailyMatches(req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get()
  async getAllMatches(@Request() req: any) {
    return this.matchesService.getDailyMatches(req.user.id);
  }

  @Post(':id/respond')
  async respond(@Param('id') id: string, @Body('status') status: MatchStatus) {
    return this.matchesService.respondToMatch(id, status);
  }

  @UseGuards(JwtAuthGuard)
  @Post('action')
  async matchAction(@Request() req: any, @Body() body: { matchId?: string; partnerId?: string; action: string }) {
    const status = body.action === 'like' || body.action === 'CONNECT' ? MatchStatus.CONNECTED : MatchStatus.DISMISSED;
    if (body.matchId) {
      return this.matchesService.respondToMatch(body.matchId, status);
    }
    return { success: true };
  }

  @UseGuards(JwtAuthGuard)
  @Get('connected')
  async getConnected(@Request() req: any) {
    return this.matchesService.getConnectedMatches(req.user.id);
  }
}
