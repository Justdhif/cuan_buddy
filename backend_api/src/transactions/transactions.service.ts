import { Injectable, Inject, NotFoundException, ForbiddenException } from '@nestjs/common';
import { eq, and, or, gte, lte, desc, ilike, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { transactions, budgets, categories, savingsGoals, wallets, roomMembers, userProfiles } from '../database/schema';
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
import { roundDecimal } from '../common/utils/formatter.util';

@Injectable()
export class TransactionsService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly notificationsService: NotificationsService,
    private readonly aiService: AiService,
  ) {}

  async create(userId: string, createTransactionDto: CreateTransactionDto) {
    if (createTransactionDto.roomId) {
      const isMember = await this.db.query.roomMembers.findFirst({
        where: and(eq(roomMembers.roomId, createTransactionDto.roomId), eq(roomMembers.userId, userId)),
      });
      if (!isMember) {
        throw new ForbiddenException('You are not a member of this room');
      }
    }

    let finalTitle = createTransactionDto.title;
    if (!finalTitle) {
      finalTitle = createTransactionDto.note ?? undefined;
    }
    if (!finalTitle && createTransactionDto.categoryId) {
      const category = await this.db.query.categories.findFirst({
        where: eq(categories.id, createTransactionDto.categoryId),
      });
      if (category) {
        finalTitle = category.name;
      }
    }
    if (!finalTitle) {
      finalTitle = createTransactionDto.type === 'income' ? 'Income' : 'Expense';
    }

    const wallet = await this.db.query.wallets.findFirst({
      where: and(eq(wallets.id, createTransactionDto.walletId), eq(wallets.userId, userId)),
    });
    const walletPrecision = wallet?.decimalPrecision ?? 2;
    const roundedAmount = roundDecimal(createTransactionDto.amount, walletPrecision);

    const exchangeRate = createTransactionDto.exchangeRate ?? 1;
    const baseAmount = roundDecimal(roundedAmount * exchangeRate, 2);

    const [newTransaction] = await this.db
      .insert(transactions)
      .values({
        userId,
        ...createTransactionDto,
        title: finalTitle,
        date: new Date(createTransactionDto.date),
        amount: roundedAmount.toString(),
        exchangeRate: exchangeRate.toString(),
        baseAmount: baseAmount.toString(),
      })
      .returning();

    // Update wallet balance
    await this.applyWalletEffect(userId, createTransactionDto.walletId, createTransactionDto.type as 'income' | 'expense', roundedAmount);

    if (newTransaction.savingsGoalId) {
      void this.applySavingsGoalEffect(userId, newTransaction.savingsGoalId, newTransaction.type as 'income' | 'expense', Number(newTransaction.amount), Number(newTransaction.baseAmount));
    }

    // Fire-and-forget: notification
    void this.notificationsService.createAndBroadcast(
      userId,
      'TRANSACTION_RECORDED',
      JSON.stringify({
        type: newTransaction.type,
        amount: Number(newTransaction.amount),
        currency: wallet?.currency ?? 'IDR'
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
      void this.checkBudgetThreshold(userId, newTransaction.categoryId, newTransaction.date, newTransaction.walletId);
    }

    // Fire-and-forget: update recording streak for achievements
    void this.updateRecordingStreak(userId);

    return newTransaction;
  }

  private async applyWalletEffect(userId: string, walletId: string, type: 'income' | 'expense', amount: number, isRevert: boolean = false) {
    const wallet = await this.db.query.wallets.findFirst({
      where: and(eq(wallets.id, walletId), eq(wallets.userId, userId))
    });
    if (!wallet) return;

    const roundedAmount = roundDecimal(amount, wallet.decimalPrecision ?? 2);

    let adjustment = type === 'income' ? roundedAmount : -roundedAmount;
    if (isRevert) {
      adjustment = -adjustment;
    }

    const newBalance = roundDecimal(Number(wallet.balance) + adjustment, wallet.decimalPrecision ?? 2);
    await this.db.update(wallets).set({ balance: newBalance.toString(), updatedAt: new Date() }).where(eq(wallets.id, walletId));
  }

  private async applySavingsGoalEffect(userId: string, goalId: string | null, type: 'income' | 'expense', amount: number, baseAmount: number, isRevert: boolean = false) {
    if (!goalId) return;
    const goal = await this.db.query.savingsGoals.findFirst({
      where: and(eq(savingsGoals.id, goalId), eq(savingsGoals.userId, userId))
    });
    if (!goal) return;

    let adjustment = type === 'income' ? (goal.walletId ? amount : baseAmount) : -(goal.walletId ? amount : baseAmount);
    if (isRevert) {
      adjustment = -adjustment;
    }

    const newAmount = Number(goal.currentAmount) + adjustment;
    const updateData: any = { currentAmount: newAmount.toString(), updatedAt: new Date() };

    if (newAmount >= Number(goal.targetAmount) && goal.status !== 'completed' && adjustment > 0) {
      updateData.status = 'completed';
      void this.notificationsService.createAndBroadcast(
        userId,
        'Goal Reached! 🎉',
        `Congratulations! You have reached your savings goal: ${goal.name}.`,
        'goal'
      );
    } else if (newAmount < Number(goal.targetAmount) && goal.status === 'completed' && adjustment < 0) {
      updateData.status = 'in_progress';
    }

    await this.db.update(savingsGoals).set(updateData).where(eq(savingsGoals.id, goalId));
  }

  private async checkBudgetThreshold(userId: string, categoryId: string, transactionDate: Date, transactionWalletId: string) {
    try {
      const monthYear = `${transactionDate.getFullYear()}-${String(transactionDate.getMonth() + 1).padStart(2, '0')}`;
      
      const applicableBudgets = await this.db.query.budgets.findMany({
        where: and(
          eq(budgets.userId, userId),
          eq(budgets.categoryId, categoryId),
          eq(budgets.monthYear, monthYear),
          // Match global budgets or budget for this specific wallet
          sql`${budgets.walletId} IS NULL OR ${budgets.walletId} = ${transactionWalletId}`
        ),
        with: { category: true }
      });

      for (const budget of applicableBudgets) {
        const limitAmount = Number(budget.limitAmount);
        const startDate = new Date(transactionDate.getFullYear(), transactionDate.getMonth(), 1);
        const endDate = new Date(transactionDate.getFullYear(), transactionDate.getMonth() + 1, 0, 23, 59, 59, 999);
        
        const amountCol = budget.walletId ? sql<number>`SUM(amount::numeric)` : sql<number>`SUM(base_amount::numeric)`;
        const spentConds = [
          eq(transactions.userId, userId),
          eq(transactions.categoryId, categoryId),
          eq(transactions.type, 'expense'),
          gte(transactions.date, startDate),
          lte(transactions.date, endDate)
        ];
        if (budget.walletId) {
          spentConds.push(eq(transactions.walletId, budget.walletId));
        }

        const spentData = await this.db
          .select({ total: amountCol })
          .from(transactions)
          .where(and(...spentConds));
          
        const totalSpent = Number(spentData[0]?.total || 0);
        const categoryName = budget.category?.name || 'Category';

        if (totalSpent > limitAmount) {
          void this.notificationsService.createAndBroadcast(
            userId,
            'BUDGET_EXCEEDED',
            JSON.stringify({
              monthYear,
              categoryName,
              totalSpent,
              limitAmount,
            }),
            'budget'
          );
        } else {
          const currentDay = transactionDate.getDate();
          const totalDays = endDate.getDate();
          if (currentDay > 5) {
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
                }),
                'budget'
              );
            }
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
      walletId,
      savingsGoalId,
      type,
      search,
      roomId,
      page = 1,
      limit = 10,
    } = query;

    const conditions: any[] = [];

    if (roomId) {
      // Verify membership
      const isMember = await this.db.query.roomMembers.findFirst({
        where: and(eq(roomMembers.roomId, roomId), eq(roomMembers.userId, userId)),
      });
      if (!isMember) {
        throw new ForbiddenException('You are not a member of this room');
      }
      conditions.push(eq(transactions.roomId, roomId));
    } else {
      // Personal space - only list user's personal (non-room) transactions
      conditions.push(eq(transactions.userId, userId));
      conditions.push(sql`${transactions.roomId} IS NULL`);
    }

    if (startDate) conditions.push(gte(transactions.date, new Date(startDate)));
    if (endDate) conditions.push(lte(transactions.date, new Date(endDate)));
    if (categoryId) conditions.push(eq(transactions.categoryId, categoryId));
    if (walletId) conditions.push(eq(transactions.walletId, walletId));
    if (savingsGoalId) conditions.push(eq(transactions.savingsGoalId, savingsGoalId));
    if (type) conditions.push(eq(transactions.type, type));
    if (search) conditions.push(or(ilike(transactions.title, `%${search}%`), ilike(transactions.note, `%${search}%`))!);

    const offset = (Number(page) - 1) * Number(limit);

    const data = await this.db.query.transactions.findMany({
      where: and(...conditions),
      orderBy: [desc(transactions.date)],
      limit: Number(limit),
      offset: offset,
      with: {
        category: true,
        savingsGoal: true,
        wallet: true,
        user: {
          with: {
            profile: true,
          },
        },
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
      where: eq(transactions.id, id),
      with: { category: true, savingsGoal: true, wallet: true, user: { with: { profile: true } } },
    });

    if (!transaction) throw new NotFoundException('Transaction not found');

    if (transaction.userId !== userId) {
      if (!transaction.roomId) {
        throw new ForbiddenException('You do not have access to this transaction');
      }
      const isMember = await this.db.query.roomMembers.findFirst({
        where: and(eq(roomMembers.roomId, transaction.roomId), eq(roomMembers.userId, userId)),
      });
      if (!isMember) {
        throw new ForbiddenException('You are not a member of this room');
      }
    }

    return transaction;
  }

  async update(
    userId: string,
    id: string,
    updateTransactionDto: UpdateTransactionDto,
  ) {
    const oldTx = await this.db.query.transactions.findFirst({
      where: and(eq(transactions.id, id), eq(transactions.userId, userId)),
    });
    if (!oldTx) throw new NotFoundException('Transaction not found');

    const targetWalletId = updateTransactionDto.walletId ?? oldTx.walletId;
    const targetWallet = await this.db.query.wallets.findFirst({
      where: and(eq(wallets.id, targetWalletId), eq(wallets.userId, userId)),
    });
    const walletPrecision = targetWallet?.decimalPrecision ?? 2;

    const updateData: any = { ...updateTransactionDto, updatedAt: new Date() };
    if (updateTransactionDto.date)
      updateData.date = new Date(updateTransactionDto.date);
    if (updateTransactionDto.amount !== undefined || updateTransactionDto.walletId !== undefined) {
      const amt = roundDecimal(updateTransactionDto.amount ?? Number(oldTx.amount), walletPrecision);
      updateData.amount = amt.toString();
    }

    if (updateTransactionDto.amount !== undefined || updateTransactionDto.exchangeRate !== undefined || updateTransactionDto.walletId !== undefined) {
      const amt = roundDecimal(updateTransactionDto.amount ?? Number(oldTx.amount), walletPrecision);
      const rate = updateTransactionDto.exchangeRate ?? Number(oldTx.exchangeRate);
      updateData.exchangeRate = rate.toString();
      updateData.baseAmount = roundDecimal(amt * rate, 2).toString();
    }

    const [updated] = await this.db
      .update(transactions)
      .set(updateData)
      .where(and(eq(transactions.id, id), eq(transactions.userId, userId)))
      .returning();

    if (!updated) throw new NotFoundException('Transaction not found');

    // Handle Wallet sync
    if (oldTx.walletId !== updated.walletId) {
      await this.applyWalletEffect(userId, oldTx.walletId, oldTx.type as 'income' | 'expense', Number(oldTx.amount), true);
      await this.applyWalletEffect(userId, updated.walletId, updated.type as 'income' | 'expense', Number(updated.amount), false);
    } else if (Number(oldTx.amount) !== Number(updated.amount) || oldTx.type !== updated.type) {
      await this.applyWalletEffect(userId, oldTx.walletId, oldTx.type as 'income' | 'expense', Number(oldTx.amount), true);
      await this.applyWalletEffect(userId, updated.walletId, updated.type as 'income' | 'expense', Number(updated.amount), false);
    }

    // Handle savings goal sync
    // 1. Revert old
    if (oldTx.savingsGoalId) {
      await this.applySavingsGoalEffect(userId, oldTx.savingsGoalId, oldTx.type as 'income' | 'expense', Number(oldTx.amount), Number(oldTx.baseAmount), true);
    }
    // 2. Apply new
    if (updated.savingsGoalId) {
      await this.applySavingsGoalEffect(userId, updated.savingsGoalId, updated.type as 'income' | 'expense', Number(updated.amount), Number(updated.baseAmount), false);
    }

    return updated;
  }

  async remove(userId: string, id: string) {
    const [deleted] = await this.db
      .delete(transactions)
      .where(and(eq(transactions.id, id), eq(transactions.userId, userId)))
      .returning();

    if (!deleted) throw new NotFoundException('Transaction not found');
    
    await this.applyWalletEffect(userId, deleted.walletId, deleted.type as 'income' | 'expense', Number(deleted.amount), true);

    if (deleted.savingsGoalId) {
      await this.applySavingsGoalEffect(userId, deleted.savingsGoalId, deleted.type as 'income' | 'expense', Number(deleted.amount), Number(deleted.baseAmount), true);
    }

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

  private async updateRecordingStreak(userId: string) {
    try {
      const profile = await this.db.query.userProfiles.findFirst({
        where: eq(userProfiles.userId, userId),
      });
      if (!profile) return;

      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const lastDate = profile.lastRecordedAt ? new Date(profile.lastRecordedAt) : null;

      if (lastDate) {
        const lastDay = new Date(lastDate.getFullYear(), lastDate.getMonth(), lastDate.getDate());
        const diffDays = Math.floor((today.getTime() - lastDay.getTime()) / (1000 * 60 * 60 * 24));

        if (diffDays === 0) {
          return; // Already recorded today
        } else if (diffDays === 1) {
          // Increment streak
          await this.db.update(userProfiles)
            .set({
              recordingStreakCount: (profile.recordingStreakCount ?? 0) + 1,
              lastRecordedAt: now,
              updatedAt: now,
            })
            .where(eq(userProfiles.userId, userId));
        } else {
          // Reset streak to 1
          await this.db.update(userProfiles)
            .set({ recordingStreakCount: 1, lastRecordedAt: now, updatedAt: now })
            .where(eq(userProfiles.userId, userId));
        }
      } else {
        // First record
        await this.db.update(userProfiles)
          .set({ recordingStreakCount: 1, lastRecordedAt: now, updatedAt: now })
          .where(eq(userProfiles.userId, userId));
      }
    } catch (err) {
      console.error('Failed to update recording streak:', err);
    }
  }
}
