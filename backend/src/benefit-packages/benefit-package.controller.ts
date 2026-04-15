import { Body, Controller, Delete, Get, Param, Patch, Post } from '@nestjs/common';
import { Public } from '../common/decorators/public.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/cbhi.enums';
import { User } from '../users/user.entity';
import { BenefitPackageService } from './benefit-package.service';

@Controller('benefit-packages')
export class BenefitPackageController {
  constructor(private readonly service: BenefitPackageService) {}

  /** Public — members and facilities can read the active package */
  @Public()
  @Get('active')
  getActive() {
    return this.service.getActivePackage();
  }

  @Public()
  @Get()
  list() {
    return this.service.listPackages();
  }

  @Public()
  @Get(':id')
  getById(@Param('id') id: string) {
    return this.service.getPackageById(id);
  }

  @Roles(UserRole.CBHI_OFFICER, UserRole.SYSTEM_ADMIN)
  @Post()
  create(@CurrentUser() _user: User, @Body() body: any) {
    return this.service.createPackage(body);
  }

  @Roles(UserRole.CBHI_OFFICER, UserRole.SYSTEM_ADMIN)
  @Patch(':id')
  update(@Param('id') id: string, @Body() body: any) {
    return this.service.updatePackage(id, body);
  }

  @Roles(UserRole.CBHI_OFFICER, UserRole.SYSTEM_ADMIN)
  @Post(':id/items')
  addItem(@Param('id') id: string, @Body() body: any) {
    return this.service.addItem(id, body);
  }

  @Roles(UserRole.CBHI_OFFICER, UserRole.SYSTEM_ADMIN)
  @Patch('items/:itemId')
  updateItem(@Param('itemId') itemId: string, @Body() body: any) {
    return this.service.updateItem(itemId, body);
  }

  @Roles(UserRole.CBHI_OFFICER, UserRole.SYSTEM_ADMIN)
  @Delete('items/:itemId')
  removeItem(@Param('itemId') itemId: string) {
    return this.service.removeItem(itemId);
  }
}
