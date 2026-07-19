import { Injectable, Inject, NotFoundException, BadRequestException } from '@nestjs/common';
import { eq, and, count, sum, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { userProfiles, wallets, users, savingsGoals, transactions, roomMembers } from '../database/schema';
import { UpdateProfileDto, UpdateAvatarDto } from './dto/update-profile.dto';
import { sendWhatsAppMessage } from '../common/utils/whatsapp.util';

// ─── Border Achievement Definitions ───────────────────────────────────────────
// Daftar semua border achievement dan kondisi unlock-nya.
// Kondisi dicek server-side untuk keamanan.
const ACHIEVEMENT_BORDERS = [
  { id: 'border-legend',       label: 'Cuan Legend',           tier: 'platinum' },
  { id: 'border-500-tx',       label: 'Cuan Master',           tier: 'gold' },
];

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

  // ─── Achievement: Get Unlocked Borders ───────────────────────────────────────
  async getUnlockedBorders(userId: string): Promise<string[]> {
    const profile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.userId, userId),
    });
    if (!profile) throw new NotFoundException('Profile not found');
    const stored = profile.unlockedBorders;
    return Array.isArray(stored) ? stored : [];
  }

  // ─── Achievement: Check & Unlock Borders ─────────────────────────────────────
  /// Evaluasi semua kondisi achievement secara server-side.
  /// Border yang memenuhi syarat dan belum terbuka akan ditambahkan ke DB secara permanen.
  async checkAndUnlockBorders(userId: string): Promise<{ unlocked: string[]; newlyUnlocked: string[] }> {
    const profile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.userId, userId),
    });
    if (!profile) throw new NotFoundException('Profile not found');

    // ── Ambil data statistik yang diperlukan ──
    // Legend border: Aktif menggunakan Cuan Buddy selama 1 tahun penuh sejak bergabung (365 hari).
    const accountAgeDays = profile.createdAt
      ? Math.floor((Date.now() - new Date(profile.createdAt).getTime()) / (1000 * 60 * 60 * 24))
      : 0;

    // Cuan Master: Mencatat minimal 500 transaksi
    const txCountResult = await this.db
      .select({ count: count() })
      .from(transactions)
      .where(eq(transactions.userId, userId));
    const txCount = txCountResult[0]?.count ?? 0;

    // ── Evaluasi Kondisi Tiap Border ──
    const conditionsMet = new Set<string>();

    if (accountAgeDays >= 365) {
      conditionsMet.add('border-legend');
    }

    if (txCount >= 500) {
      conditionsMet.add('border-500-tx');
    }

    // ── Gabungkan dengan yang sudah tersimpan (permanent) ──
    const currentUnlocked: string[] = Array.isArray(profile.unlockedBorders)
      ? profile.unlockedBorders
      : [];
    const currentSet   = new Set(currentUnlocked);
    const newlyUnlocked: string[] = [];

    for (const borderId of conditionsMet) {
      if (!currentSet.has(borderId)) {
        newlyUnlocked.push(borderId);
        currentSet.add(borderId);
      }
    }

    // ── Simpan ke DB jika ada yang baru terbuka ──
    const finalList = Array.from(currentSet);
    if (newlyUnlocked.length > 0) {
      await this.db.update(userProfiles)
        .set({ unlockedBorders: finalList, updatedAt: new Date() })
        .where(eq(userProfiles.userId, userId));
    }

    return { unlocked: finalList, newlyUnlocked };
  }

  // ─── Achievement: Update Recording Streak ────────────────────────────────────
  /// Dipanggil setiap kali user mencatat transaksi.
  /// Streak increment jika hari ini belum pernah mencatat, reset jika skip 1+ hari.
  async updateRecordingStreak(userId: string): Promise<void> {
    const profile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.userId, userId),
    });
    if (!profile) return;

    const now      = new Date();
    const today    = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const lastDate = profile.lastRecordedAt ? new Date(profile.lastRecordedAt) : null;

    if (lastDate) {
      const lastDay        = new Date(lastDate.getFullYear(), lastDate.getMonth(), lastDate.getDate());
      const diffDays       = Math.floor((today.getTime() - lastDay.getTime()) / (1000 * 60 * 60 * 24));

      if (diffDays === 0) {
        // Sudah mencatat hari ini, tidak perlu update streak
        return;
      } else if (diffDays === 1) {
        // Hari berturut-turut: increment streak
        await this.db.update(userProfiles)
          .set({
            recordingStreakCount: (profile.recordingStreakCount ?? 0) + 1,
            lastRecordedAt: now,
            updatedAt: new Date(),
          })
          .where(eq(userProfiles.userId, userId));
      } else {
        // Skip 1+ hari: reset streak ke 1
        await this.db.update(userProfiles)
          .set({ recordingStreakCount: 1, lastRecordedAt: now, updatedAt: new Date() })
          .where(eq(userProfiles.userId, userId));
      }
    } else {
      // Pertama kali mencatat: mulai streak dari 1
      await this.db.update(userProfiles)
        .set({ recordingStreakCount: 1, lastRecordedAt: now, updatedAt: new Date() })
        .where(eq(userProfiles.userId, userId));
    }

    // Cek apakah ada achievement baru setelah update streak
    await this.checkAndUnlockBorders(userId);
  }
}
