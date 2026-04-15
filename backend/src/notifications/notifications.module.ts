import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { Notification } from './notification.entity';
import { FcmService } from './fcm.service';
import { NotificationService } from './notification.service';
import { NotificationsGateway } from './notifications.gateway';

@Module({
  imports: [
    AuthModule,
    TypeOrmModule.forFeature([Notification]),
  ],
  providers: [FcmService, NotificationService, NotificationsGateway],
  exports: [NotificationService, NotificationsGateway, FcmService],
})
export class NotificationsModule {}
