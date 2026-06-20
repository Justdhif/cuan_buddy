import { Injectable, Inject } from '@nestjs/common';
import { eq, and, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { transactions, savingsGoals, budgets } from '../database/schema';
import { formatCurrency } from '../common/utils/formatter.util';

@Injectable()
export class AnalyticsService {
  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  async getSummary(userId: string) {
    // Optimized: single SQL aggregate query instead of fetching all rows to JS
    const [result] = await this.db
      .select({
        totalIncome: sql<number>`COALESCE(SUM(CASE WHEN type = 'income' THEN amount::numeric ELSE 0 END), 0)`,
        totalExpense: sql<number>`COALESCE(SUM(CASE WHEN type = 'expense' THEN amount::numeric ELSE 0 END), 0)`,
      })
      .from(transactions)
      .where(eq(transactions.userId, userId));

    const income = Number(result.totalIncome);
    const expense = Number(result.totalExpense);

    return {
      totalIncome: income,
      totalIncomeFormatted: formatCurrency(income),
      totalExpense: expense,
      totalExpenseFormatted: formatCurrency(expense),
      balance: income - expense,
      balanceFormatted: formatCurrency(income - expense),
    };
  }

  async getSpendingByCategory(userId: string) {
    // Optimized: aggregate and group by category in SQL
    const results = await this.db
      .select({
        categoryName: sql<string>`COALESCE(c.name, 'Uncategorized')`,
        emojiIcon: sql<string>`MAX(c.emoji_icon)`,
        total: sql<number>`SUM(t.amount::numeric)`,
      })
      .from(sql`${transactions} t`)
      .leftJoin(sql`categories c ON c.id = t.category_id`)
      .where(sql`t.user_id = ${userId} AND t.type = 'expense'`)
      .groupBy(sql`COALESCE(c.name, 'Uncategorized')`)
      .orderBy(sql`SUM(t.amount::numeric) DESC`);

    return results.map((row: any) => ({
      category: row.categoryName,
      emojiIcon: row.emojiIcon ?? '📦',
      amount: Number(row.total),
      amountFormatted: formatCurrency(Number(row.total)),
    }));
  }

  async getMonthlyTrend(userId: string) {
    // Optimized: GROUP BY month in SQL, no JS reduce needed
    const results = await this.db
      .select({
        month: sql<string>`TO_CHAR(date, 'YYYY-MM')`,
        income: sql<number>`COALESCE(SUM(CASE WHEN type = 'income' THEN amount::numeric ELSE 0 END), 0)`,
        expense: sql<number>`COALESCE(SUM(CASE WHEN type = 'expense' THEN amount::numeric ELSE 0 END), 0)`,
      })
      .from(transactions)
      .where(eq(transactions.userId, userId))
      .groupBy(sql`TO_CHAR(date, 'YYYY-MM')`)
      .orderBy(sql`TO_CHAR(date, 'YYYY-MM') ASC`);

    return results.map((row: any) => ({
      month: row.month,
      income: Number(row.income),
      incomeFormatted: formatCurrency(Number(row.income)),
      expense: Number(row.expense),
      expenseFormatted: formatCurrency(Number(row.expense)),
    }));
  }

  async getFinancialHealth(userId: string) {
    const summary = await this.getSummary(userId);
    let score = 50;

    if (summary.totalIncome > 0) {
      const savingsRate = (summary.balance / summary.totalIncome) * 100;
      if (savingsRate > 20) score += 30;
      else if (savingsRate > 0) score += 10;
      else score -= 20;
    }

    const currentMonth = new Date().toISOString().slice(0, 7);
    const userBudgets = await this.db.query.budgets.findMany({
      where: and(eq(budgets.userId, userId), eq(budgets.monthYear, currentMonth)),
    });

    let overspentCount = 0;
    if (userBudgets.length > 0) {
      const expenses = await this.db
        .select({
          categoryId: transactions.categoryId,
          total: sql<number>`SUM(amount::numeric)`,
        })
        .from(transactions)
        .where(
          and(
            eq(transactions.userId, userId),
            eq(transactions.type, 'expense'),
            sql`TO_CHAR(date, 'YYYY-MM') = ${currentMonth}`
          )
        )
        .groupBy(transactions.categoryId);

      const expensesByCat = expenses.reduce((acc: any, row: any) => {
        acc[row.categoryId] = Number(row.total);
        return acc;
      }, {});

      for (const budget of userBudgets) {
        const spent = expensesByCat[budget.categoryId] || 0;
        if (spent > Number(budget.limitAmount)) {
          overspentCount++;
        }
      }
    }

    let status = 'healthy';
    let message = 'Your finances are looking great!';

    if (overspentCount > 0) {
      score -= 20 * overspentCount;
      status = overspentCount >= 2 ? 'danger' : 'warning';
      message = `You have exceeded your budget in ${overspentCount} categor${overspentCount > 1 ? 'ies' : 'y'}.`;
    } else if (summary.totalIncome > 0 && summary.balance < 0) {
      status = 'warning';
      message = 'You are spending more than you earn.';
    } else if (score < 50) {
      status = 'warning';
      message = 'Your savings rate is low. Try to save more!';
    } else if (score >= 80) {
      status = 'excellent';
    }

    return {
      score: Math.min(Math.max(score, 0), 100),
      status,
      message,
    };
  }

  async getSavingsProgress(userId: string) {
    const goals = await this.db
      .select()
      .from(savingsGoals)
      .where(eq(savingsGoals.userId, userId));

    return goals.map((goal: any) => ({
      id: goal.id,
      name: goal.name,
      targetAmount: Number(goal.targetAmount),
      targetAmountFormatted: formatCurrency(goal.targetAmount),
      currentAmount: Number(goal.currentAmount),
      currentAmountFormatted: formatCurrency(goal.currentAmount),
      progressPercentage:
        Number(goal.targetAmount) > 0
          ? (Number(goal.currentAmount) / Number(goal.targetAmount)) * 100
          : 0,
      status: goal.status,
    }));
  }
}
