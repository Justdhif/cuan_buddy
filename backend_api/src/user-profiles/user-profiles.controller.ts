import { Controller, Get, Patch, Post, Body, UseGuards, Req, UseInterceptors, UploadedFile, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UserProfilesService } from './user-profiles.service';
import { UpdateProfileDto, UpdateAvatarDto } from './dto/update-profile.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

@UseGuards(JwtAuthGuard)
@Controller('profiles')
export class UserProfilesController {
  constructor(
    private readonly userProfilesService: UserProfilesService,
    private readonly cloudinaryService: CloudinaryService,
  ) {}

  @Get('me')
  getProfile(@Req() req) {
    return this.userProfilesService.getProfile(req.user.userId);
  }

  @Patch('me')
  async updateProfile(@Req() req, @Body() updateProfileDto: UpdateProfileDto) {
    try {
      return await this.userProfilesService.updateProfile(req.user.userId, updateProfileDto);
    } catch (error) {
      console.error('Profile Update Exception:', error);
      throw new BadRequestException(error.message || 'Failed to update profile');
    }
  }

  @Patch('avatar')
  updateAvatar(@Req() req, @Body() updateAvatarDto: UpdateAvatarDto) {
    return this.userProfilesService.updateAvatar(req.user.userId, updateAvatarDto);
  }

  @Post('avatar/upload')
  @UseInterceptors(FileInterceptor('file'))
  async uploadAvatar(@Req() req, @UploadedFile() file: Express.Multer.File) {
    try {
      if (!file) {
        throw new BadRequestException('File is required');
      }
      
      const result = await this.cloudinaryService.uploadImage(file).catch((err) => {
        console.error('Cloudinary Upload Error:', err);
        throw new BadRequestException('Failed to upload image to Cloudinary');
      });
      
      const secureUrl = result.secure_url;
      if (!secureUrl) {
        throw new Error('Cloudinary response missing secure_url');
      }
      
      // Update the database
      await this.userProfilesService.updateAvatar(req.user.userId, { avatar: secureUrl });
      
      return { avatar: secureUrl };
    } catch (error) {
      console.error('Avatar Upload Exception:', error);
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(error.message || 'An unexpected error occurred during upload');
    }
  }
}
