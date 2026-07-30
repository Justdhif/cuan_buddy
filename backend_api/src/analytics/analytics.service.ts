import { Injectable, Inject } from '@nestjs/common';
import { eq, and, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { transactions, savingsGoals, budgets } from '../database/schema';
import { formatCurrency } from '../common/utils/formatter.util';

@Injectable()
export class AnalyticsService {
  constructor(@Inject(DATABASE_CONNECTION) private readonly db: any) {}

  async getSummary(userId: string) {

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

    const currentScore = Math.min(Math.max(score, 0), 100);

    // Calculate scoreHistory for past 7 months accurately based on actual monthly data
    const scoreHistory: Array<{ date: string; score: number; status: string; message: string }> = [];
    const now = new Date();

    const getStatusAndMessage = (sc: number, hasTx: boolean) => {
      if (!hasTx) {
        return {
          status: 'healthy',
          message: 'No transaction data for this month.',
        };
      }
      if (sc >= 80) {
        return {
          status: 'excellent',
          message: 'Your finances are looking great!',
        };
      } else if (sc >= 50) {
        return {
          status: 'healthy',
          message: 'Financial condition is stable. Keep saving.',
        };
      } else {
        return {
          status: 'warning',
          message: 'High expense ratio or budget exceeded.',
        };
      }
    };


    // Calculate real score for each of the last 7 months
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;

      if (i === 0) {
        // Current month uses exact calculated score & status
        scoreHistory.push({
          date: monthStr,
          score: currentScore,
          status,
          message,
        });
      } else {
        // Query monthly income and expense for monthStr
        const [mSummary] = await this.db
          .select({
            totalIncome: sql<number>`COALESCE(SUM(CASE WHEN type = 'income' THEN amount::numeric ELSE 0 END), 0)`,
            totalExpense: sql<number>`COALESCE(SUM(CASE WHEN type = 'expense' THEN amount::numeric ELSE 0 END), 0)`,
          })
          .from(transactions)
          .where(
            and(
              eq(transactions.userId, userId),
              sql`TO_CHAR(date, 'YYYY-MM') = ${monthStr}`
            )
          );

        const mInc = Number(mSummary?.totalIncome || 0);
        const mExp = Number(mSummary?.totalExpense || 0);
        const hasTx = mInc > 0 || mExp > 0;

        if (!hasTx) {
          const { status: sStatus, message: sMsg } = getStatusAndMessage(100, false);
          scoreHistory.push({
            date: monthStr,
            score: 100,
            status: sStatus,
            message: sMsg,
          });
        } else {
          let mScore = 50;
          const savingsRate = mInc > 0 ? ((mInc - mExp) / mInc) * 100 : -20;
          if (savingsRate > 20) mScore += 30;
          else if (savingsRate > 0) mScore += 10;
          else mScore -= 20;

          // Check monthly budget overspends
          const mBudgets = await this.db.query.budgets.findMany({
            where: and(eq(budgets.userId, userId), eq(budgets.monthYear, monthStr)),
          });

          if (mBudgets.length > 0) {
            const mCatExpenses = await this.db
              .select({
                categoryId: transactions.categoryId,
                total: sql<number>`SUM(amount::numeric)`,
              })
              .from(transactions)
              .where(
                and(
                  eq(transactions.userId, userId),
                  eq(transactions.type, 'expense'),
                  sql`TO_CHAR(date, 'YYYY-MM') = ${monthStr}`
                )
              )
              .groupBy(transactions.categoryId);

            const mCatExpMap = mCatExpenses.reduce((acc: any, row: any) => {
              acc[row.categoryId] = Number(row.total);
              return acc;
            }, {});

            let mOverspentCount = 0;
            for (const b of mBudgets) {
              const spent = mCatExpMap[b.categoryId] || 0;
              if (spent > Number(b.limitAmount)) mOverspentCount++;
            }
            if (mOverspentCount > 0) mScore -= 20 * mOverspentCount;
          }

          const finalScore = Math.min(Math.max(mScore, 0), 100);
          const { status: sStatus, message: sMsg } = getStatusAndMessage(finalScore, true);
          scoreHistory.push({
            date: monthStr,
            score: finalScore,
            status: sStatus,
            message: sMsg,
          });
        }
      }
    }

    return {
      score: currentScore,
      status,
      message,
      scoreHistory,
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

  async getDailyBurnRate(userId: string, requestedMonthYear?: string) {
    const currentMonthStr = new Date().toISOString().slice(0, 7);
    const targetMonthYear = requestedMonthYear || currentMonthStr;

    const [yearStr, monthStr] = targetMonthYear.split('-');
    const year = parseInt(yearStr, 10);
    const month = parseInt(monthStr, 10);
    const totalDays = new Date(year, month, 0).getDate();

    const userBudgets = await this.db.query.budgets.findMany({
      where: and(eq(budgets.userId, userId), eq(budgets.monthYear, targetMonthYear)),
    });

    const totalBudget = userBudgets.reduce(
      (sum: number, b: any) => sum + Number(b.limitAmount),
      0
    );
    const dailySafeLimit = totalBudget > 0 ? Math.round(totalBudget / totalDays) : 0;

    const dailyTransactions = await this.db
      .select({
        day: sql<number>`EXTRACT(DAY FROM date)::int`,
        expense: sql<number>`COALESCE(SUM(CASE WHEN type = 'expense' THEN amount::numeric ELSE 0 END), 0)`,
        income: sql<number>`COALESCE(SUM(CASE WHEN type = 'income' THEN amount::numeric ELSE 0 END), 0)`,
      })
      .from(transactions)
      .where(
        and(
          eq(transactions.userId, userId),
          sql`TO_CHAR(date, 'YYYY-MM') = ${targetMonthYear}`
        )
      )
      .groupBy(sql`EXTRACT(DAY FROM date)`);

    const dailyMap = new Map<number, { expense: number; income: number }>();
    let totalExpense = 0;
    let totalIncome = 0;

    dailyTransactions.forEach((row: any) => {
      const exp = Number(row.expense);
      const inc = Number(row.income);
      dailyMap.set(row.day, { expense: exp, income: inc });
      totalExpense += exp;
      totalIncome += inc;
    });

    let cumulativeExpense = 0;
    const daysResult: any[] = [];


    for (let d = 1; d <= totalDays; d++) {
      const dayRecord = dailyMap.get(d) || { expense: 0, income: 0 };
      cumulativeExpense += dayRecord.expense;
      const idealCumulativeSpend = dailySafeLimit * d;

      daysResult.push({
        day: d,
        date: `${targetMonthYear}-${String(d).padStart(2, '0')}`,
        dailyExpense: dayRecord.expense,
        dailyExpenseFormatted: formatCurrency(dayRecord.expense),
        dailyIncome: dayRecord.income,
        dailyIncomeFormatted: formatCurrency(dayRecord.income),
        cumulativeExpense,
        cumulativeExpenseFormatted: formatCurrency(cumulativeExpense),
        idealCumulativeSpend,
        idealCumulativeSpendFormatted: formatCurrency(idealCumulativeSpend),
      });
    }

    const now = new Date();
    const today = now.getDate();
    const isCurrentMonth = targetMonthYear === currentMonthStr;
    const remainingDays = isCurrentMonth
      ? Math.max(totalDays - today + 1, 1)
      : totalDays;
    const remainingBudget = Math.max(totalBudget - totalExpense, 0);
    const remainingSafeLimit =
      totalBudget > 0 ? Math.round(remainingBudget / remainingDays) : 0;

    const dowTransactions = await this.db
      .select({
        isodow: sql<number>`EXTRACT(ISODOW FROM date)::int`,
        expense: sql<number>`COALESCE(SUM(CASE WHEN type = 'expense' THEN amount::numeric ELSE 0 END), 0)`,
      })
      .from(transactions)
      .where(
        and(
          eq(transactions.userId, userId),
          eq(transactions.type, 'expense'),
          sql`TO_CHAR(date, 'YYYY-MM') = ${targetMonthYear}`
        )
      )
      .groupBy(sql`EXTRACT(ISODOW FROM date)`);

    const dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const dowMap = new Map<number, number>();
    dowTransactions.forEach((row: any) => {
      dowMap.set(row.isodow, Number(row.expense));
    });

    let weekdayExpense = 0;
    let weekendExpense = 0;

    const peakSpendingDays = dayNames.map((name, idx) => {
      const isoDow = idx + 1; // 1 = Mon, ..., 7 = Sun
      const exp = dowMap.get(isoDow) || 0;
      if (isoDow === 6 || isoDow === 7) {
        weekendExpense += exp;
      } else {
        weekdayExpense += exp;
      }
      return {
        dayIndex: isoDow,
        dayName: name,
        totalExpense: exp,
        totalExpenseFormatted: formatCurrency(exp),
        percentage: totalExpense > 0 ? Math.round((exp / totalExpense) * 100) : 0,
      };
    });

    const weekendPercentage =
      totalExpense > 0 ? Math.round((weekendExpense / totalExpense) * 100) : 0;
    const weekdayPercentage =
      totalExpense > 0 ? Math.round((weekdayExpense / totalExpense) * 100) : 0;

    let insightMessage = 'Pengeluaran terdistribusi merata sepanjang minggu.';
    if (totalExpense > 0) {
      if (weekendPercentage > 45) {
        insightMessage = `Pengeluaran kamu cenderung melonjak tinggi di akhir pekan (${weekendPercentage}%).`;
      } else if (weekdayPercentage > 75) {
        insightMessage = `Sebagian besar pengeluaran kamu terjadi pada hari kerja (${weekdayPercentage}%).`;
      }
    }

    return {
      monthYear: targetMonthYear,
      totalDays,
      totalIncome,
      totalIncomeFormatted: formatCurrency(totalIncome),
      totalExpense,
      totalExpenseFormatted: formatCurrency(totalExpense),
      totalBudget,
      totalBudgetFormatted: formatCurrency(totalBudget),
      dailySafeLimit,
      dailySafeLimitFormatted: formatCurrency(dailySafeLimit),
      remainingDays,
      remainingSafeLimit,
      remainingSafeLimitFormatted: formatCurrency(remainingSafeLimit),
      days: daysResult,
      peakSpendingDays,
      weekendVsWeekday: {
        weekendExpense,
        weekendExpenseFormatted: formatCurrency(weekendExpense),
        weekdayExpense,
        weekdayExpenseFormatted: formatCurrency(weekdayExpense),
        weekendPercentage,
        weekdayPercentage,
        insight: insightMessage,
      },
    };
  }
}

