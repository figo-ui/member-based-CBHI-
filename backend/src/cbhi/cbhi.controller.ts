import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../users/user.entity';
import {
  CreateFamilyMemberDto,
  RegistrationStepOneDto,
  RegistrationStepTwoDto,
  RenewCoverageDto,
  UpdateFamilyMemberDto,
} from './cbhi.dto';
import { CbhiService } from './cbhi.service';
import { Public } from '../common/decorators/public.decorator';

@Controller('cbhi')
export class CbhiController {
  constructor(private readonly cbhiService: CbhiService) {}

  @Public()
  @Post('registration/step-1')
  registerStepOne(@Body() dto: RegistrationStepOneDto) {
    return this.cbhiService.registerStepOne(dto);
  }

  @Public()
  @Post('registration/step-2')
  registerStepTwo(@Body() dto: RegistrationStepTwoDto) {
    return this.cbhiService.registerStepTwo(dto);
  }

  @Get('me')
  getSnapshot(@CurrentUser() user: User) {
    return this.cbhiService.getMemberSnapshot(user.id);
  }

  @Get('family')
  getFamily(@CurrentUser() user: User) {
    return this.cbhiService.getFamily(user.id);
  }

  @Get('profile')
  getProfile(@CurrentUser() user: User) {
    return this.cbhiService.getProfile(user.id);
  }

  @Get('eligibility')
  getEligibility(@CurrentUser() user: User) {
    return this.cbhiService.getViewerEligibility(user.id);
  }

  @Get('payments')
  getPayments(@CurrentUser() user: User) {
    return this.cbhiService.getPaymentHistory(user.id);
  }

  @Post('coverage/renew')
  renewCoverage(@CurrentUser() user: User, @Body() dto: RenewCoverageDto) {
    return this.cbhiService.renewCoverage(user.id, dto);
  }

  @Get('cards')
  getDigitalCards(@CurrentUser() user: User) {
    return this.cbhiService.getDigitalCards(user.id);
  }

  @Get('notifications')
  getNotifications(@CurrentUser() user: User) {
    return this.cbhiService.getNotifications(user.id);
  }

  @Post('notifications/:notificationId/read')
  markNotificationRead(
    @CurrentUser() user: User,
    @Param('notificationId') notificationId: string,
  ) {
    return this.cbhiService.markNotificationRead(user.id, notificationId);
  }

  @Post('family')
  addFamilyMember(@CurrentUser() user: User, @Body() dto: CreateFamilyMemberDto) {
    return this.cbhiService.addFamilyMember(user.id, dto);
  }

  @Patch('family/:memberId')
  updateFamilyMember(
    @CurrentUser() user: User,
    @Param('memberId') memberId: string,
    @Body() dto: UpdateFamilyMemberDto,
  ) {
    return this.cbhiService.updateFamilyMember(user.id, memberId, dto);
  }

  @Delete('family/:memberId')
  removeFamilyMember(
    @CurrentUser() user: User,
    @Param('memberId') memberId: string,
  ) {
    return this.cbhiService.removeFamilyMember(user.id, memberId);
  }

  /** Coverage history — all past and current coverage periods */
  @Get('coverage/history')
  getCoverageHistory(@CurrentUser() user: User) {
    return this.cbhiService.getCoverageHistory(user.id);
  }
}
