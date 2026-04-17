import { Body, Controller, Get, Param, Patch, Post, Put, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/cbhi.enums';
import { User } from '../users/user.entity';
import {
  AddFacilityStaffDto,
  CreateFacilityDto,
  ExportQueryDto,
  ReportsQueryDto,
  ReviewClaimDto,
  ReviewIndigentApplicationDto,
  UpdateFacilityDto,
  UpdateSystemSettingDto,
} from './admin.dto';
import { AdminService } from './admin.service';
import { ClaimAppealService } from '../claims/claim-appeal.service';
import { AppealStatus } from '../claims/claim-appeal.entity';

@Controller('admin')
@Roles(UserRole.CBHI_OFFICER, UserRole.SYSTEM_ADMIN)
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly claimAppealService: ClaimAppealService,
  ) {}

  @Get('indigent/pending')
  getPendingIndigent(
    @CurrentUser() user: User,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getPendingIndigentApplications(
      user.id,
      page ? Number(page) : 1,
      limit ? Math.min(Number(limit), 100) : 50,
    );
  }

  @Patch('indigent/:applicationId/review')
  reviewIndigent(
    @CurrentUser() user: User,
    @Param('applicationId') applicationId: string,
    @Body() dto: ReviewIndigentApplicationDto,
  ) {
    return this.adminService.reviewIndigentApplication(user.id, applicationId, dto);
  }

  @Patch('claims/:claimId/decision')
  reviewClaim(
    @CurrentUser() user: User,
    @Param('claimId') claimId: string,
    @Body() dto: ReviewClaimDto,
  ) {
    return this.adminService.reviewClaim(user.id, claimId, dto);
  }

  @Get('claims')
  listClaims(
    @CurrentUser() user: User,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.listClaimsForReview(
      user.id,
      page ? Number(page) : 1,
      limit ? Math.min(Number(limit), 100) : 50,
    );
  }

  @Get('configuration')
  getConfiguration(@CurrentUser() user: User) {
    return this.adminService.getSystemConfiguration(user.id);
  }

  @Put('configuration/:key')
  updateConfiguration(
    @CurrentUser() user: User,
    @Param('key') key: string,
    @Body() dto: UpdateSystemSettingDto,
  ) {
    return this.adminService.updateSystemConfiguration(user.id, key, dto);
  }

  @Get('reports/summary')
  getSummaryReport(@CurrentUser() user: User, @Query() query: ReportsQueryDto) {
    return this.adminService.generateSummaryReport(user.id, query);
  }

  @Get('export')
  async exportData(
    @CurrentUser() user: User,
    @Query() query: ExportQueryDto,
    @Res() res: Response,
  ) {
    const csv = await this.adminService.exportToCsv(user.id, query);
    const filename = `cbhi_${query.type ?? 'export'}_${new Date().toISOString().split('T')[0]}.csv`;
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(csv);
  }

  @Get('audit-logs')
  getAuditLogs(
    @CurrentUser() user: User,
    @Query('entityType') entityType?: string,
    @Query('entityId') entityId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getAuditLogs(
      user.id,
      entityType,
      entityId,
      page ? Number(page) : 1,
      limit ? Math.min(Number(limit), 200) : 100,
    );
  }

  // ── Facility management ────────────────────────────────────────────────────

  @Get('facilities')
  listFacilities(@CurrentUser() user: User) {
    return this.adminService.listFacilities(user.id);
  }

  @Post('facilities')
  createFacility(@CurrentUser() user: User, @Body() dto: CreateFacilityDto) {
    return this.adminService.createFacility(user.id, dto);
  }

  @Patch('facilities/:facilityId')
  updateFacility(
    @CurrentUser() user: User,
    @Param('facilityId') facilityId: string,
    @Body() dto: UpdateFacilityDto,
  ) {
    return this.adminService.updateFacility(user.id, facilityId, dto);
  }

  @Post('facilities/:facilityId/staff')
  addFacilityStaff(
    @CurrentUser() user: User,
    @Param('facilityId') facilityId: string,
    @Body() dto: AddFacilityStaffDto,
  ) {
    return this.adminService.addFacilityStaff(user.id, facilityId, dto);
  }

  @Patch('facilities/:facilityId/staff/:staffUserId/deactivate')
  deactivateFacilityStaff(
    @CurrentUser() user: User,
    @Param('facilityId') facilityId: string,
    @Param('staffUserId') staffUserId: string,
  ) {
    return this.adminService.deactivateFacilityStaff(user.id, facilityId, staffUserId);
  }

  // ── User management ────────────────────────────────────────────────────────

  @Get('users')
  listUsers(
    @CurrentUser() user: User,
    @Query('role') role?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.listUsers(user.id, role, page ? Number(page) : 1, limit ? Math.min(Number(limit), 100) : 50);
  }

  @Patch('users/:userId/deactivate')
  deactivateUser(@CurrentUser() user: User, @Param('userId') userId: string) {
    return this.adminService.deactivateUser(user.id, userId);
  }

  @Patch('users/:userId/activate')
  activateUser(@CurrentUser() user: User, @Param('userId') userId: string) {
    return this.adminService.activateUser(user.id, userId);
  }

  @Post('users/:userId/reset-password')
  resetUserPassword(@CurrentUser() user: User, @Param('userId') userId: string) {
    return this.adminService.resetUserPassword(user.id, userId);
  }

  // ── Financial dashboard ────────────────────────────────────────────────────

  @Get('reports/financial')
  getFinancialDashboard(@CurrentUser() user: User, @Query() query: ReportsQueryDto) {
    return this.adminService.getFinancialDashboard(user.id, query);
  }

  // ── Facility performance ───────────────────────────────────────────────────

  @Get('reports/facility-performance')
  getFacilityPerformance(@CurrentUser() user: User, @Query() query: ReportsQueryDto) {
    return this.adminService.getFacilityPerformance(user.id, query);
  }

  // ── Claim Appeals ──────────────────────────────────────────────────────────

  @Get('claims/appeals')
  getAllAppeals(@CurrentUser() user: User) {
    return this.claimAppealService.getAllAppeals(user.id);
  }

  @Patch('claims/appeals/:appealId/review')
  reviewAppeal(
    @CurrentUser() user: User,
    @Param('appealId') appealId: string,
    @Body() body: { status: AppealStatus; reviewNote?: string },
  ) {
    return this.claimAppealService.reviewAppeal(user.id, appealId, body);
  }
}
