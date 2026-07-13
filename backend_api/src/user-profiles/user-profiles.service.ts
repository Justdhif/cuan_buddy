import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq, and } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { userProfiles, wallets, users } from '../database/schema';
import { UpdateProfileDto, UpdateAvatarDto } from './dto/update-profile.dto';

@Injectable()
export class UserProfilesService {
  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

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
}
