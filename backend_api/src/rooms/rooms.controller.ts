import { Controller, Get, Post, Patch, Body, Req, UseGuards, Param, Delete, ParseUUIDPipe } from '@nestjs/common';
import { RoomsService } from './rooms.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('rooms')
export class RoomsController {
  constructor(private readonly roomsService: RoomsService) {}

  @Post()
  createRoom(@Req() req: any, @Body() body: { name: string; memberUserIds?: string[] }) {
    return this.roomsService.createRoom(req.user.userId, body);
  }

  @Get()
  listRooms(@Req() req: any) {
    return this.roomsService.listRooms(req.user.userId);
  }

  @Get(':id')
  getRoomDetail(@Req() req: any, @Param('id', ParseUUIDPipe) id: string) {
    return this.roomsService.getRoomDetail(req.user.userId, id);
  }

  @Patch(':id')
  updateRoom(
    @Req() req: any,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: { name?: string; emojiIcon?: string; colorCode?: string; description?: string }
  ) {
    return this.roomsService.updateRoom(req.user.userId, id, body);
  }

  @Post(':id/invite')
  inviteMember(
    @Req() req: any,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: { userId: string }
  ) {
    return this.roomsService.inviteMember(req.user.userId, id, body.userId);
  }

  @Delete(':id')
  leaveOrDeleteRoom(@Req() req: any, @Param('id', ParseUUIDPipe) id: string) {
    return this.roomsService.leaveOrDeleteRoom(req.user.userId, id);
  }
}
