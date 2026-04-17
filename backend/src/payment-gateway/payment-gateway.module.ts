import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
import { Coverage } from '../coverages/coverage.entity';
import { Household } from '../households/household.entity';
import { Notification } from '../notifications/notification.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { Payment } from '../payments/payment.entity';
import { SmsModule } from '../sms/sms.module';
import { ChapaService } from './chapa.service';
import { PaymentGatewayController } from './payment-gateway.controller';
import { PaymentService } from './payment.service';

@Module({
  imports: [
    NotificationsModule,
    SmsModule,
    TypeOrmModule.forFeature([Coverage, Payment, Household, Beneficiary, Notification]),
  ],
  controllers: [PaymentGatewayController],
  providers: [ChapaService, PaymentService],
  exports: [ChapaService, PaymentService],
})
export class PaymentGatewayModule {}
