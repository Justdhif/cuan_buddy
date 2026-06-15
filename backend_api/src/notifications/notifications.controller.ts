import { Controller, Get, Patch, Param, UseGuards, Req, Query } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  findAll(@Req() req, @Query() query: any) {
    return this.notificationsService.findAll(req.user.userId, query);
  }

  @Patch(':id/read')
  markAsRead(@Req() req, @Param('id') id: string) {
    return this.notificationsService.markAsRead(req.user.userId, id);
  }
}
