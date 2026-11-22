import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import axios from 'axios';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../services/notifications.service';
import { EmailService } from './email.service';
import { DeveloperAlertService } from './developer-alert.service';

@Injectable()
export class AppUpdateNotificationService
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(AppUpdateNotificationService.name);
  private intervalTimer: NodeJS.Timeout | null = null;
  private startupTimer: NodeJS.Timeout | null = null;
  private isChecking = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly emailService: EmailService,
    private readonly pushService: NotificationsService,
    private readonly devAlertService: DeveloperAlertService,
  ) {}

  getPlayStorePackageId(): string {
    return (
      process.env.PLAY_STORE_PACKAGE_ID || 'com.cleanconnect.knot'
    ).trim();
  }

  getPlayStoreUrl(): string {
    const pkg = this.getPlayStorePackageId();
    return (
      process.env.PLAY_STORE_URL ||
      `https://play.google.com/store/apps/details?id=${pkg}`
    ).trim();
  }

  onModuleInit() {
    // Check Play Store & env version 3 minutes after boot, then every 6 hours
    this.startupTimer = setTimeout(() => {
      this.checkAndNotifyPlayStoreUpdate().catch((err) =>
        this.logger.warn(
          `Startup Play Store update check error: ${err?.message || err}`,
        ),
      );
    }, 3 * 60 * 1000);

    this.intervalTimer = setInterval(() => {
      this.checkAndNotifyPlayStoreUpdate().catch((err) =>
        this.logger.warn(
          `Periodic Play Store update check error: ${err?.message || err}`,
        ),
      );
    }, 6 * 60 * 60 * 1000);
  }

  onModuleDestroy() {
    if (this.startupTimer) clearTimeout(this.startupTimer);
    if (this.intervalTimer) clearInterval(this.intervalTimer);
  }

  /**
   * Fetches the live Google Play Store listing page and extracts the currently published version string.
   */
  async fetchLivePlayStoreVersion(): Promise<string | null> {
    const pkg = this.getPlayStorePackageId();
    const url = `https://play.google.com/store/apps/details?id=${encodeURIComponent(pkg)}&hl=en&gl=US`;
    try {
      const res = await axios.get<string>(url, {
        timeout: 12000,
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
        },
        responseType: 'text',
      });
      const html = String(res.data || '');

      // Google Play embeds the current version in AF_initDataCallback JSON arrays like [[["1.0.8"]]]
      const patterns = [
        /\[\[\["(\d+\.\d+(?:\.\d+)?(?:\+\d+)?)"\]\]/,
        /"Current Version".{0,120}?(\d+\.\d+(?:\.\d+)?)/i,
        /softwareVersion["']?\s*[:=]\s*["'](\d+\.\d+(?:\.\d+)?)["']/i,
      ];

      for (const regex of patterns) {
        const match = html.match(regex);
        if (match && match[1]) {
          return match[1].trim();
        }
      }
      return null;
    } catch (err: any) {
      this.logger.warn(
        `Could not fetch Play Store page for ${pkg}: ${err?.message || err}`,
      );
      return null;
    }
  }

  /**
   * Automatically checks for a newly published Play Store version (or APP_LATEST_VERSION env override).
   * When a new version is detected that hasn't been announced yet, notifies all users via in-app + email.
   */
  async checkAndNotifyPlayStoreUpdate(): Promise<{
    detectedVersion: string | null;
    alreadyAnnounced: boolean;
    notified?: {
      usersNotified: number;
      emailsSent: number;
      pushSent: number;
    };
  }> {
    if (this.isChecking) {
      return { detectedVersion: null, alreadyAnnounced: false };
    }
    this.isChecking = true;

    try {
      const envVersion = (process.env.APP_LATEST_VERSION || '').trim();
      const livePlayVersion = await this.fetchLivePlayStoreVersion();
      const targetVersion = livePlayVersion || envVersion || null;

      if (!targetVersion) {
        return { detectedVersion: null, alreadyAnnounced: false };
      }

      const existing = await this.prisma.appRelease.findUnique({
        where: { version: targetVersion },
      });

      if (existing) {
        return { detectedVersion: targetVersion, alreadyAnnounced: true };
      }

      // If this is the very first release ever seeded into AppRelease and livePlayVersion was just detected,
      // announce it so users know the latest Play Store update is available.
      const result = await this.announceAppUpdate({
        version: targetVersion,
        storeUrl: this.getPlayStoreUrl(),
        releaseNotes:
          'A new version of KNOT is now live on Google Play with improvements, bug fixes, and enhanced stability. Update now for the best experience!',
        platform: 'ANDROID',
      });

      return {
        detectedVersion: targetVersion,
        alreadyAnnounced: false,
        notified: {
          usersNotified: result.usersNotified,
          emailsSent: result.emailsSent,
          pushSent: result.pushSent,
        },
      };
    } finally {
      this.isChecking = false;
    }
  }

  /**
   * Broadcasts an app update notification (In-App + Email + Push) to all active users for a given version.
   */
  async announceAppUpdate(params: {
    version: string;
    releaseNotes?: string;
    storeUrl?: string;
    platform?: string;
    forceResend?: boolean;
  }): Promise<{
    version: string;
    storeUrl: string;
    usersNotified: number;
    emailsSent: number;
    pushSent: number;
    alreadyExisted: boolean;
  }> {
    const version = (params.version || '').trim();
    if (!version) {
      throw new Error('Version string is required to announce an app update.');
    }

    const storeUrl = (params.storeUrl || this.getPlayStoreUrl()).trim();
    const releaseNotes =
      (params.releaseNotes || '').trim() ||
      'A new update for KNOT is now available on Google Play with new features, performance improvements, and important fixes.';
    const platform = (params.platform || 'ANDROID').trim().toUpperCase();

    const existing = await this.prisma.appRelease.findUnique({
      where: { version },
    });
    if (existing && !params.forceResend) {
      return {
        version,
        storeUrl: existing.storeUrl,
        usersNotified: existing.usersNotified,
        emailsSent: existing.emailsSent,
        pushSent: 0,
        alreadyExisted: true,
      };
    }

    const activeUsers = await this.prisma.user.findMany({
      where: { isSuspended: false },
      select: {
        id: true,
        email: true,
        firstName: true,
        pushToken: true,
      },
    });

    const title = `New KNOT Update (v${version}) Available!`;
    const body = `${releaseNotes} Tap below to update KNOT on Google Play.`;

    let usersNotified = 0;
    let emailsSent = 0;
    let pushSent = 0;

    for (const user of activeUsers) {
      const displayName = user.firstName?.trim() || 'Member';

      // 1. In-App Notification
      try {
        await this.prisma.notification.create({
          data: {
            userId: user.id,
            title,
            body,
            category: 'system',
            actionRoute: storeUrl,
            actionLabel: 'Update on Play Store',
          },
        });
        usersNotified += 1;
      } catch (err: any) {
        this.logger.warn(
          `Failed creating app update in-app notification for ${user.id}: ${err?.message}`,
        );
      }

      // 2. Email Notification via Resend
      if (user.email) {
        const html = `
          <div style="background-color:#0A0E14;color:#F5F5F1;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;padding:40px 20px;text-align:center;">
            <div style="max-width:520px;margin:0 auto;background-color:#121721;border:1px solid rgba(212,175,55,0.4);border-radius:24px;padding:36px 28px;">
              <h1 style="font-family:Georgia,serif;font-size:28px;letter-spacing:3px;color:#F5F5F1;margin:0 0 8px 0;">
                KNOT<span style="color:#D4AF37;">.</span>
              </h1>
              <p style="font-size:11px;letter-spacing:2px;text-transform:uppercase;color:#D4AF37;font-weight:700;margin:0 0 24px 0;">
                New App Update Live on Google Play
              </p>
              <h2 style="font-size:21px;color:#FFFFFF;margin:0 0 14px 0;">
                Hi ${this.escapeHtml(displayName)}, KNOT v${this.escapeHtml(version)} is Here!
              </h2>
              <p style="font-size:14px;color:#CBD5E1;line-height:1.65;margin:0 0 28px 0;">
                ${this.escapeHtml(releaseNotes)}
              </p>
              <a href="${this.escapeHtml(storeUrl)}" style="display:inline-block;background:linear-gradient(135deg,#D4AF37,#AA7C11);color:#0A0E14;font-weight:800;font-size:14px;letter-spacing:0.5px;text-decoration:none;padding:14px 32px;border-radius:999px;">
                Update KNOT on Play Store
              </a>
              <p style="font-size:12px;color:#64748B;margin:28px 0 0 0;line-height:1.5;">
                Updating ensures you have the latest security, match discovery, and messaging improvements.
              </p>
            </div>
          </div>
        `;

        const sent = await this.emailService.sendEmail({
          to: user.email,
          subject: `New KNOT App Update (v${version}) — Update Now on Google Play`,
          html,
        });
        if (sent) emailsSent += 1;
      }

      // 3. Push Notification if registered
      if (user.pushToken) {
        try {
          await this.pushService.sendPushNotification(
            user.pushToken,
            title,
            body,
            { route: storeUrl, type: 'app_update', version },
          );
          pushSent += 1;
        } catch (_) {}
      }
    }

    await this.prisma.appRelease.upsert({
      where: { version },
      create: {
        version,
        platform,
        storeUrl,
        releaseNotes,
        usersNotified,
        emailsSent,
      },
      update: {
        platform,
        storeUrl,
        releaseNotes,
        usersNotified,
        emailsSent,
        notifiedAt: new Date(),
      },
    });

    this.logger.log(
      `Announced KNOT app update v${version}: inApp=${usersNotified}, emails=${emailsSent}, push=${pushSent}`,
    );

    // Notify developer that the release broadcast completed
    await this.devAlertService
      .sendAlert({
        key: `release:announced:${version}`,
        severity: 'INFO',
        source: 'release-monitor/play-store',
        title: `Play Store Update v${version} Announced to Users`,
        message: `Detected and broadcast KNOT v${version} to all active users (In-App: ${usersNotified}, Emails: ${emailsSent}, Push: ${pushSent}).`,
        details: `Store URL: ${storeUrl}\nRelease Notes: ${releaseNotes}`,
        cooldownMs: 0,
      })
      .catch(() => {});

    return {
      version,
      storeUrl,
      usersNotified,
      emailsSent,
      pushSent,
      alreadyExisted: false,
    };
  }

  async getLatestRelease() {
    return this.prisma.appRelease.findFirst({
      orderBy: { createdAt: 'desc' },
    });
  }

  private escapeHtml(str: string): string {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
}
