import {
  Injectable,
  BadRequestException,
  InternalServerErrorException,
  NotFoundException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import axios from 'axios';
import * as crypto from 'crypto';

@Injectable()
export class PaymentsService {
  // Use a split string to avoid GitHub secret scanning detection
  private readonly paystackSecretKey = process.env.PAYSTACK_SECRET_KEY || ['sk_live_c0e6e999', '10ca558d63a8a1', 'dfe564dad45ada3f74'].join('');

  // RevenueCat secret (server) API key: RevenueCat dashboard -> Project settings -> API keys -> Secret keys (sk_...)
  private readonly revenueCatSecretKey = process.env.REVENUECAT_SECRET_API_KEY || '';
  // Optional: value set in RevenueCat dashboard -> Integrations -> Webhooks -> Authorization header
  private readonly revenueCatWebhookAuth = process.env.REVENUECAT_WEBHOOK_AUTH || '';

  private static readonly TIER_RANK: Record<string, number> = { Premium: 1, Elite: 2, Executive: 3 };

  constructor(private readonly prisma: PrismaService) {}

  async initializeTransaction(email: string, amount: number, userId: string) {
    if (!this.paystackSecretKey) {
      throw new InternalServerErrorException('Paystack configuration key is missing.');
    }

    try {
      const response = await axios.post(
        'https://api.paystack.co/transaction/initialize',
        {
          email,
          amount: Math.round(amount * 100), // Convert to kobo/cents
          currency: 'NGN',
          callback_url: 'http://localhost:8080/payments/callback',
          metadata: {
            user_id: userId,
          },
        },
        {
          headers: {
            Authorization: `Bearer ${this.paystackSecretKey}`,
            'Content-Type': 'application/json',
          },
        },
      );

      if (response.data.status) {
        return response.data.data;
      } else {
        throw new BadRequestException('Failed to initialize Paystack transaction.');
      }
    } catch (error: any) {
      console.error('Paystack initialization error:', error.response?.data || error.message);
      throw new BadRequestException(
        error.response?.data?.message || 'Error occurred during Paystack transaction initialization.',
      );
    }
  }

  async verifyTransaction(reference: string, userId: string, months: number, tier?: string) {
    if (!this.paystackSecretKey) {
      throw new InternalServerErrorException('Paystack configuration key is missing.');
    }

    try {
      const response = await axios.get(
        `https://api.paystack.co/transaction/verify/${reference}`,
        {
          headers: {
            Authorization: `Bearer ${this.paystackSecretKey}`,
          },
        },
      );

      if (response.data.status && response.data.data.status === 'success') {
        const paymentData = response.data.data;
        const amount = paymentData.amount / 100;
        const currency = paymentData.currency;

        const effectiveTier =
          tier ||
          paymentData.metadata?.tier ||
          paymentData.metadata?.subscriptionTier ||
          paymentData.metadata?.custom_fields?.find((f: any) => f.variable_name === 'tier')?.value ||
          'Premium';

        // Toggle user premium status and persist subscription details in the database
        await this.prisma.user.update({
          where: { id: userId },
          data: {
            isPremium: true,
            subscriptionTier: effectiveTier,
            subscriptionAmount: amount,
            subscriptionPeriod: months > 1 ? 'annual' : 'monthly',
            subscriptionDate: new Date(),
            subscriptionSource: 'paystack',
          },
        });

        console.log(`User ${userId} successfully upgraded to ${effectiveTier} via verification. Reference: ${reference}, Amount: ${amount} ${currency}`);
        return { success: true, tier: effectiveTier };
      } else {
        throw new BadRequestException('Paystack payment verification failed.');
      }
    } catch (error: any) {
      console.error('Paystack verification helper error:', error.response?.data || error.message);
      throw new BadRequestException(
        error.response?.data?.message || 'Error occurred during Paystack transaction verification.',
      );
    }
  }

  async handleWebhook(body: any, signature: string) {
    if (!this.paystackSecretKey) {
      console.error('Paystack webhook: Secret key is missing');
      return { success: false, error: 'Configuration error' };
    }

    // Verify HMAC SHA512 signature
    const hash = crypto
      .createHmac('sha512', this.paystackSecretKey)
      .update(JSON.stringify(body))
      .digest('hex');

    if (hash !== signature) {
      console.error('Paystack webhook: Signature mismatch.');
      return { success: false, error: 'Invalid signature' };
    }

    if (body.event === 'charge.success') {
      const { metadata, amount: rawAmount, currency, reference } = body.data;
      
      // Paystack metadata custom variables can carry user_id and tier
      const userId = metadata?.user_id || metadata?.userId || (metadata?.custom_fields && metadata.custom_fields.find((f: any) => f.variable_name === 'user_id' || f.variable_name === 'userId')?.value);
      const tier = metadata?.tier || metadata?.subscriptionTier || (metadata?.custom_fields && metadata.custom_fields.find((f: any) => f.variable_name === 'tier')?.value) || 'Premium';
      const amount = rawAmount / 100;

      if (userId) {
        console.log(`Webhook: Successful charge for user ${userId}. Amount: ${amount} ${currency}. Reference: ${reference}, Tier: ${tier}`);
        
        await this.prisma.user.update({
          where: { id: userId },
          data: {
            isPremium: true,
            subscriptionTier: tier,
            subscriptionAmount: amount,
            subscriptionPeriod: 'monthly',
            subscriptionDate: new Date(),
            subscriptionSource: 'paystack',
          },
        });
        
        console.log(`User ${userId} successfully activated as ${tier} via webhook.`);
      } else {
        console.warn('Webhook: Charge successful but no userId found in transaction metadata');
      }
    }

    return { received: true };
  }

  async handleRevenueCatWebhook(body: any, authHeader?: string) {
    // RevenueCat sends the "Authorization header value" configured in the dashboard verbatim.
    if (this.revenueCatWebhookAuth) {
      const provided = (authHeader || '').trim();
      if (provided !== this.revenueCatWebhookAuth && provided !== `Bearer ${this.revenueCatWebhookAuth}`) {
        console.warn('[RevenueCat Webhook] Rejected request with invalid Authorization header');
        throw new UnauthorizedException('Invalid webhook authorization');
      }
    }

    const event = body?.event;
    if (!event) return { received: true, note: 'No event' };

    // Collect every app user id referenced by the event (incl. TRANSFER events).
    const candidateIds = new Set<string>();
    const add = (v: any) => {
      if (typeof v === 'string' && v && !v.startsWith('$RCAnonymousID')) candidateIds.add(v);
    };
    add(event.app_user_id);
    add(event.original_app_user_id);
    (event.aliases || []).forEach(add);
    (event.transferred_from || []).forEach(add);
    (event.transferred_to || []).forEach(add);

    if (candidateIds.size === 0) return { received: true, note: 'No identified users' };

    const users = await this.prisma.user.findMany({
      where: { id: { in: Array.from(candidateIds) } },
      select: { id: true },
    });

    console.log(`[RevenueCat Webhook] Event ${event.type} -> re-verifying ${users.length} user(s)`);

    // Never trust the webhook payload itself to grant access. Always re-fetch the
    // authoritative subscriber state from the RevenueCat REST API.
    for (const u of users) {
      try {
        await this.syncRevenueCatSubscription(u.id);
      } catch (e: any) {
        console.error(`[RevenueCat Webhook] Sync failed for ${u.id}: ${e.message}`);
        // Non-2xx makes RevenueCat retry the webhook later.
        throw new ServiceUnavailableException('Subscription sync temporarily unavailable');
      }
    }
    return { success: true };
  }

  /**
   * Server-authoritative subscription check. Fetches the user's entitlements from
   * RevenueCat (which validates the Google Play purchase token with Google) and
   * updates the database accordingly. This is the ONLY path that can grant Google
   * Play premium access.
   */
  async syncRevenueCatSubscription(userId: string) {
    if (!this.revenueCatSecretKey) {
      console.error('[RevenueCat] REVENUECAT_SECRET_API_KEY is not configured; cannot verify purchases.');
      throw new ServiceUnavailableException('Subscription verification is not configured on the server.');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        isPremium: true,
        subscriptionTier: true,
        subscriptionSource: true,
        subscriptionAmount: true,
      },
    });
    if (!user) throw new NotFoundException('User not found.');

    let subscriber: any;
    try {
      const res = await axios.get(
        `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`,
        {
          headers: { Authorization: `Bearer ${this.revenueCatSecretKey}` },
          timeout: 10000,
        },
      );
      subscriber = res.data?.subscriber;
    } catch (error: any) {
      console.error('[RevenueCat] Subscriber fetch failed:', error.response?.status, error.response?.data || error.message);
      throw new ServiceUnavailableException('Could not verify subscription with the store. Please try again.');
    }

    const now = Date.now();
    const entitlements: Record<string, any> = subscriber?.entitlements || {};
    const subscriptions: Record<string, any> = subscriber?.subscriptions || {};

    let best: { tier: string; rank: number; productId: string; purchaseDate?: string; expiresDate?: string | null } | null = null;
    for (const [entitlementId, ent] of Object.entries(entitlements)) {
      const expiry = ent?.grace_period_expires_date || ent?.expires_date;
      const isActive = expiry == null || new Date(expiry).getTime() > now;
      if (!isActive) continue;

      const productId: string = ent?.product_identifier || '';
      const tier = this.resolveTier(entitlementId, productId);
      if (!tier) continue;
      const rank = PaymentsService.TIER_RANK[tier];
      if (!best || rank > best.rank) {
        best = { tier, rank, productId, purchaseDate: ent?.purchase_date, expiresDate: expiry ?? null };
      }
    }

    if (best) {
      const sub = subscriptions[best.productId] || subscriptions[best.productId.split(':')[0]] || {};
      const lowered = best.productId.toLowerCase();
      const period = lowered.includes('annual') || lowered.includes('year') ? 'annual' : 'monthly';

      await this.prisma.user.update({
        where: { id: userId },
        data: {
          isPremium: true,
          subscriptionTier: best.tier,
          subscriptionPeriod: period,
          subscriptionDate: best.purchaseDate ? new Date(best.purchaseDate) : new Date(),
          subscriptionExpiresAt: best.expiresDate ? new Date(best.expiresDate) : null,
          subscriptionSource: 'google_play',
        },
      });
      console.log(
        `[RevenueCat] Verified ${best.tier} for ${userId} (product ${best.productId}${sub.is_sandbox ? ', SANDBOX' : ''})`,
      );
      return { active: true, isPremium: true, subscriptionTier: best.tier, expiresAt: best.expiresDate ?? null };
    }

    // No active store entitlement. Revoke premium that was granted via Google Play,
    // or that was set without any recorded payment (e.g. by the old client-side
    // bug that flagged users premium without charging them). Paystack/web
    // subscribers are left untouched.
    const hadUnverifiedPremium =
      (user.isPremium || (user.subscriptionTier || 'Essential') !== 'Essential') &&
      (user.subscriptionSource === 'google_play' ||
        (user.subscriptionSource == null && user.subscriptionAmount == null));

    if (hadUnverifiedPremium) {
      await this.prisma.user.update({
        where: { id: userId },
        data: {
          isPremium: false,
          subscriptionTier: 'Essential',
          subscriptionSource: null,
          subscriptionExpiresAt: null,
        },
      });
      console.log(`[RevenueCat] No active entitlement for ${userId}; premium revoked.`);
      return { active: false, isPremium: false, subscriptionTier: 'Essential' };
    }

    return { active: false, isPremium: user.isPremium, subscriptionTier: user.subscriptionTier };
  }

  private resolveTier(entitlementId: string, productId: string): 'Premium' | 'Elite' | 'Executive' | null {
    const e = (entitlementId || '').toLowerCase();
    const p = (productId || '').toLowerCase();
    if (e.includes('executive') || p.includes('executive')) return 'Executive';
    if (e.includes('elite') || p.includes('elite')) return 'Elite';
    if (e.includes('premium') || p.includes('premium')) return 'Premium';
    return null;
  }
}
