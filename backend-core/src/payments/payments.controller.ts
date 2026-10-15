import { Controller, Post, Body, Headers, HttpCode, HttpStatus } from '@nestjs/common';
import { PaymentsService } from './payments.service';

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
  ) {
    return this.usersVerify(reference, userId, months || 1);
  }

  private async usersVerify(reference: string, userId: string, months: number) {
    return this.paymentsService.verifyTransaction(reference, userId, months);
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
  async handleRevenueCatWebhook(@Body() body: any) {
    return this.paymentsService.handleRevenueCatWebhook(body);
  }
}
