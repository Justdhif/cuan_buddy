import { Injectable, Inject, NotFoundException, BadRequestException } from '@nestjs/common';
import { eq, and } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { userProfiles, wallets, users } from '../database/schema';
import { UpdateProfileDto, UpdateAvatarDto } from './dto/update-profile.dto';
import { sendWhatsAppMessage } from '../common/utils/whatsapp.util';

@Injectable()
export class UserProfilesService {
  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  private otpStore = new Map<string, { code: string; expiresAt: number }>();

  private async getBaseCurrency(userId: string): Promise<string> {
    const baseWallet = await this.db.query.wallets.findFirst({
      where: and(eq(wallets.userId, userId), eq(wallets.isBaseCurrency, true)),
    });
    return baseWallet?.currency || 'IDR';
  }

  async getProfile(userId: string) {
    const profile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.userId, userId),
    });
    if (!profile) throw new NotFoundException('Profile not found');
    
    const currency = await this.getBaseCurrency(userId);
    return { ...profile, currency };
  }

  async updateProfile(userId: string, updateProfileDto: UpdateProfileDto) {
    const updateData: any = { ...updateProfileDto, updatedAt: new Date() };
    if (updateProfileDto.birthDate) {
      updateData.birthDate = new Date(updateProfileDto.birthDate);
    }

    const [updated] = await this.db.update(userProfiles)
      .set(updateData)
      .where(eq(userProfiles.userId, userId))
      .returning();
      
    const currency = await this.getBaseCurrency(userId);
    return { ...updated, currency };
  }

  async updateAvatar(userId: string, updateAvatarDto: UpdateAvatarDto) {
    const [updated] = await this.db.update(userProfiles)
      .set({ avatar: updateAvatarDto.avatar, updatedAt: new Date() })
      .where(eq(userProfiles.userId, userId))
      .returning();
      
    const currency = await this.getBaseCurrency(userId);
    return { ...updated, currency };
  }

  async updateFcmToken(userId: string, token: string) {
    await this.db.update(users)
      .set({ fcmToken: token, updatedAt: new Date() })
      .where(eq(users.id, userId));
    return { success: true };
  }

  async sendOtp(userId: string, phone: string) {
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes expiry
    this.otpStore.set(phone, { code, expiresAt });

    const result = await sendWhatsAppMessage({
      phone,
      title: 'OTP VERIFICATION CODE',
      description: `Your verification code is: ${code}. This code is valid for 5 minutes. Please do not share it with anyone.`,
    });

    if (!result.success) {
      throw new BadRequestException(`Failed to send WhatsApp OTP: ${result.reason}`);
    }

    return { success: true, message: 'OTP sent successfully' };
  }

  async verifyOtp(userId: string, phone: string, code: string) {
    const otpData = this.otpStore.get(phone);
    

    if (!otpData) {
      throw new BadRequestException('OTP not found or has expired. Please request a new one.');
    }

    if (Date.now() > otpData.expiresAt) {
      this.otpStore.delete(phone);
      throw new BadRequestException('OTP has expired. Please request a new one.');
    }

    if (otpData.code !== code) {
      throw new BadRequestException('Invalid OTP code.');
    }

    // Success: Update the phone number in user profile
    await this.updateProfile(userId, { phoneNumber: phone });
    this.otpStore.delete(phone);

    return { success: true, message: 'Phone number updated successfully' };
  }
}
