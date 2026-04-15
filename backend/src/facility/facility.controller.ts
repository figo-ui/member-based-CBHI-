import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/cbhi.enums';
import { User } from '../users/user.entity';
import {
  SubmitServiceClaimDto,
  VerifyEligibilityQueryDto,
} from './facility.dto';
import { FacilityService } from './facility.service';

@Controller('facility')
@Roles(UserRole.HEALTH_FACILITY_STAFF)
export class FacilityController {
  constructor(private readonly facilityService: FacilityService) {}

  @Get('eligibility')
  verifyEligibility(@CurrentUser() user: User, @Query() query: VerifyEligibilityQueryDto) {
    return this.facilityService.verifyBeneficiaryEligibility(user.id, query);
  }

  @Post('claims')
  submitClaim(@CurrentUser() user: User, @Body() dto: SubmitServiceClaimDto) {
    return this.facilityService.submitServiceClaim(user.id, dto);
  }

  @Get('claims')
  listClaims(@CurrentUser() user: User) {
    return this.facilityService.listFacilityClaims(user.id);
  }
}
