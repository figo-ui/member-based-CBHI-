import { BullModule } from '@nestjs/bull';
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Coverage } from '../coverages/coverage.entity';
import { Household } from '../households/household.entity';
import { Notification } from '../notifications/notification.entity';
import { FcmService } from '../notifications/fcm.service';
import { SmsModule } from '../sms/sms.module';
import { JobsService } from './jobs.service';
import { JobsProcessor, CBHI_JOBS_QUEUE } from './jobs.processor';
import { JobsScheduler } from './jobs.scheduler';

@Module({
  imports: [
    TypeOrmModule.forFeature([Coverage, Household, Notification]),
    SmsModule,
    // FIX ME-7: Register Bull queue for multi-instance-safe job scheduling
    BullModule.registerQueue({
      name: CBHI_JOBS_QUEUE,
    }),
  ],
  providers: [JobsService, FcmService, JobsProcessor, JobsScheduler],
  exports: [JobsService],
})
export class JobsModule {}
