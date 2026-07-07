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
      walletId: createBudgetDto.walletId || null,
      limitAmount: createBudgetDto.limitAmount.toString(),
      periodCount: createBudgetDto.periodCount ?? 1,
      startDay: createBudgetDto.startDay ?? 1,
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

    const conditions = [eq(budgets.userId, userId)];

    // If monthYear filter is provided, find budgets that cover this month.
    // A budget starting at monthYear and spanning periodCount months covers
    // any queried month within that range.
    if (monthYear) {
      // We fetch all budgets for user then filter in JS so we can use periodCount
      // This is simpler than complex SQL date arithmetic on text month fields
    }

    const data = await this.db.query.budgets.findMany({
      where: and(...conditions),
      with: { 
        category: true,
        wallet: true 
      },
      limit: 200, // fetch all, filter in JS
      offset: 0,
    });

    // Filter budgets that cover the requested monthYear (if provided)
    const filteredData = monthYear
      ? data.filter((b) => {
          const startMY = b.monthYear; // YYYY-MM
          const pCount = b.periodCount ?? 1;
          const [sY, sM] = startMY.split('-').map(Number);
          const [qY, qM] = monthYear.split('-').map(Number);
          const startTotal = sY * 12 + (sM - 1);
          const queryTotal = qY * 12 + (qM - 1);
          return queryTotal >= startTotal && queryTotal < startTotal + pCount;
        })
      : data;

    const paginatedSlice = filteredData.slice(offset, offset + Number(limit));

    const formattedData = await Promise.all(paginatedSlice.map(async (b) => {
      const startDay = b.startDay ?? 1;
      const periodCount = b.periodCount ?? 1;

      // Compute actual start and end dates based on startDay and periodCount
      const [sYear, sMonth] = b.monthYear.split('-').map(Number);
      const periodStartDate = new Date(sYear, sMonth - 1, startDay);

      // End date: startDay of (startMonth + periodCount), minus 1 day
      const endMonthDate = new Date(sYear, sMonth - 1 + periodCount, startDay);
      endMonthDate.setDate(endMonthDate.getDate() - 1);
      endMonthDate.setHours(23, 59, 59, 999);

      // If budget has walletId, calculate against that wallet using raw amount
      // If global (no walletId), calculate against all wallets using baseAmount
      const amountCol = b.walletId ? sql<number>`SUM(amount::numeric)` : sql<number>`SUM(base_amount::numeric)`;
      const walletCond = b.walletId ? eq(transactions.walletId, b.walletId) : undefined;

      const spentConds = [
        eq(transactions.userId, userId),
        eq(transactions.categoryId, b.categoryId),
        eq(transactions.type, 'expense'),
        gte(transactions.date, periodStartDate),
        lte(transactions.date, endMonthDate)
      ];
      if (walletCond) spentConds.push(walletCond);

      const spentData = await this.db
        .select({ total: amountCol })
        .from(transactions)
        .where(and(...spentConds));

      const spentAmount = Number(spentData[0]?.total || 0);

      // Also compute income in the same period for the summary pill
      const incomeConds = [
        eq(transactions.userId, userId),
        eq(transactions.type, 'income'),
        gte(transactions.date, periodStartDate),
        lte(transactions.date, endMonthDate)
      ];
      if (walletCond) incomeConds.push(walletCond);

      const incomeData = await this.db
        .select({ total: amountCol })
        .from(transactions)
        .where(and(...incomeConds));

      const incomeAmount = Number(incomeData[0]?.total || 0);

      return {
        ...b,
        limitAmountFormatted: formatCurrency(b.limitAmount),
        spentAmount,
        incomeAmount,
        periodStartDate: periodStartDate.toISOString(),
        periodEndDate: endMonthDate.toISOString(),
      };
    }));

    const totalCount = filteredData.length;

    return formatPaginatedResponse(formattedData, totalCount, Number(page), Number(limit));
  }

  async findOne(userId: string, id: string) {
    const budget = await this.db.query.budgets.findFirst({
      where: and(eq(budgets.id, id), eq(budgets.userId, userId)),
      with: { category: true, wallet: true }
    });

    if (!budget) throw new NotFoundException('Budget not found');
    return budget;
  }

  async update(userId: string, id: string, updateBudgetDto: UpdateBudgetDto) {
    // Optimized: single query — no separate findOne before update
    const updateData: any = { ...updateBudgetDto, updatedAt: new Date() };
    if (updateBudgetDto.limitAmount) updateData.limitAmount = updateBudgetDto.limitAmount.toString();
    if (updateBudgetDto.walletId === null) updateData.walletId = null;

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
}
