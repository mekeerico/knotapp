import {
  Controller,
  Get,
  Patch,
  Post,
  Param,
  Req,
  UseGuards,
  Body,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '@prisma/client';
import { VerificationReminderService } from './verification-reminder.service';
import { DeveloperAlertService } from './developer-alert.service';
import { AppUpdateNotificationService } from './app-update-notification.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly verificationReminderService: VerificationReminderService,
    private readonly devAlertService: DeveloperAlertService,
    private readonly appUpdateService: AppUpdateNotificationService,
  ) {}

  @Get()
  async getMyNotifications(@Req() req: any) {
    const userId = req.user.userId || req.user.id;
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  @Patch(':id/read')
  async markAsRead(@Req() req: any, @Param('id') id: string) {
    const userId = req.user.userId || req.user.id;
    await this.prisma.notification.updateMany({
      where: { id, userId },
      data: { isRead: true },
    });
    return { success: true };
  }

  @Patch('read-all')
  async markAllAsRead(@Req() req: any) {
    const userId = req.user.userId || req.user.id;
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
    return { success: true };
  }

  // --- Admin / Developer endpoints ---

  @Post('admin/trigger-verification-reminders')
  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  async triggerVerificationReminders(@Body('force') force?: boolean) {
    const result =
      await this.verificationReminderService.sendDailyVerificationReminders(
        Boolean(force),
      );
    return { success: true, ...result };
  }

  @Get('admin/system-alerts')
  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  async getSystemAlerts() {
    return this.prisma.systemAlert.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  @Patch('admin/system-alerts/:id/resolve')
  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  async resolveSystemAlert(@Param('id') id: string) {
    const updated = await this.prisma.systemAlert.update({
      where: { id },
      data: { resolved: true, resolvedAt: new Date() },
    });
    return { success: true, alert: updated };
  }

  @Post('admin/test-developer-alert')
  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  async sendTestDeveloperAlert() {
    const result = await this.devAlertService.sendAlert({
      key: `test:${Date.now()}`,
      severity: 'INFO',
      source: 'admin/test',
      title: 'KNOT Developer Alert Test',
      message:
        'Your developer alert pipeline is active. You will be notified immediately of server 5xx errors, database issues, or public API outages before users are cut off.',
      cooldownMs: 0,
    });
    return {
      success: true,
      developerEmail: this.devAlertService.getDeveloperEmail(),
      ...result,
    };
  }

  @Get('app-version')
  async getLatestAppVersion() {
    const latest = await this.appUpdateService.getLatestRelease();
    return {
      latestVersion: latest?.version || process.env.APP_LATEST_VERSION || null,
      storeUrl: latest?.storeUrl || this.appUpdateService.getPlayStoreUrl(),
      releaseNotes: latest?.releaseNotes || '',
      notifiedAt: latest?.notifiedAt || null,
    };
  }

  @Post('admin/check-play-store')
  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  async checkPlayStoreUpdate() {
    const result = await this.appUpdateService.checkAndNotifyPlayStoreUpdate();
    return { success: true, ...result };
  }

  @Post('admin/announce-app-update')
  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  async announceAppUpdate(
    @Body()
    body: {
      version: string;
      releaseNotes?: string;
      storeUrl?: string;
      platform?: string;
      forceResend?: boolean;
    },
  ) {
    const result = await this.appUpdateService.announceAppUpdate(body);
    return { success: true, ...result };
  }
}
