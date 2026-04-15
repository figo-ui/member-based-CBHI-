import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
} from '@nestjs/common';
import { IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { Public } from '../common/decorators/public.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../users/user.entity';
import { ChapaService } from './chapa.service';
import { PaymentService } from './payment.service';

class InitiatePaymentDto {
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  amount!: number;

  @IsOptional()
  @IsString()
  description?: string;
}

/**
 * FIX ME-3: Controller is now a thin HTTP adapter.
 * All business logic lives in PaymentService.
 */
@Controller('payments')
export class PaymentGatewayController {
  constructor(
    private readonly paymentService: PaymentService,
    private readonly chapaService: ChapaService,
  ) {}

  @Post('initiate')
  initiatePayment(
    @CurrentUser() user: User,
    @Body() dto: InitiatePaymentDto,
  ) {
    return this.paymentService.initiatePayment(user, dto.amount, dto.description);
  }

  @Get('verify/:txRef')
  verifyPayment(
    @CurrentUser() _user: User,
    @Param('txRef') txRef: string,
  ) {
    return this.paymentService.verifyPayment(txRef);
  }

  @Public()
  @Post('webhook/chapa')
  async chapaWebhook(
    @Headers('x-chapa-signature') signature: string,
    @Body() body: Record<string, unknown>,
  ) {
    const rawBody = JSON.stringify(body);

    if (!this.chapaService.verifyWebhookSignature(rawBody, signature)) {
      throw new BadRequestException('Invalid webhook signature.');
    }

    const txRef = body['tx_ref']?.toString() ?? body['trx_ref']?.toString();
    const status = body['status']?.toString();

    if (!txRef) return { received: true };

    await this.paymentService.handleWebhook(txRef, status ?? '');
    return { received: true };
  }
}
