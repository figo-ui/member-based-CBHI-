import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
import { Coverage } from '../coverages/coverage.entity';
import { Household } from '../households/household.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { Payment } from '../payments/payment.entity';
import { ChapaService } from './chapa.service';
import { PaymentGatewayController } from './payment-gateway.controller';
import { PaymentService } from './payment.service';

@Module({
  imports: [
    NotificationsModule,
    TypeOrmModule.forFeature([Coverage, Payment, Household, Beneficiary]),
  ],
  controllers: [PaymentGatewayController],
  // FIX ME-3: Register PaymentService — business logic extracted from controller
  providers: [ChapaService, PaymentService],
  exports: [ChapaService, PaymentService],
})
export class PaymentGatewayModule {}
