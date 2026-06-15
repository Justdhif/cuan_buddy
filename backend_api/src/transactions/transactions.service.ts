import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq, and, gte, lte, desc, ilike, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { transactions } from '../database/schema';
import { CreateTransactionDto, UpdateTransactionDto } from './dto/transaction.dto';
import { formatPaginatedResponse, formatCurrency, formatDate } from '../common/utils/formatter.util';
import { NotificationsService } from '../notifications/notifications.service';
import { AiService } from '../ai/ai.service';

@Injectable()
export class TransactionsService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly notificationsService: NotificationsService,
    private readonly aiService: AiService,
  ) {}

  async create(userId: string, createTransactionDto: CreateTransactionDto) {
    const [newTransaction] = await this.db.insert(transactions).values({
      userId,
      ...createTransactionDto,
      date: new Date(createTransactionDto.date),
      amount: createTransactionDto.amount.toString(),
    }).returning();
    
    // Fire-and-forget: notification
    void this.notificationsService.createAndBroadcast(
      userId,
      'New Transaction Recorded',
      `You have successfully recorded a ${newTransaction.type} of ${formatCurrency(newTransaction.amount)}.`,
      'transaction'
    );

    // Fire-and-forget: anomaly detection — does not block response
    void this.aiService.detectAnomaly(
      userId,
      newTransaction.id,
      newTransaction.categoryId,
      Number(newTransaction.amount),
      newTransaction.type,
    );

    return newTransaction;
  }

  async findAll(userId: string, query: any) {
    const { 
      startDate, endDate, categoryId, type, 
      search, page = 1, limit = 10 
    } = query;

    const conditions = [eq(transactions.userId, userId)];

    if (startDate) conditions.push(gte(transactions.date, new Date(startDate)));
    if (endDate) conditions.push(lte(transactions.date, new Date(endDate)));
    if (categoryId) conditions.push(eq(transactions.categoryId, categoryId));
    if (type) conditions.push(eq(transactions.type, type));
    if (search) conditions.push(ilike(transactions.note, `%${search}%`));

    const offset = (Number(page) - 1) * Number(limit);

    const data = await this.db.query.transactions.findMany({
      where: and(...conditions),
      orderBy: [desc(transactions.date)],
      limit: Number(limit),
      offset: offset,
      with: {
        category: true
      }
    });

    const formattedData = data.map(t => ({
      ...t,
      amountFormatted: formatCurrency(t.amount),
      dateFormatted: formatDate(t.date),
    }));

    // Dynamic count query
    const countQuery = sql`SELECT count(*) FROM ${transactions} WHERE ${transactions.userId} = ${userId}`;
    if (startDate) countQuery.append(sql` AND ${transactions.date} >= ${new Date(startDate).toISOString()}`);
    if (endDate) countQuery.append(sql` AND ${transactions.date} <= ${new Date(endDate).toISOString()}`);
    if (categoryId) countQuery.append(sql` AND ${transactions.categoryId} = ${categoryId}`);
    if (type) countQuery.append(sql` AND ${transactions.type} = ${type}`);
    if (search) countQuery.append(sql` AND ${transactions.note} ILIKE ${`%${search}%`}`);

    const [{ count }] = await this.db.execute(countQuery);

    return formatPaginatedResponse(formattedData, count, Number(page), Number(limit));
  }

  async findOne(userId: string, id: string) {
    const transaction = await this.db.query.transactions.findFirst({
      where: and(eq(transactions.id, id), eq(transactions.userId, userId)),
      with: { category: true }
    });

    if (!transaction) throw new NotFoundException('Transaction not found');
    return transaction;
  }

  async update(userId: string, id: string, updateTransactionDto: UpdateTransactionDto) {
    // Optimized: single query — update with ownership check, no separate findOne
    const updateData: any = { ...updateTransactionDto, updatedAt: new Date() };
    if (updateTransactionDto.date) updateData.date = new Date(updateTransactionDto.date);
    if (updateTransactionDto.amount) updateData.amount = updateTransactionDto.amount.toString();

    const [updated] = await this.db.update(transactions)
      .set(updateData)
      .where(and(eq(transactions.id, id), eq(transactions.userId, userId)))
      .returning();

    if (!updated) throw new NotFoundException('Transaction not found');
    return updated;
  }

  async remove(userId: string, id: string) {
    // Optimized: single query — delete with ownership check, no separate findOne
    const [deleted] = await this.db.delete(transactions)
      .where(and(eq(transactions.id, id), eq(transactions.userId, userId)))
      .returning({ id: transactions.id });

    if (!deleted) throw new NotFoundException('Transaction not found');
    return { message: 'Transaction removed successfully' };
  }
}
