import { Controller, Get, Param, Patch } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../users/user.entity';
import { NotificationService } from './notification.service';

/**
 * REST endpoints for in-app notifications.
 * Used by admin and facility apps to fetch and mark notifications.
 */
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationService: NotificationService) {}

  /** GET /api/v1/notifications — list notifications for the current user */
  @Get()
  getMyNotifications(@CurrentUser() user: User) {
    return this.notificationService.getForUser(user.id);
  }

  /** PATCH /api/v1/notifications/:id/read — mark a notification as read */
  @Patch(':id/read')
  markRead(@CurrentUser() user: User, @Param('id') id: string) {
    return this.notificationService.markRead(user.id, id);
  }
}
