import { Injectable, Inject } from '@nestjs/common';
import { eq, and, sum } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { transactions, savingsGoals } from '../database/schema';
import { formatCurrency, formatDate } from '../common/utils/formatter.util';

@Injectable()
export class AnalyticsService {
  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  async getSummary(userId: string) {
    const allTransactions = await this.db.query.transactions.findMany({
      where: eq(transactions.userId, userId),
    });

    const income = allTransactions
      .filter(t => t.type === 'income')
      .reduce((acc, curr) => acc + Number(curr.amount), 0);
      
    const expense = allTransactions
      .filter(t => t.type === 'expense')
      .reduce((acc, curr) => acc + Number(curr.amount), 0);

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
    const expenses = await this.db.query.transactions.findMany({
      where: and(eq(transactions.userId, userId), eq(transactions.type, 'expense')),
      with: { category: true }
    });

    const grouped = expenses.reduce((acc, curr) => {
      const catName = curr.category?.name || 'Uncategorized';
      if (!acc[catName]) acc[catName] = 0;
      acc[catName] += Number(curr.amount);
      return acc;
    }, {});

    return Object.entries(grouped).map(([category, amount]) => ({ 
      category, 
      amount,
      amountFormatted: formatCurrency(amount as number),
    }));
  }

  async getMonthlyTrend(userId: string) {
    const allTransactions = await this.db.query.transactions.findMany({
      where: eq(transactions.userId, userId),
    });

    const trend = allTransactions.reduce((acc, curr) => {
      const monthYear = curr.date.toISOString().slice(0, 7); // YYYY-MM
      if (!acc[monthYear]) acc[monthYear] = { income: 0, expense: 0 };
      
      if (curr.type === 'income') acc[monthYear].income += Number(curr.amount);
      if (curr.type === 'expense') acc[monthYear].expense += Number(curr.amount);
      return acc;
    }, {});

    return Object.entries(trend).map(([month, data]: [string, any]) => ({
      month,
      income: data.income,
      incomeFormatted: formatCurrency(data.income),
      expense: data.expense,
      expenseFormatted: formatCurrency(data.expense),
    })).sort((a, b) => a.month.localeCompare(b.month));
  }

  async getFinancialHealth(userId: string) {
    const summary = await this.getSummary(userId);
    let score = 50; // Base score
    
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
    const goals = await this.db.query.savingsGoals.findMany({
      where: eq(savingsGoals.userId, userId),
    });

    return goals.map(goal => ({
      id: goal.id,
      name: goal.name,
      targetAmount: Number(goal.targetAmount),
      targetAmountFormatted: formatCurrency(goal.targetAmount),
      currentAmount: Number(goal.currentAmount),
      currentAmountFormatted: formatCurrency(goal.currentAmount),
      progressPercentage: (Number(goal.currentAmount) / Number(goal.targetAmount)) * 100,
      status: goal.status
    }));
  }
}
