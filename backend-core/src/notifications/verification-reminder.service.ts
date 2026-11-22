import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../services/notifications.service';
import { EmailService } from './email.service';
import { DeveloperAlertService } from './developer-alert.service';

@Injectable()
export class VerificationReminderService
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(VerificationReminderService.name);
  private intervalTimer: NodeJS.Timeout | null = null;
  private startupTimer: NodeJS.Timeout | null = null;
  private isRunning = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly emailService: EmailService,
    private readonly pushService: NotificationsService,
    private readonly devAlertService: DeveloperAlertService,
  ) {}

  onModuleInit() {
    // Check once 2 minutes after startup, then every hour.
    // Per-user 24-hour guard (`lastVerificationReminderAt`) guarantees at most 1 reminder per day per unverified user.
    this.startupTimer = setTimeout(() => {
      this.sendDailyVerificationReminders().catch((err) =>
        this.logger.error(`Daily reminder startup error: ${err?.message || err}`),
      );
    }, 2 * 60 * 1000);

    this.intervalTimer = setInterval(() => {
      this.sendDailyVerificationReminders().catch((err) =>
        this.logger.error(`Daily reminder interval error: ${err?.message || err}`),
      );
    }, 60 * 60 * 1000);
  }

  onModuleDestroy() {
    if (this.startupTimer) clearTimeout(this.startupTimer);
    if (this.intervalTimer) clearInterval(this.intervalTimer);
  }

  async sendDailyVerificationReminders(force = false): Promise<{
    eligibleCount: number;
    inAppSent: number;
    emailsSent: number;
    pushSent: number;
  }> {
    if (this.isRunning) {
      return { eligibleCount: 0, inAppSent: 0, emailsSent: 0, pushSent: 0 };
    }
    this.isRunning = true;

    let inAppSent = 0;
    let emailsSent = 0;
    let pushSent = 0;

    try {
      const now = new Date();
      const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      const sixHoursAgo = new Date(now.getTime() - 6 * 60 * 60 * 1000);

      const whereClause: any = {
        isVerified: false,
        isSuspended: false,
        role: 'USER',
      };

      if (!force) {
        whereClause.AND = [
          { createdAt: { lte: sixHoursAgo } },
          {
            OR: [
              { lastVerificationReminderAt: null },
              { lastVerificationReminderAt: { lte: twentyFourHoursAgo } },
            ],
          },
        ];
      }

      const unverifiedUsers = await this.prisma.user.findMany({
        where: whereClause,
        select: {
          id: true,
          email: true,
          firstName: true,
          pushToken: true,
          preferredGender: true,
        },
        take: 200,
      });

      if (unverifiedUsers.length === 0) {
        return { eligibleCount: 0, inAppSent: 0, emailsSent: 0, pushSent: 0 };
      }

      const verifiedCount = await this.prisma.user.count({
        where: { isVerified: true, isSuspended: false, role: 'USER' },
      });

      const matchesWaitingPhrase =
        verifiedCount >= 5
          ? `${verifiedCount}+ verified matches are waiting for you`
          : 'so many verified matches are waiting for you';

      for (const user of unverifiedUsers) {
        const displayName = user.firstName?.trim() || 'there';
        const title = 'Verify Your Profile — Matches Are Waiting!';
        const body = `Hi ${displayName}, your profile is still hidden because you haven't completed identity verification yet. Verify your identity today to make your profile public — ${matchesWaitingPhrase} on KNOT!`;

        // 1. In-App Notification (persisted in DB for both Mobile & Web)
        try {
          await this.prisma.notification.create({
            data: {
              userId: user.id,
              title,
              body,
              category: 'verification',
              actionRoute: '/verification',
              actionLabel: 'Verify Now',
            },
          });
          inAppSent += 1;
        } catch (err: any) {
          this.logger.warn(
            `Failed creating in-app verification reminder for ${user.id}: ${err?.message}`,
          );
        }

        // 2. Email Notification via Resend
        if (user.email) {
          const html = `
            <div style="background-color:#0A0E14;color:#F5F5F1;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;padding:40px 20px;text-align:center;">
              <div style="max-width:520px;margin:0 auto;background-color:#121721;border:1px solid rgba(212,175,55,0.35);border-radius:24px;padding:36px 28px;">
                <h1 style="font-family:Georgia,serif;font-size:28px;letter-spacing:3px;color:#F5F5F1;margin:0 0 8px 0;">
                  KNOT<span style="color:#D4AF37;">.</span>
                </h1>
                <p style="font-size:11px;letter-spacing:2px;text-transform:uppercase;color:#D4AF37;font-weight:700;margin:0 0 24px 0;">
                  Where True Relationship Leads to Vow
                </p>
                <h2 style="font-size:21px;color:#FFFFFF;margin:0 0 14px 0;">
                  Your Matches Are Waiting for You, ${this.escapeHtml(displayName)}!
                </h2>
                <p style="font-size:14px;color:#CBD5E1;line-height:1.65;margin:0 0 20px 0;">
                  Your KNOT profile is currently <strong>private</strong> because your identity verification is not yet complete.
                </p>
                <p style="font-size:14px;color:#CBD5E1;line-height:1.65;margin:0 0 28px 0;">
                  Complete your quick verification now to make your profile public and unlock curated introductions — <strong style="color:#E27D8D;">${this.escapeHtml(matchesWaitingPhrase)}</strong>!
                </p>
                <a href="https://knotmarriage.online/dashboard" style="display:inline-block;background:linear-gradient(135deg,#D4AF37,#AA7C11);color:#0A0E14;font-weight:800;font-size:14px;letter-spacing:0.5px;text-decoration:none;padding:14px 32px;border-radius:999px;">
                  Verify &amp; Make Profile Public
                </a>
                <p style="font-size:12px;color:#64748B;margin:28px 0 0 0;line-height:1.5;">
                  Once verified, you will earn the Gold Verification Seal and stop receiving daily verification reminders.
                </p>
              </div>
            </div>
          `;

          const sent = await this.emailService.sendEmail({
            to: user.email,
            subject:
              'Verify your KNOT profile — so many matches are waiting for you!',
            html,
          });
          if (sent) emailsSent += 1;
        }

        // 3. Push notification if the user has a registered push token
        if (user.pushToken) {
          try {
            await this.pushService.sendPushNotification(
              user.pushToken,
              title,
              body,
              { route: '/verification', type: 'verification_reminder' },
            );
            pushSent += 1;
          } catch (_) {}
        }

        // 4. Stamp lastVerificationReminderAt so this user is reminded at most once every 24h
        await this.prisma.user.update({
          where: { id: user.id },
          data: { lastVerificationReminderAt: now },
        });
      }

      this.logger.log(
        `Daily verification reminders processed: eligible=${unverifiedUsers.length}, inApp=${inAppSent}, emails=${emailsSent}, push=${pushSent}`,
      );

      return {
        eligibleCount: unverifiedUsers.length,
        inAppSent,
        emailsSent,
        pushSent,
      };
    } catch (err: any) {
      this.logger.error(
        `Daily verification reminders failed: ${err?.message || err}`,
      );
      await this.devAlertService.sendAlert({
        key: 'cron:verification-reminders',
        severity: 'ERROR',
        source: 'scheduler/verification-reminders',
        title: 'Daily Verification Reminder Job Failed',
        message:
          'The daily reminder job for unverified users encountered an error.',
        details: err?.stack || err?.message || String(err),
      });
      throw err;
    } finally {
      this.isRunning = false;
    }
  }

  private escapeHtml(str: string): string {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
}
