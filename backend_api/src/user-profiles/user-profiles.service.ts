import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { userProfiles } from '../database/schema';
import { UpdateProfileDto, UpdateAvatarDto } from './dto/update-profile.dto';

@Injectable()
export class UserProfilesService {
  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  async getProfile(userId: string) {
    const profile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.userId, userId),
    });
    if (!profile) throw new NotFoundException('Profile not found');
    return profile;
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
      
    return updated;
  }

  async updateAvatar(userId: string, updateAvatarDto: UpdateAvatarDto) {
    const [updated] = await this.db.update(userProfiles)
      .set({ avatar: updateAvatarDto.avatar, updatedAt: new Date() })
      .where(eq(userProfiles.userId, userId))
      .returning();
      
    return updated;
  }
}
