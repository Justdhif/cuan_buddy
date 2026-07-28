import { Injectable, Inject, Logger } from '@nestjs/common';
import { DATABASE_CONNECTION } from '../database/database.module';
import { feedbacks, userProfiles, users } from '../database/schema';
import { eq } from 'drizzle-orm';
import { sendWhatsAppMessage } from '../common/utils/whatsapp.util';

@Injectable()
export class FeedbackService {
  private readonly logger = new Logger(FeedbackService.name);

  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  async createFeedback(userId: string, message: string, imageUrl?: string) {

    const [feedback] = await this.db.insert(feedbacks).values({
      userId,
      message,
    }).returning();

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

    // Construct backend public URL dynamically
    let baseUrl = process.env.APP_BASE_URL;
    if (!baseUrl && process.env.VERCEL_URL) {
      baseUrl = `https://${process.env.VERCEL_URL}`;
    }
    if (!baseUrl) {
      baseUrl = 'https://cuan-buddy-api.vercel.app';
    }

    const defaultPublicBanner = `${baseUrl.replace(/\/$/, '')}/images/feedback_banner.jpg`;
    const finalImageUrl = imageUrl || process.env.FEEDBACK_BANNER_URL || defaultPublicBanner;

    const result = await sendWhatsAppMessage({
      phone: targetPhone,
      title: 'NEW USER FEEDBACK',
      description: waDescription,
      imageUrl: finalImageUrl,
    });

    if (!result.success) {
      this.logger.error(`Failed to send WhatsApp message via Fonnte: ${result.reason}`);
    } else {
      this.logger.log(`Feedback WhatsApp sent successfully to ${targetPhone}`);
    }

    return feedback;
  }
}
