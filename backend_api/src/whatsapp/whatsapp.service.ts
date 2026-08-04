import { Injectable, Inject, Logger } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { userProfiles, users } from '../database/schema';

@Injectable()
export class WhatsappService {
  private readonly logger = Logger.name ? new Logger('WhatsappService') : console;

  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
  ) {}

  /**
   * Generate 6-digit connection OTP for user in mobile/web app
   */
  async generateConnectOtp(userId: string): Promise<{ otp: string }> {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    await this.db
      .update(userProfiles)
      .set({ waConnectOtp: otp, updatedAt: new Date() })
      .where(eq(userProfiles.userId, userId));
    return { otp };
  }

  /**
   * Pair WhatsApp phone number with CuanBuddy user via OTP
   */
  async connectAccountViaOtp(fromNumber: string, otp: string) {
    const profile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.waConnectOtp, otp),
    });

    if (!profile) {
      return { success: false, message: 'Kode OTP tidak valid atau sudah kadaluarsa.' };
    }

    // Connect user: save WA phone number and clear OTP
    await this.db
      .update(userProfiles)
      .set({
        phoneNumber: fromNumber,
        waConnectOtp: null,
        updatedAt: new Date(),
      })
      .where(eq(userProfiles.userId, profile.userId));

    // Get user email for confirmation message
    const user = await this.db.query.users.findFirst({ where: eq(users.id, profile.userId) });

    return {
      success: true,
      message: 'Akun CuanBuddy berhasil terhubung!',
      email: user?.email || '',
    };
  }
}
