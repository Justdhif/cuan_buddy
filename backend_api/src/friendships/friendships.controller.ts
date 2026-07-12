import { Controller, Get, Post, Body, Req, UseGuards, Query } from '@nestjs/common';
import { FriendshipsService } from './friendships.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('friendships')
export class FriendshipsController {
  constructor(private readonly friendshipsService: FriendshipsService) {}

  @Post('request')
  sendRequest(@Req() req: any, @Body() body: { usernameOrEmail: string }) {
    return this.friendshipsService.sendRequest(req.user.userId, body.usernameOrEmail);
  }

  @Post('respond')
  respondRequest(
    @Req() req: any,
    @Body() body: { friendshipId: string; action: 'accept' | 'decline' }
  ) {
    return this.friendshipsService.respondRequest(req.user.userId, body.friendshipId, body.action);
  }

  @Get()
  listFriends(@Req() req: any) {
    return this.friendshipsService.listFriends(req.user.userId);
  }

  @Get('pending')
  listPending(@Req() req: any) {
    return this.friendshipsService.listPending(req.user.userId);
  }

  @Get('search')
  searchUsers(@Req() req: any, @Query('query') query: string) {
    return this.friendshipsService.searchUsers(req.user.userId, query);
  }
}
