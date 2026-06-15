import { Injectable, Inject, NotFoundException, ConflictException } from '@nestjs/common';
import { eq, and, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { budgets } from '../database/schema';
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
      'New Budget Created',
      `Budget for ${newBudget.monthYear} has been set to ${formatCurrency(newBudget.limitAmount)}.`,
      'budget'
    );

    return newBudget;
  }

  async findAll(userId: string, query: any) {
    const { monthYear, page = 1, limit = 10 } = query;
    const offset = (Number(page) - 1) * Number(limit);

    const conditions = [eq(budgets.userId, userId)];
    if (monthYear) conditions.push(eq(budgets.monthYear, monthYear));

    const data = await this.db.query.budgets.findMany({
      where: and(...conditions),
      with: { category: true },
      limit: Number(limit),
      offset: offset,
    });

    const formattedData = data.map(b => ({
      ...b,
      limitAmountFormatted: formatCurrency(b.limitAmount),
    }));

    // Dynamic count query
    const countQuery = sql`SELECT count(*) FROM ${budgets} WHERE ${budgets.userId} = ${userId}`;
    if (monthYear) countQuery.append(sql` AND ${budgets.monthYear} = ${monthYear}`);
    const [{ count }] = await this.db.execute(countQuery);

    return formatPaginatedResponse(formattedData, count, Number(page), Number(limit));
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
}
