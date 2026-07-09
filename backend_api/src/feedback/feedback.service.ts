import { Injectable, Inject, Logger } from '@nestjs/common';
import { DATABASE_CONNECTION } from '../database/database.module';
import { feedbacks, userProfiles, users } from '../database/schema';
import { eq } from 'drizzle-orm';

@Injectable()
export class FeedbackService {
  private readonly logger = new Logger(FeedbackService.name);

  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  async createFeedback(userId: string, message: string) {
    // 1. Save to Database
    const [feedback] = await this.db.insert(feedbacks).values({
      userId,
      message,
    }).returning();

    // 2. Fetch User Profile & Account details
    let profile: any = null;
    let userDetail: any = null;

    try {
      profile = await this.db.query.userProfiles.findFirst({
        where: eq(userProfiles.userId, userId),
      });
      userDetail = await this.db.query.users.findFirst({
        where: eq(users.id, userId),
      });
    } catch (err) {
      this.logger.error('Failed to fetch user info for feedback enrichment', err);
    }

    // 3. Send WhatsApp via Fonnte API
    const fonnteApiKey = process.env.FONNTE_API_KEY;
    const targetPhone = process.env.FONNTE_TARGET_PHONE;

    if (!fonnteApiKey) {
      this.logger.warn('FONNTE_API_KEY is not defined in environment. WhatsApp notification skipped.');
      return feedback;
    }

    const waMessage = `*FEEDBACK / MASUKAN BARU* 📩\n\n` +
      `*Nama:* ${profile?.fullName || 'Tidak Diketahui'}\n` +
      `*Email:* ${userDetail?.email || 'Tidak Diketahui'}\n` +
      `*No. HP:* ${profile?.phoneNumber || 'Tidak Diketahui'}\n` +
      `*Waktu:* ${new Date().toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' })}\n\n` +
      `*Pesan:*\n"${message}"`;

    try {
      const response = await fetch('https://api.fonnte.com/send', {
        method: 'POST',
        headers: {
          'Authorization': fonnteApiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          target: targetPhone,
          message: waMessage,
        }),
      });

      const resData = await response.json();
      if (!response.ok || !resData.status) {
        this.logger.error(`Fonnte API responded with error: ${JSON.stringify(resData)}`);
      } else {
        this.logger.log(`Feedback WhatsApp sent successfully to ${targetPhone}`);
      }
    } catch (error) {
      this.logger.error('Failed to send WhatsApp message via Fonnte', error);
    }

    return feedback;
  }
}
