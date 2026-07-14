import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq, and, desc, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { notifications, users, userProfiles } from '../database/schema';
import { formatPaginatedResponse, formatDate } from '../common/utils/formatter.util';
import { NotificationsGateway } from './notifications.gateway';
import { getApps, initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

@Injectable()
export class NotificationsService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly gateway: NotificationsGateway
  ) {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    if (getApps().length === 0) {
      const privateKey = process.env.FIREBASE_PRIVATE_KEY;
      const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
      const projectId = process.env.FIREBASE_PROJECT_ID;

      if (privateKey && clientEmail && projectId) {
        try {
          initializeApp({
            credential: cert({
              projectId,
              clientEmail,
              privateKey: privateKey.replace(/\\n/g, '\n'),
            }),
          });
          console.log('Firebase Admin initialized successfully.');
        } catch (e) {
          console.error('Failed to initialize Firebase Admin:', e);
        }
      } else {
        console.warn('Firebase Admin credentials missing. Push notifications will be logged only.');
      }
    }
  }

  async findAll(userId: string, query: any) {
    const { page = 1, limit = 10 } = query;
    const offset = (Number(page) - 1) * Number(limit);

    const data = await this.db.query.notifications.findMany({
      where: eq(notifications.userId, userId),
      orderBy: [desc(notifications.createdAt)],
      limit: Number(limit),
      offset: offset,
    });

    const formattedData = data.map(n => ({
      ...n,
      createdAtFormatted: formatDate(n.createdAt),
    }));

    const countData = await this.db
      .select({ count: sql`count(*)` })
      .from(notifications)
      .where(eq(notifications.userId, userId));

    const totalCount = Number(countData[0].count);

    return formatPaginatedResponse(formattedData, totalCount, Number(page), Number(limit));
  }

  async markAsRead(userId: string, id: string) {
    const [updated] = await this.db.update(notifications)
      .set({ isRead: true })
      .where(and(eq(notifications.id, id), eq(notifications.userId, userId)))
      .returning();
      
    if (!updated) throw new NotFoundException('Notification not found');
    return updated;
  }

  async createAndBroadcast(userId: string, title: string, message: string, type: string) {
    const [newNotification] = await this.db.insert(notifications).values({
      userId,
      title,
      message,
      type,
    }).returning();

    // 1. Broadcast via WebSockets for real-time foreground updates
    this.gateway.sendToUser(userId, 'new_notification', {
      ...newNotification,
      createdAtFormatted: formatDate(newNotification.createdAt),
    });

    // 2. Fetch User and Profile to check for FCM Token and Language
    const userRecord = await this.db.query.users.findFirst({
      where: eq(users.id, userId),
    });

    if (userRecord?.fcmToken && getApps().length > 0) {
      const profile = await this.db.query.userProfiles.findFirst({
        where: eq(userProfiles.userId, userId),
      });
      const lang = profile?.language || 'en';

      let titleText = title;
      let bodyText = message;

      try {
        const payload = JSON.parse(message);

        if (title === 'TRANSACTION_RECORDED') {
          const isId = lang === 'id';
          titleText = isId ? 'Transaksi Baru 💰' : 'New Transaction Recorded 💰';
          const typeStr = payload.type === 'income' 
            ? (isId ? 'Pemasukan' : 'Income') 
            : (isId ? 'Pengeluaran' : 'Expense');
          const amtStr = new Intl.NumberFormat(isId ? 'id-ID' : 'en-US', { 
            style: 'currency', 
            currency: payload.currency || 'IDR', 
            maximumFractionDigits: 0 
          }).format(payload.amount);
          bodyText = isId 
            ? `${typeStr} baru tercatat: ${amtStr}` 
            : `New ${typeStr.toLowerCase()} recorded: ${amtStr}`;
        } else if (title === 'FRIEND_REQUEST') {
          const isId = lang === 'id';
          titleText = isId ? 'Permintaan Pertemanan 👋' : 'Friend Request 👋';
          const sender = payload.senderName || payload.senderEmail || (isId ? 'Seseorang' : 'Someone');
          bodyText = isId 
            ? `${sender} ingin berteman dengan Anda` 
            : `${sender} wants to be friends with you`;
        } else if (title === 'FRIEND_REQUEST_ACCEPTED') {
          const isId = lang === 'id';
          titleText = isId ? 'Pertemanan Diterima 🎉' : 'Friend Request Accepted 🎉';
          const receiver = payload.receiverName || payload.receiverEmail || (isId ? 'Seseorang' : 'Someone');
          bodyText = isId 
            ? `${receiver} menerima permintaan pertemanan Anda` 
            : `${receiver} accepted your friend request`;
        } else if (title === 'FRIEND_REQUEST_DECLINED') {
          const isId = lang === 'id';
          titleText = isId ? 'Pertemanan Ditolak ❌' : 'Friend Request Declined ❌';
          const receiver = payload.receiverName || payload.receiverEmail || (isId ? 'Seseorang' : 'Someone');
          bodyText = isId 
            ? `${receiver} menolak permintaan pertemanan Anda` 
            : `${receiver} declined your friend request`;
        } else if (title === 'ROOM_INVITATION') {
          const isId = lang === 'id';
          titleText = isId ? 'Undangan Ruang 🏡' : 'Room Invitation 🏡';
          const inviter = payload.inviterName || (isId ? 'Seseorang' : 'Someone');
          const room = payload.roomName || (isId ? 'Ruang' : 'Room');
          bodyText = isId 
            ? `${inviter} mengundang Anda ke ruang ${room}` 
            : `${inviter} invited you to room ${room}`;
        } else if (title === 'BUDGET_EXCEEDED') {
          const isId = lang === 'id';
          titleText = isId ? 'Batas Anggaran Terlewati ⚠️' : 'Budget Exceeded ⚠️';
          const category = payload.categoryName || (isId ? 'kategori' : 'category');
          bodyText = isId 
            ? `Anggaran bulanan untuk ${category} telah terlewati.` 
            : `Monthly budget for ${category} has been exceeded.`;
        } else if (title === 'BUDGET_WARNING') {
          const isId = lang === 'id';
          titleText = isId ? 'Peringatan Anggaran ⚠️' : 'Budget Warning ⚠️';
          const category = payload.categoryName || (isId ? 'kategori' : 'category');
          const percentage = (payload.ratio * 100).toFixed(0);
          bodyText = isId 
            ? `Penggunaan anggaran bulanan untuk ${category} mencapai ${percentage}%.` 
            : `Monthly budget usage for ${category} has reached ${percentage}%.`;
        } else if (title === 'BUDGET_PREDICTION_WARNING') {
          const isId = lang === 'id';
          titleText = isId ? 'Prediksi Batas Anggaran 📈' : 'Budget Limit Prediction 📈';
          const category = payload.categoryName || (isId ? 'kategori' : 'category');
          bodyText = isId 
            ? `Pengeluaran diprediksi melebihi anggaran untuk ${category}.` 
            : `Spending is predicted to exceed the budget for ${category}.`;
        }
      } catch (_) {
        // Fallback to raw values if parsing fails
      }

      void getMessaging().send({
        token: userRecord.fcmToken,
        notification: {
          title: titleText,
          body: bodyText,
        },
        data: {
          type,
          payload: message,
        },
      }).catch(err => {
        console.error('Failed to send FCM push notification:', err);
      });
    }

    return newNotification;
  }
}
