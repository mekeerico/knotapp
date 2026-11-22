import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import axios from 'axios';
import { PrismaService } from '../prisma/prisma.service';
import { EmailService } from './email.service';

export type AlertSeverity = 'INFO' | 'WARNING' | 'ERROR' | 'CRITICAL';

export interface DeveloperAlertPayload {
  key: string;
  severity: AlertSeverity;
  source: string;
  title: string;
  message: string;
  details?: string;
  cooldownMs?: number;
}

@Injectable()
export class DeveloperAlertService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DeveloperAlertService.name);
  private readonly lastSentByKey = new Map<string, number>();
  private readonly suppressedCountByKey = new Map<string, number>();
  private readonly activeIncidents = new Set<string>();
  private healthTimer: NodeJS.Timeout | null = null;
  private startupTimer: NodeJS.Timeout | null = null;

  private readonly defaultCooldownMs = 15 * 60 * 1000; // 15 minutes per unique alert key

  constructor(
    private readonly prisma: PrismaService,
    private readonly emailService: EmailService,
  ) {}

  getDeveloperEmail(): string {
    return (
      process.env.DEVELOPER_ALERT_EMAIL || 'johnmeke2013@gmail.com'
    ).trim();
  }

  onModuleInit() {
    // Run proactive health watchdog every 5 minutes (first check 60s after boot)
    this.startupTimer = setTimeout(() => {
      this.runHealthWatchdog().catch((err) =>
        this.logger.error(`Health watchdog error: ${err?.message || err}`),
      );
    }, 60 * 1000);

    this.healthTimer = setInterval(() => {
      this.runHealthWatchdog().catch((err) =>
        this.logger.error(`Health watchdog error: ${err?.message || err}`),
      );
    }, 5 * 60 * 1000);
  }

  onModuleDestroy() {
    if (this.startupTimer) clearTimeout(this.startupTimer);
    if (this.healthTimer) clearInterval(this.healthTimer);
  }

  async sendAlert(payload: DeveloperAlertPayload): Promise<{
    sent: boolean;
    channels: string[];
    throttled?: boolean;
  }> {
    const cooldown = payload.cooldownMs ?? this.defaultCooldownMs;
    const now = Date.now();
    const lastSent = this.lastSentByKey.get(payload.key) ?? 0;

    if (cooldown > 0 && now - lastSent < cooldown) {
      this.suppressedCountByKey.set(
        payload.key,
        (this.suppressedCountByKey.get(payload.key) ?? 0) + 1,
      );
      return { sent: false, channels: [], throttled: true };
    }

    const suppressed = this.suppressedCountByKey.get(payload.key) ?? 0;
    this.lastSentByKey.set(payload.key, now);
    this.suppressedCountByKey.delete(payload.key);

    const extraNote =
      suppressed > 0
        ? `\n\n(${suppressed} similar occurrence(s) suppressed during cooldown)`
        : '';
    const fullDetails = `${payload.details || ''}${extraNote}`.trim();

    const channelsSent: string[] = [];

    // 1. Email to developer (johnmeke2013@gmail.com by default)
    const devEmail = this.getDeveloperEmail();
    const severityColors: Record<AlertSeverity, string> = {
      INFO: '#38BDF8',
      WARNING: '#F59E0B',
      ERROR: '#EF4444',
      CRITICAL: '#DC2626',
    };
    const badgeColor = severityColors[payload.severity] || '#EF4444';
    const timestamp = new Date().toISOString();

    const emailHtml = `
      <div style="background-color:#0A0E14;color:#F5F5F1;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;padding:32px 20px;">
        <div style="max-width:600px;margin:0 auto;background-color:#121721;border:1px solid ${badgeColor};border-radius:16px;padding:28px;">
          <div style="display:inline-block;background-color:${badgeColor};color:#FFFFFF;font-size:11px;font-weight:800;letter-spacing:1.2px;padding:4px 10px;border-radius:6px;text-transform:uppercase;margin-bottom:14px;">
            ${payload.severity} • ${payload.source}
          </div>
          <h2 style="margin:0 0 12px 0;color:#FFFFFF;font-size:20px;">${this.escapeHtml(payload.title)}</h2>
          <p style="margin:0 0 16px 0;color:#CBD5E1;font-size:14px;line-height:1.6;">
            ${this.escapeHtml(payload.message)}
          </p>
          ${
            fullDetails
              ? `<pre style="background-color:#0A0E14;border:1px solid rgba(148,163,184,0.2);border-radius:10px;padding:14px;color:#FCA5A5;font-size:12px;overflow-x:auto;white-space:pre-wrap;word-break:break-word;margin:0 0 16px 0;">${this.escapeHtml(fullDetails.slice(0, 3500))}</pre>`
              : ''
          }
          <p style="margin:0;color:#64748B;font-size:12px;">
            Detected at ${timestamp} • KNOT Automated Developer Monitor
          </p>
        </div>
      </div>
    `;

    const emailOk = await this.emailService.sendEmail({
      to: devEmail,
      subject: `[KNOT ${payload.severity}] ${payload.title}`,
      html: emailHtml,
      from: 'KNOT Monitor <noreply@knotmarriage.online>',
    });
    if (emailOk) {
      channelsSent.push(`email:${devEmail}`);
    }

    // 2. Optional Webhook (Discord / Slack / custom webhook)
    const webhookUrl = (process.env.DEV_ALERT_WEBHOOK_URL || '').trim();
    if (webhookUrl) {
      try {
        const textBody = `**[KNOT ${payload.severity}] ${payload.title}**\nSource: \`${payload.source}\`\n${payload.message}${fullDetails ? `\n\`\`\`\n${fullDetails.slice(0, 1200)}\n\`\`\`` : ''}`;
        await axios.post(
          webhookUrl,
          {
            content: textBody, // Discord compatible
            text: textBody, // Slack compatible
          },
          { timeout: 8000 },
        );
        channelsSent.push('webhook');
      } catch (err: any) {
        this.logger.warn(`Webhook alert failed: ${err?.message || err}`);
      }
    }

    // 3. Optional Telegram Bot instant mobile push
    const tgToken = (process.env.TELEGRAM_BOT_TOKEN || '').trim();
    const tgChatId = (process.env.TELEGRAM_CHAT_ID || '').trim();
    if (tgToken && tgChatId) {
      try {
        const tgText = `[KNOT ${payload.severity}] ${payload.title}\nSource: ${payload.source}\n\n${payload.message}${fullDetails ? `\n\n${fullDetails.slice(0, 1500)}` : ''}`;
        await axios.post(
          `https://api.telegram.org/bot${tgToken}/sendMessage`,
          {
            chat_id: tgChatId,
            text: tgText,
          },
          { timeout: 8000 },
        );
        channelsSent.push('telegram');
      } catch (err: any) {
        this.logger.warn(`Telegram alert failed: ${err?.message || err}`);
      }
    }

    // 4. Persist alert in PostgreSQL for Admin Dashboard review
    try {
      await this.prisma.systemAlert.create({
        data: {
          severity: payload.severity,
          source: payload.source,
          title: payload.title,
          message: payload.message,
          details: fullDetails || null,
          channelsSent,
        },
      });
      channelsSent.push('database');
    } catch (dbErr: any) {
      this.logger.warn(
        `Could not persist SystemAlert to DB: ${dbErr?.message || dbErr}`,
      );
    }

    return { sent: true, channels: channelsSent };
  }

  async notifyHttpError(params: {
    method: string;
    url: string;
    statusCode: number;
    errorMessage: string;
    stack?: string;
    userId?: string;
  }) {
    const key = `http:${params.statusCode}:${params.method}:${params.url.split('?')[0]}`;
    await this.sendAlert({
      key,
      severity: params.statusCode >= 500 ? 'CRITICAL' : 'ERROR',
      source: 'backend-core/http',
      title: `API Error ${params.statusCode} on ${params.method} ${params.url.split('?')[0]}`,
      message: `A server error occurred while serving a user request. Investigate before users are affected.`,
      details: [
        `Route: ${params.method} ${params.url}`,
        `Status: ${params.statusCode}`,
        params.userId ? `User ID: ${params.userId}` : null,
        `Error: ${params.errorMessage}`,
        params.stack ? `\nStack:\n${params.stack}` : null,
      ]
        .filter(Boolean)
        .join('\n'),
    });
  }

  async runHealthWatchdog() {
    // Check 1: PostgreSQL connectivity
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      await this.markRecovered(
        'health:postgres',
        'PostgreSQL Database Recovered',
        'Database connectivity is healthy again.',
      );
    } catch (err: any) {
      this.activeIncidents.add('health:postgres');
      await this.sendAlert({
        key: 'health:postgres',
        severity: 'CRITICAL',
        source: 'watchdog/database',
        title: 'PostgreSQL Database Unreachable',
        message:
          'Backend cannot reach PostgreSQL. Users will be unable to log in, register, or load matches until restored.',
        details: err?.message || String(err),
      });
    }

    // Check 2: Backend AI Service
    const aiUrl = (process.env.AI_SERVICE_URL || '').trim();
    if (aiUrl) {
      try {
        await axios.get(aiUrl, { timeout: 6000, validateStatus: () => true });
        await this.markRecovered(
          'health:ai-service',
          'AI Service Recovered',
          `AI service at ${aiUrl} is reachable again.`,
        );
      } catch (err: any) {
        this.activeIncidents.add('health:ai-service');
        await this.sendAlert({
          key: 'health:ai-service',
          severity: 'WARNING',
          source: 'watchdog/backend-ai',
          title: 'Backend AI Service Unreachable',
          message: `Cannot connect to AI service (${aiUrl}). AI Coach and compatibility insights may be degraded.`,
          details: err?.message || String(err),
        });
      }
    }

    // Check 3: Public HTTPS API proxy (catches Cloudflare/SSL/proxy misconfigurations early!)
    const publicApiCheckUrl = (
      process.env.PUBLIC_API_HEALTH_URL ||
      'https://knotmarriage.online/api-backend/auth/login'
    ).trim();
    if (publicApiCheckUrl && process.env.NODE_ENV !== 'test') {
      try {
        const res = await axios.post(
          publicApiCheckUrl,
          {},
          {
            timeout: 10000,
            maxRedirects: 0,
            validateStatus: () => true,
            headers: { 'Content-Type': 'application/json' },
          },
        );
        const contentType = String(res.headers?.['content-type'] || '');
        const isJson = contentType.includes('application/json');
        const isExpectedAuthStatus = res.status === 400 || res.status === 401;

        if (!isJson || !isExpectedAuthStatus) {
          this.activeIncidents.add('health:public-api');
          await this.sendAlert({
            key: 'health:public-api',
            severity: 'CRITICAL',
            source: 'watchdog/public-endpoint',
            title: `Public Auth Endpoint Anomaly (HTTP ${res.status})`,
            message: `${publicApiCheckUrl} returned unexpected status/content-type. Users on Web or Mobile may be blocked from logging in or registering!`,
            details: `URL: ${publicApiCheckUrl}\nStatus: ${res.status}\nContent-Type: ${contentType}\nLocation Header: ${res.headers?.location || 'none'}\nBody Preview: ${String(typeof res.data === 'string' ? res.data : JSON.stringify(res.data)).slice(0, 400)}`,
          });
        } else {
          await this.markRecovered(
            'health:public-api',
            'Public Auth Endpoint Recovered',
            `${publicApiCheckUrl} is returning healthy JSON responses again.`,
          );
        }
      } catch (err: any) {
        this.activeIncidents.add('health:public-api');
        await this.sendAlert({
          key: 'health:public-api',
          severity: 'CRITICAL',
          source: 'watchdog/public-endpoint',
          title: 'Public Auth Endpoint Unreachable',
          message: `External check to ${publicApiCheckUrl} failed. Check DNS, Cloudflare, SSL, or EC2 container health immediately.`,
          details: err?.message || String(err),
        });
      }
    }
  }

  private async markRecovered(key: string, title: string, message: string) {
    if (!this.activeIncidents.has(key)) return;
    this.activeIncidents.delete(key);
    await this.sendAlert({
      key: `${key}:recovered`,
      severity: 'INFO',
      source: 'watchdog/recovery',
      title,
      message,
      cooldownMs: 0,
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
