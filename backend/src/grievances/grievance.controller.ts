import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/cbhi.enums';
import { User } from '../users/user.entity';
import { GrievanceService } from './grievance.service';
import { GrievanceType } from './grievance.entity';

@Controller('grievances')
export class GrievanceController {
  constructor(private readonly service: GrievanceService) {}

  /** Any authenticated user can submit a grievance */
  @Post()
  submit(@CurrentUser() user: User, @Body() body: {
    type: GrievanceType;
    subject: string;
    description: string;
    referenceId?: string;
    referenceType?: string;
  }) {
    return this.service.submitGrievance(user.id, body);
  }

  /** Members view their own grievances */
  @Get('mine')
  getMine(@CurrentUser() user: User) {
    return this.service.getMyGrievances(user.id);
  }

  /** Admins view all grievances */
  @Roles(UserRole.CBHI_OFFICER, UserRole.SYSTEM_ADMIN)
  @Get()
  getAll(@CurrentUser() user: User, @Query('status') status?: string) {
    return this.service.getAllGrievances(user.id, status);
  }

  /** Admins update grievance status and resolution */
  @Roles(UserRole.CBHI_OFFICER, UserRole.SYSTEM_ADMIN)
  @Patch(':id')
  update(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.service.updateGrievance(user.id, id, body);
  }
}
