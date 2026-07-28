import { Controller, Get, Post, Patch, Body, Req, UseGuards, Param, Delete, ParseUUIDPipe } from '@nestjs/common';
import { RoomsService } from './rooms.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('rooms')
export class RoomsController {
  constructor(private readonly roomsService: RoomsService) {}

  @Post()
  createRoom(@Req() req: any, @Body() body: { name: string; memberUserIds?: string[]; onlyOwnerCanInvite?: boolean }) {
    return this.roomsService.createRoom(req.user.userId, body);
  }

  @Post('join-code')
  joinRoomByInviteCode(@Req() req: any, @Body() body: { inviteCode: string }) {
    return this.roomsService.joinRoomByInviteCode(req.user.userId, body.inviteCode);
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
    @Body() body: { name?: string; emojiIcon?: string; colorCode?: string; description?: string; onlyOwnerCanInvite?: boolean }
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

  @Post(':id/invite-code')
  generateInviteCode(@Req() req: any, @Param('id', ParseUUIDPipe) id: string) {
    return this.roomsService.generateInviteCode(req.user.userId, id);
  }

  @Delete(':id/invite-code')
  deleteInviteCode(@Req() req: any, @Param('id', ParseUUIDPipe) id: string) {
    return this.roomsService.deleteInviteCode(req.user.userId, id);
  }

  @Delete(':id')
  leaveOrDeleteRoom(@Req() req: any, @Param('id', ParseUUIDPipe) id: string) {
    return this.roomsService.leaveOrDeleteRoom(req.user.userId, id);
  }
}
