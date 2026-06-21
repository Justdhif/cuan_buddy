import { Injectable, Inject, NotFoundException, ConflictException } from '@nestjs/common';
import { eq, and, sql, gte, lte } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { budgets, transactions } from '../database/schema';
import { CreateBudgetDto, UpdateBudgetDto } from './dto/budget.dto';
import { formatPaginatedResponse, formatCurrency } from '../common/utils/formatter.util';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class BudgetsService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly notificationsService: NotificationsService
  ) {}

  async create(userId: string, createBudgetDto: CreateBudgetDto) {
    // Check if budget for this category and month already exists
    const existing = await this.db.query.budgets.findFirst({
      where: and(
        eq(budgets.userId, userId),
        eq(budgets.categoryId, createBudgetDto.categoryId),
        eq(budgets.monthYear, createBudgetDto.monthYear)
      )
    });

    if (existing) {
      throw new ConflictException('Budget for this category and month already exists');
    }

    const [newBudget] = await this.db.insert(budgets).values({
      userId,
      ...createBudgetDto,
      limitAmount: createBudgetDto.limitAmount.toString()
    }).returning();

    // Fire-and-forget: do not await so response is returned immediately
    void this.notificationsService.createAndBroadcast(
      userId,
      'BUDGET_CREATED',
      JSON.stringify({
        monthYear: newBudget.monthYear,
        limitAmount: Number(newBudget.limitAmount),
        currency: newBudget.currency
      }),
      'budget'
    );

    return newBudget;
  }

  async findAll(userId: string, query: any) {
    const { monthYear, page = 1, limit = 10 } = query;
    const offset = (Number(page) - 1) * Number(limit);

    if (monthYear) {
      await this._generateRecurringBudgets(userId, monthYear);
    }

    const conditions = [eq(budgets.userId, userId)];
    if (monthYear) conditions.push(eq(budgets.monthYear, monthYear));

    const data = await this.db.query.budgets.findMany({
      where: and(...conditions),
      with: { category: true },
      limit: Number(limit),
      offset: offset,
    });

    const formattedData = await Promise.all(data.map(async (b) => {
      const [year, month] = b.monthYear.split('-');
      const startDate = new Date(Number(year), Number(month) - 1, 1);
      const endDate = new Date(Number(year), Number(month), 0, 23, 59, 59, 999);
      
      const spentData = await this.db
        .select({ total: sql<number>`SUM(amount::numeric)` })
        .from(transactions)
        .where(
          and(
            eq(transactions.userId, userId),
            eq(transactions.categoryId, b.categoryId),
            eq(transactions.type, 'expense'),
            gte(transactions.date, startDate),
            lte(transactions.date, endDate)
          )
        );
        
      const spentAmount = Number(spentData[0]?.total || 0);

      return {
        ...b,
        limitAmountFormatted: formatCurrency(b.limitAmount),
        spentAmount: spentAmount,
      };
    }));

    // Dynamic count query
    const countQuery = this.db
      .select({ count: sql`count(*)` })
      .from(budgets)
      .where(and(...conditions));

    const countData = await countQuery;
    const totalCount = Number(countData[0].count);

    return formatPaginatedResponse(formattedData, totalCount, Number(page), Number(limit));
  }

  async findOne(userId: string, id: string) {
    const budget = await this.db.query.budgets.findFirst({
      where: and(eq(budgets.id, id), eq(budgets.userId, userId)),
      with: { category: true }
    });

    if (!budget) throw new NotFoundException('Budget not found');
    return budget;
  }

  async update(userId: string, id: string, updateBudgetDto: UpdateBudgetDto) {
    // Optimized: single query — no separate findOne before update
    const updateData: any = { ...updateBudgetDto, updatedAt: new Date() };
    if (updateBudgetDto.limitAmount) updateData.limitAmount = updateBudgetDto.limitAmount.toString();

    const [updated] = await this.db.update(budgets)
      .set(updateData)
      .where(and(eq(budgets.id, id), eq(budgets.userId, userId)))
      .returning();

    if (!updated) throw new NotFoundException('Budget not found');
    return updated;
  }

  async remove(userId: string, id: string) {
    // Optimized: single query — delete with ownership check
    const [deleted] = await this.db.delete(budgets)
      .where(and(eq(budgets.id, id), eq(budgets.userId, userId)))
      .returning({ id: budgets.id });

    if (!deleted) throw new NotFoundException('Budget not found');
    return { message: 'Budget removed successfully' };
  }
  async _generateRecurringBudgets(userId: string, currentMonthYear: string) {
    const [year, month] = currentMonthYear.split('-').map(Number);
    // month is 1-indexed. Month - 2 gives previous month (since 0-indexed in JS)
    const prevDate = new Date(year, month - 2, 1);
    const prevMonth = String(prevDate.getMonth() + 1).padStart(2, '0');
    const prevYear = prevDate.getFullYear();
    const prevMonthYear = `${prevYear}-${prevMonth}`;

    const prevBudgets = await this.db.query.budgets.findMany({
      where: and(
        eq(budgets.userId, userId),
        eq(budgets.monthYear, prevMonthYear),
        eq(budgets.isRecurring, true)
      )
    });

    if (prevBudgets.length === 0) return;

    const currBudgets = await this.db.query.budgets.findMany({
      where: and(
        eq(budgets.userId, userId),
        eq(budgets.monthYear, currentMonthYear)
      )
    });
    const currCategoryIds = new Set(currBudgets.map(b => b.categoryId));

    for (const pb of prevBudgets) {
      if (!currCategoryIds.has(pb.categoryId)) {
        let rolloverAmount = 0;
        if (pb.rollover) {
          const startDate = new Date(prevYear, prevDate.getMonth(), 1);
          const endDate = new Date(prevYear, prevDate.getMonth() + 1, 0, 23, 59, 59, 999);
          const spentData = await this.db
            .select({ total: sql<number>`SUM(amount::numeric)` })
            .from(transactions)
            .where(
              and(
                eq(transactions.userId, userId),
                eq(transactions.categoryId, pb.categoryId),
                eq(transactions.type, 'expense'),
                gte(transactions.date, startDate),
                lte(transactions.date, endDate)
              )
            );
          const spent = Number(spentData[0]?.total || 0);
          const totalPrevLimit = Number(pb.limitAmount) + Number(pb.rolloverAmount);
          rolloverAmount = Math.max(0, totalPrevLimit - spent);
        }

        await this.db.insert(budgets).values({
          userId,
          categoryId: pb.categoryId,
          limitAmount: pb.limitAmount.toString(),
          isRecurring: true,
          rollover: pb.rollover,
          rolloverAmount: rolloverAmount.toString(),
          currency: pb.currency,
          monthYear: currentMonthYear
        });
      }
    }
  }
}
