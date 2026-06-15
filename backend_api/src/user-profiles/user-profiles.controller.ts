import { Controller, Get, Patch, Body, UseGuards, Req } from '@nestjs/common';
import { UserProfilesService } from './user-profiles.service';
import { UpdateProfileDto, UpdateAvatarDto } from './dto/update-profile.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('profiles')
export class UserProfilesController {
  constructor(private readonly userProfilesService: UserProfilesService) {}

  @Get('me')
  getProfile(@Req() req) {
    return this.userProfilesService.getProfile(req.user.userId);
  }

  @Patch('me')
  updateProfile(@Req() req, @Body() updateProfileDto: UpdateProfileDto) {
    return this.userProfilesService.updateProfile(req.user.userId, updateProfileDto);
  }

  @Patch('avatar')
  updateAvatar(@Req() req, @Body() updateAvatarDto: UpdateAvatarDto) {
    return this.userProfilesService.updateAvatar(req.user.userId, updateAvatarDto);
  }
}
