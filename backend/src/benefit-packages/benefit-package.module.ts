import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BenefitItem, BenefitPackage } from './benefit-package.entity';
import { BenefitPackageController } from './benefit-package.controller';
import { BenefitPackageService } from './benefit-package.service';

@Module({
  imports: [TypeOrmModule.forFeature([BenefitPackage, BenefitItem])],
  controllers: [BenefitPackageController],
  providers: [BenefitPackageService],
  exports: [BenefitPackageService],
})
export class BenefitPackageModule {}
