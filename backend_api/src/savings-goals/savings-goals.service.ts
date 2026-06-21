import { Injectable, Inject, NotFoundException, ConflictException } from '@nestjs/common';
import { eq, and, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { savingsGoals } from '../database/schema';
import { CreateSavingsGoalDto, UpdateSavingsGoalDto } from './dto/savings-goal.dto';
import { formatPaginatedResponse, formatCurrency, formatDate } from '../common/utils/formatter.util';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class SavingsGoalsService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly notificationsService: NotificationsService
  ) {}

  async create(userId: string, createSavingsGoalDto: CreateSavingsGoalDto) {
    const data: any = {
      userId,
      name: createSavingsGoalDto.name,
      targetAmount: createSavingsGoalDto.targetAmount.toString(),
    };
    if (createSavingsGoalDto.currentAmount) data.currentAmount = createSavingsGoalDto.currentAmount.toString();
    if (createSavingsGoalDto.targetDate) data.targetDate = new Date(createSavingsGoalDto.targetDate);
    if (createSavingsGoalDto.status) data.status = createSavingsGoalDto.status;

    try {
      const [newGoal] = await this.db.insert(savingsGoals).values(data).returning();
      return newGoal;
    } catch (err: any) {
      if (
        err?.code === '23505' ||
        err?.message?.includes('unique') ||
        err?.cause?.code === '23505' ||
        err?.cause?.message?.includes('unique')
      ) {
        throw new ConflictException('A savings goal with this name already exists');
      }
      throw err;
    }
  }

  async findAll(userId: string, query: any) {
    const { page = 1, limit = 10 } = query;
    const offset = (Number(page) - 1) * Number(limit);

    const data = await this.db.query.savingsGoals.findMany({
      where: eq(savingsGoals.userId, userId),
      limit: Number(limit),
      offset: offset,
    });

    const formattedData = data.map(g => ({
      ...g,
      targetAmountFormatted: formatCurrency(g.targetAmount),
      currentAmountFormatted: formatCurrency(g.currentAmount),
      targetDateFormatted: formatDate(g.targetDate),
    }));

    const countData = await this.db
      .select({ count: sql`count(*)` })
      .from(savingsGoals)
      .where(eq(savingsGoals.userId, userId));

    const totalCount = Number(countData[0].count);

    return formatPaginatedResponse(formattedData, totalCount, Number(page), Number(limit));
  }

  async findOne(userId: string, id: string) {
    const goal = await this.db.query.savingsGoals.findFirst({
      where: and(eq(savingsGoals.id, id), eq(savingsGoals.userId, userId)),
    });

    if (!goal) {
      throw new NotFoundException('Savings goal not found');
    }
    return goal;
  }

  async update(userId: string, id: string, updateSavingsGoalDto: UpdateSavingsGoalDto) {
    await this.findOne(userId, id);

    const updateData: any = {};
    if (updateSavingsGoalDto.name) {
      updateData.name = updateSavingsGoalDto.name;
    }
    if (updateSavingsGoalDto.targetAmount) updateData.targetAmount = updateSavingsGoalDto.targetAmount.toString();
    if (updateSavingsGoalDto.currentAmount) updateData.currentAmount = updateSavingsGoalDto.currentAmount.toString();
    if (updateSavingsGoalDto.targetDate) updateData.targetDate = new Date(updateSavingsGoalDto.targetDate);
    if (updateSavingsGoalDto.status) updateData.status = updateSavingsGoalDto.status;

    const [updated] = await this.db
      .update(savingsGoals)
      .set({ ...updateData, updatedAt: new Date() })
      .where(and(eq(savingsGoals.id, id), eq(savingsGoals.userId, userId)))
      .returning();

    // Check if goal is reached after update
    if (updated && Number(updated.currentAmount) >= Number(updated.targetAmount) && updated.status !== 'completed') {
      await this.db.update(savingsGoals).set({ status: 'completed' }).where(eq(savingsGoals.id, updated.id));
      updated.status = 'completed';

      await this.notificationsService.createAndBroadcast(
        userId,
        'Goal Reached! 🎉',
        `Congratulations! You have reached your savings goal: ${updated.name}.`,
        'goal'
      );
    }

    return updated;
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id);
    await this.db.delete(savingsGoals)
      .where(and(eq(savingsGoals.id, id), eq(savingsGoals.userId, userId)));
    return { message: 'Savings goal deleted successfully' };
  }
}
