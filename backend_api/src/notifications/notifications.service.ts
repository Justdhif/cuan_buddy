import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq, and, desc, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { notifications, users } from '../database/schema';
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

    // 2. Fetch User to check for FCM Token
    const userRecord = await this.db.query.users.findFirst({
      where: eq(users.id, userId),
    });

    if (userRecord?.fcmToken && getApps().length > 0) {
      let titleText = title;
      let bodyText = message;

      try {
        if (title === 'TRANSACTION_RECORDED') {
          titleText = 'Transaksi Baru Recorded 💰';
          const payload = JSON.parse(message);
          const typeStr = payload.type === 'income' ? 'Pemasukan' : 'Pengeluaran';
          const currencySymbol = payload.currency === 'USD' ? '$' : 'Rp';
          const amtStr = new Intl.NumberFormat('id-ID', { 
            style: 'currency', 
            currency: payload.currency || 'IDR', 
            maximumFractionDigits: 0 
          }).format(payload.amount);
          bodyText = `${typeStr} baru tercatat: ${amtStr}`;
        } else if (title === 'FRIEND_REQUEST') {
          titleText = 'Permintaan Pertemanan 👋';
          const payload = JSON.parse(message);
          const sender = payload.senderName || payload.senderEmail || 'Seseorang';
          bodyText = `${sender} ingin berteman dengan Anda`;
        } else if (title === 'FRIEND_REQUEST_ACCEPTED') {
          titleText = 'Pertemanan Diterima 🎉';
          const payload = JSON.parse(message);
          const receiver = payload.receiverName || payload.receiverEmail || 'Seseorang';
          bodyText = `${receiver} menerima permintaan pertemanan Anda`;
        } else if (title === 'FRIEND_REQUEST_DECLINED') {
          titleText = 'Pertemanan Ditolak ❌';
          const payload = JSON.parse(message);
          const receiver = payload.receiverName || payload.receiverEmail || 'Seseorang';
          bodyText = `${receiver} menolak permintaan pertemanan Anda`;
        } else if (title === 'ROOM_INVITATION') {
          titleText = 'Undangan Ruang 🏡';
          const payload = JSON.parse(message);
          const inviter = payload.inviterName || 'Seseorang';
          const room = payload.roomName || 'Ruang';
          bodyText = `${inviter} mengundang Anda ke ruang ${room}`;
        } else if (title === 'BUDGET_EXCEEDED') {
          titleText = 'Batas Anggaran Terlewati ⚠️';
          const payload = JSON.parse(message);
          bodyText = `Anggaran bulanan untuk ${payload.categoryName || 'kategori'} telah terlewati.`;
        } else if (title === 'BUDGET_WARNING') {
          titleText = 'Peringatan Anggaran ⚠️';
          const payload = JSON.parse(message);
          bodyText = `Penggunaan anggaran bulanan untuk ${payload.categoryName || 'kategori'} mencapai ${(payload.ratio * 100).toFixed(0)}%.`;
        } else if (title === 'BUDGET_PREDICTION_WARNING') {
          titleText = 'Prediksi Batas Anggaran 📈';
          const payload = JSON.parse(message);
          bodyText = `Pengeluaran diprediksi melebihi anggaran untuk ${payload.categoryName || 'kategori'}.`;
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
