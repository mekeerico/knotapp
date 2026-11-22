import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);

  private getApiKey(): string {
    const defaultKey = Buffer.from(
      'cmVfUkVMWVZLaTRfR3RycmNWNnVTaUxnb1h4MmRWMmF5a3FM',
      'base64',
    ).toString('utf8');
    return (process.env.RESEND_API_KEY || defaultKey).trim();
  }

  private getFromEmail(): string {
    return (
      process.env.RESEND_FROM_EMAIL ||
      'KNOT Registry <noreply@knotmarriage.online>'
    ).trim();
  }

  async sendEmail(params: {
    to: string | string[];
    subject: string;
    html: string;
    from?: string;
  }): Promise<boolean> {
    const apiKey = this.getApiKey();
    if (!apiKey) {
      this.logger.warn(
        `RESEND_API_KEY not configured — skipped email "${params.subject}"`,
      );
      return false;
    }

    const recipients = Array.isArray(params.to) ? params.to : [params.to];
    const primaryFrom = (params.from || this.getFromEmail()).trim();

    try {
      await axios.post(
        'https://api.resend.com/emails',
        {
          from: primaryFrom,
          to: recipients,
          subject: params.subject,
          html: params.html,
        },
        {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 12000,
        },
      );
      return true;
    } catch (err: any) {
      const errMsg = err?.response?.data?.message || err?.message || '';
      this.logger.warn(
        `Primary sender (${primaryFrom}) failed for "${params.subject}": ${errMsg}. Retrying with onboarding@resend.dev...`,
      );
      try {
        await axios.post(
          'https://api.resend.com/emails',
          {
            from: 'KNOT Registry <onboarding@resend.dev>',
            to: recipients,
            subject: params.subject,
            html: params.html,
          },
          {
            headers: {
              Authorization: `Bearer ${apiKey}`,
              'Content-Type': 'application/json',
            },
            timeout: 12000,
          },
        );
        return true;
      } catch (fallbackErr: any) {
        const fbMsg =
          fallbackErr?.response?.data?.message || fallbackErr?.message || '';
        this.logger.error(
          `Failed to send email "${params.subject}" to ${recipients.join(', ')}: ${fbMsg}`,
        );
        return false;
      }
    }
  }
}
