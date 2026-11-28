import { Controller, Post, Body, Headers, HttpCode, HttpStatus, UseGuards, Request } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('initialize')
  @HttpCode(HttpStatus.OK)
  async initializePayment(
    @Body('email') email: string,
    @Body('amount') amount: number,
    @Body('userId') userId: string,
  ) {
    return this.paymentsService.initializeTransaction(email, amount, userId);
  }

  @Post('verify')
  @HttpCode(HttpStatus.OK)
  async verifyPayment(
    @Body('reference') reference: string,
    @Body('userId') userId: string,
    @Body('months') months: number,
    @Body('tier') tier?: string,
  ) {
    return this.usersVerify(reference, userId, months || 1, tier);
  }

  private async usersVerify(reference: string, userId: string, months: number, tier?: string) {
    return this.paymentsService.verifyTransaction(reference, userId, months, tier);
  }

  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  async handleWebhook(
    @Body() body: any,
    @Headers('x-paystack-signature') signature: string,
  ) {
    return this.paymentsService.handleWebhook(body, signature);
  }

  @Post('revenuecat-webhook')
  @HttpCode(HttpStatus.OK)
  async handleRevenueCatWebhook(
    @Body() body: any,
    @Headers('authorization') authorization?: string,
  ) {
    return this.paymentsService.handleRevenueCatWebhook(body, authorization);
  }

  /**
   * Called by the mobile app after a Google Play purchase / restore (and on launch).
   * The server re-verifies entitlements directly with RevenueCat; the client can no
   * longer grant itself premium.
   */
  @UseGuards(JwtAuthGuard)
  @Post('revenuecat/sync')
  @HttpCode(HttpStatus.OK)
  async syncRevenueCat(@Request() req: any) {
    return this.paymentsService.syncRevenueCatSubscription(req.user.id);
  }
}
