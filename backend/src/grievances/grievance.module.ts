import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Grievance } from './grievance.entity';
import { GrievanceController } from './grievance.controller';
import { GrievanceService } from './grievance.service';
import { User } from '../users/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Grievance, User])],
  controllers: [GrievanceController],
  providers: [GrievanceService],
  exports: [GrievanceService],
})
export class GrievanceModule {}
