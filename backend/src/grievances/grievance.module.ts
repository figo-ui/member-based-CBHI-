import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Grievance } from './grievance.entity';
import { GrievanceController } from './grievance.controller';
import { GrievanceService } from './grievance.service';
import { User } from '../users/user.entity';
import { Notification } from '../notifications/notification.entity';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Grievance, User, Notification]),
    NotificationsModule,
  ],
  controllers: [GrievanceController],
  providers: [GrievanceService],
  exports: [GrievanceService],
})
export class GrievanceModule {}
