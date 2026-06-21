import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq, and, gte, lte, desc, ilike, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { transactions, budgets } from '../database/schema';
import {
  CreateTransactionDto,
  UpdateTransactionDto,
} from './dto/transaction.dto';
import {
  formatPaginatedResponse,
  formatCurrency,
  formatDate,
} from '../common/utils/formatter.util';
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
    const [newTransaction] = await this.db
      .insert(transactions)
      .values({
        userId,
        ...createTransactionDto,
        date: new Date(createTransactionDto.date),
        amount: createTransactionDto.amount.toString(),
      })
      .returning();

    // Fire-and-forget: notification
    void this.notificationsService.createAndBroadcast(
      userId,
      'TRANSACTION_RECORDED',
      JSON.stringify({
        type: newTransaction.type,
        amount: Number(newTransaction.amount),
        currency: newTransaction.currency
      }),
      'transaction',
    );

    // Fire-and-forget: anomaly detection — does not block response
    void this.aiService.detectAnomaly(
      userId,
      newTransaction.id,
      newTransaction.categoryId,
      Number(newTransaction.amount),
      newTransaction.type,
    );

    // Fire-and-forget: check budget thresholds
    if (newTransaction.type === 'expense' && newTransaction.categoryId) {
      void this.checkBudgetThreshold(userId, newTransaction.categoryId, newTransaction.date);
    }

    return newTransaction;
  }

  private async checkBudgetThreshold(userId: string, categoryId: string, transactionDate: Date) {
    try {
      const monthYear = `${transactionDate.getFullYear()}-${String(transactionDate.getMonth() + 1).padStart(2, '0')}`;
      
      const budget = await this.db.query.budgets.findFirst({
        where: and(
          eq(budgets.userId, userId),
          eq(budgets.categoryId, categoryId),
          eq(budgets.monthYear, monthYear)
        ),
        with: { category: true }
      });

      if (!budget) return;

      const limitAmount = Number(budget.limitAmount);
      const startDate = new Date(transactionDate.getFullYear(), transactionDate.getMonth(), 1);
      const endDate = new Date(transactionDate.getFullYear(), transactionDate.getMonth() + 1, 0, 23, 59, 59, 999);
      
      const spentData = await this.db
        .select({ total: sql<number>`SUM(amount::numeric)` })
        .from(transactions)
        .where(
          and(
            eq(transactions.userId, userId),
            eq(transactions.categoryId, categoryId),
            eq(transactions.type, 'expense'),
            gte(transactions.date, startDate),
            lte(transactions.date, endDate)
          )
        );
        
      const totalSpent = Number(spentData[0]?.total || 0);
      const ratio = totalSpent / limitAmount;
      const categoryName = budget.category?.name || 'Category';

      if (ratio >= 1.0) {
        void this.notificationsService.createAndBroadcast(
          userId,
          'BUDGET_EXCEEDED',
          JSON.stringify({
            monthYear,
            categoryName,
            limitAmount,
            totalSpent,
            currency: budget.currency
          }),
          'budget'
        );
      } else if (ratio >= 0.75) {
        void this.notificationsService.createAndBroadcast(
          userId,
          'BUDGET_WARNING',
          JSON.stringify({
            monthYear,
            categoryName,
            ratio,
            currency: budget.currency
          }),
          'budget'
        );
      } else {
        const currentDay = transactionDate.getDate();
        const totalDays = endDate.getDate();
        if (currentDay > 5) { // Only predict if we have at least 5 days of data
          const dailyAvg = totalSpent / currentDay;
          const predicted = dailyAvg * totalDays;
          if (predicted > limitAmount) {
            void this.notificationsService.createAndBroadcast(
              userId,
              'BUDGET_PREDICTION_WARNING',
              JSON.stringify({
                monthYear,
                categoryName,
                predicted,
                limitAmount,
                currency: budget.currency
              }),
              'budget'
            );
          }
        }
      }
    } catch (err) {
      console.error('Failed to check budget threshold:', err);
    }
  }

  async findAll(userId: string, query: any) {
    const {
      startDate,
      endDate,
      categoryId,
      type,
      search,
      page = 1,
      limit = 10,
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
        category: true,
      },
    });

    const formattedData = data.map((t) => ({
      ...t,
      amountFormatted: formatCurrency(t.amount),
      dateFormatted: formatDate(t.date),
    }));

    const countData = await this.db
      .select({ count: sql`count(*)` })
      .from(transactions)
      .where(and(...conditions));

    const totalCount = Number(countData[0].count);

    return formatPaginatedResponse(
      formattedData,
      totalCount,
      Number(page),
      Number(limit),
    );
  }

  async findOne(userId: string, id: string) {
    const transaction = await this.db.query.transactions.findFirst({
      where: and(eq(transactions.id, id), eq(transactions.userId, userId)),
      with: { category: true },
    });

    if (!transaction) throw new NotFoundException('Transaction not found');
    return transaction;
  }

  async update(
    userId: string,
    id: string,
    updateTransactionDto: UpdateTransactionDto,
  ) {
    // Optimized: single query — update with ownership check, no separate findOne
    const updateData: any = { ...updateTransactionDto, updatedAt: new Date() };
    if (updateTransactionDto.date)
      updateData.date = new Date(updateTransactionDto.date);
    if (updateTransactionDto.amount)
      updateData.amount = updateTransactionDto.amount.toString();

    const [updated] = await this.db
      .update(transactions)
      .set(updateData)
      .where(and(eq(transactions.id, id), eq(transactions.userId, userId)))
      .returning();

    if (!updated) throw new NotFoundException('Transaction not found');
    return updated;
  }

  async remove(userId: string, id: string) {
    // Optimized: single query — delete with ownership check, no separate findOne
    const [deleted] = await this.db
      .delete(transactions)
      .where(and(eq(transactions.id, id), eq(transactions.userId, userId)))
      .returning({ id: transactions.id });

    if (!deleted) throw new NotFoundException('Transaction not found');
    return { message: 'Transaction removed successfully' };
  }

  async getCalendarSummary(userId: string, month: number, year: number) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59, 999);

    const conditions = [
      eq(transactions.userId, userId),
      gte(transactions.date, startDate),
      lte(transactions.date, endDate),
    ];

    const summary = await this.db
      .select({
        date: sql<string>`DATE(${transactions.date})`.as('date'),
        type: transactions.type,
        count: sql<number>`count(*)`.as('count'),
      })
      .from(transactions)
      .where(and(...conditions))
      .groupBy(sql`DATE(${transactions.date})`, transactions.type);

    return summary.map((row: any) => ({
      // Formatting date back to string in case it comes as a Date object from pg driver
      date: typeof row.date === 'string' ? row.date : row.date.toISOString().split('T')[0],
      type: row.type,
      count: Number(row.count),
    }));
  }
}
