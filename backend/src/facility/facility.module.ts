import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Beneficiary } from '../beneficiaries/beneficiary.entity';
import { ClaimItem } from '../claim-items/claim-item.entity';
import { Claim } from '../claims/claim.entity';
import { Coverage } from '../coverages/coverage.entity';
import { Document } from '../documents/document.entity';
import { FacilityUser } from '../facility-users/facility-user.entity';
import { Notification } from '../notifications/notification.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { FacilityController } from './facility.controller';
import { FacilityService } from './facility.service';

@Module({
  imports: [
    NotificationsModule,
    TypeOrmModule.forFeature([
      FacilityUser,
      Beneficiary,
      Coverage,
      Claim,
      ClaimItem,
      Document,
      Notification,
    ]),
  ],
  controllers: [FacilityController],
  providers: [FacilityService],
})
export class FacilityModule {}
