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
  async getProfile(@Req() req) {
    const profile = await this.userProfilesService.getProfile(req.user.userId);
    // Evaluasi achievement setiap kali user load profil (fire-and-forget, tidak blok response)
    this.userProfilesService.checkAndUnlockBorders(req.user.userId).catch(() => {});
    return profile;
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

  @Patch('fcm-token')
  updateFcmToken(@Req() req, @Body() body: { token: string }) {
    return this.userProfilesService.updateFcmToken(req.user.userId, body.token);
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

  // ─── Achievement Endpoints ─────────────────────────────────────────────────

  /// Kembalikan list border ID yang sudah di-unlock oleh user ini secara permanen.
  @Get('unlocked-borders')
  getUnlockedBorders(@Req() req) {
    return this.userProfilesService.getUnlockedBorders(req.user.userId);
  }

  /// Evaluasi ulang semua kondisi achievement dan unlock border baru jika ada.
  /// Kembalikan { unlocked: string[], newlyUnlocked: string[] }
  @Post('check-achievements')
  checkAchievements(@Req() req) {
    return this.userProfilesService.checkAndUnlockBorders(req.user.userId);
  }

  @Post('phone/send-otp')
  sendOtp(@Req() req, @Body() body: { phone: string }) {
    if (!body.phone) {
      throw new BadRequestException('Phone number is required');
    }
    return this.userProfilesService.sendOtp(req.user.userId, body.phone);
  }

  @Post('phone/verify-otp')
  verifyOtp(@Req() req, @Body() body: { phone: string; code: string }) {
    if (!body.phone || !body.code) {
      throw new BadRequestException('Phone and code are required');
    }
    return this.userProfilesService.verifyOtp(req.user.userId, body.phone, body.code);
  }
}
