import { Global, Module } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../services/notifications.service';
import { EmailService } from './email.service';
import { DeveloperAlertService } from './developer-alert.service';
import { VerificationReminderService } from './verification-reminder.service';
import { AppUpdateNotificationService } from './app-update-notification.service';
import { NotificationsController } from './notifications.controller';

@Global()
@Module({
  controllers: [NotificationsController],
  providers: [
    PrismaService,
    NotificationsService,
    EmailService,
    DeveloperAlertService,
    VerificationReminderService,
    AppUpdateNotificationService,
  ],
  exports: [
    EmailService,
    DeveloperAlertService,
    VerificationReminderService,
    AppUpdateNotificationService,
    NotificationsService,
  ],
})
export class NotificationsModule {}
