import { Injectable, Inject, Logger } from '@nestjs/common';
import { DATABASE_CONNECTION } from '../database/database.module';
import { feedbacks, userProfiles, users } from '../database/schema';
import { eq } from 'drizzle-orm';
import { sendWhatsAppMessage } from '../common/utils/whatsapp.util';

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
    const targetPhone = process.env.FONNTE_TARGET_PHONE;
    if (!targetPhone) {
      this.logger.warn('FONNTE_TARGET_PHONE is not defined in environment. WhatsApp notification skipped.');
      return feedback;
    }

    const waDescription = `*Name:* ${profile?.fullName || 'Unknown'}\n` +
      `*Email:* ${userDetail?.email || 'Unknown'}\n` +
      `*Phone:* ${profile?.phoneNumber || 'Unknown'}\n` +
      `*Time:* ${new Date().toUTCString()}\n\n` +
      `*Message:*\n"${message}"`;

    const result = await sendWhatsAppMessage({
      phone: targetPhone,
      title: 'NEW USER FEEDBACK',
      description: waDescription,
    });

    if (!result.success) {
      this.logger.error(`Failed to send WhatsApp message via Fonnte: ${result.reason}`);
    } else {
      this.logger.log(`Feedback WhatsApp sent successfully to ${targetPhone}`);
    }

    return feedback;
  }
}
