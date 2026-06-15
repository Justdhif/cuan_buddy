import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq, and, desc, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { notifications } from '../database/schema';
import { formatPaginatedResponse, formatDate } from '../common/utils/formatter.util';
import { NotificationsGateway } from './notifications.gateway';

@Injectable()
export class NotificationsService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly gateway: NotificationsGateway
  ) {}

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

    const [{ count }] = await this.db.execute(
      sql`SELECT count(*) FROM ${notifications} WHERE ${notifications.userId} = ${userId}`
    );

    return formatPaginatedResponse(formattedData, count, Number(page), Number(limit));
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

    // Broadcast via WebSockets
    this.gateway.sendToUser(userId, 'new_notification', {
      ...newNotification,
      createdAtFormatted: formatDate(newNotification.createdAt),
    });

    return newNotification;
  }
}
