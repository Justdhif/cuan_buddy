import { Injectable, Inject } from '@nestjs/common';
import { eq, and, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { transactions, savingsGoals } from '../database/schema';
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
        total: sql<number>`SUM(t.amount::numeric)`,
      })
      .from(sql`${transactions} t`)
      .leftJoin(sql`categories c ON c.id = t.category_id`)
      .where(sql`t.user_id = ${userId} AND t.type = 'expense'`)
      .groupBy(sql`COALESCE(c.name, 'Uncategorized')`)
      .orderBy(sql`SUM(t.amount::numeric) DESC`);

    return results.map((row: any) => ({
      category: row.categoryName,
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
    // Reuse getSummary — already optimized to single query
    const summary = await this.getSummary(userId);
    let score = 50;

    if (summary.totalIncome > 0) {
      const savingsRate = (summary.balance / summary.totalIncome) * 100;
      if (savingsRate > 20) score += 30;
      else if (savingsRate > 0) score += 10;
      else score -= 20;
    }

    return {
      score: Math.min(Math.max(score, 0), 100),
      status: score >= 80 ? 'Excellent' : score >= 50 ? 'Good' : 'Needs Improvement',
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
