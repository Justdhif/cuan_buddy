import { Injectable, Inject, Logger } from '@nestjs/common';
import { DATABASE_CONNECTION } from '../database/database.module';
import { feedbacks, userProfiles, users } from '../database/schema';
import { eq } from 'drizzle-orm';
import { sendWhatsAppMessage } from '../common/utils/whatsapp.util';

@Injectable()
export class FeedbackService {
  private readonly logger = new Logger(FeedbackService.name);

  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  async createFeedback(
    userId: string,
    data: {
      message: string;
      category?: string;
      rating?: number;
      deviceInfo?: string;
      appVersion?: string;
    },
  ) {
    const category = data.category || 'general';
    const rating = data.rating ?? 5;

    const [feedback] = await this.db
      .insert(feedbacks)
      .values({
        userId,
        message: data.message,
        category,
        rating,
        deviceInfo: data.deviceInfo,
        appVersion: data.appVersion,
      })
      .returning();

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

    const targetPhone = process.env.WA_ADMIN_PHONE || process.env.FONNTE_TARGET_PHONE;
    if (!targetPhone) {
      this.logger.warn(
        'WA_ADMIN_PHONE is not defined in environment. WhatsApp notification skipped.',
      );
      return feedback;
    }

    const ratingStars = '⭐'.repeat(rating);
    const waDescription =
      `*Category:* ${category.toUpperCase()}\n` +
      `*Rating:* ${ratingStars} (${rating}/5)\n` +
      `*Name:* ${profile?.fullName || 'Unknown'}\n` +
      `*Email:* ${userDetail?.email || 'Unknown'}\n` +
      `*Phone:* ${profile?.phoneNumber || 'Unknown'}\n` +
      `*Device:* ${data.deviceInfo || 'Unknown'}\n` +
      `*App Version:* ${data.appVersion || 'Unknown'}\n` +
      `*Time:* ${new Date().toUTCString()}\n\n` +
      `*Message:*\n"${data.message}"`;

    const result = await sendWhatsAppMessage({
      phone: targetPhone,
      title: 'NEW USER FEEDBACK',
      description: waDescription,
    });

    if (!result.success) {
      this.logger.error(
        `Failed to send WhatsApp feedback notification: ${result.reason}`,
      );
    } else {
      this.logger.log(`Feedback WhatsApp sent successfully to ${targetPhone}`);
    }

    return feedback;
  }
}
