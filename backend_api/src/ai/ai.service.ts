import { Injectable, Inject, BadRequestException, NotFoundException } from '@nestjs/common';
import { eq, and, gte, sql, desc, asc } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { transactions, categories, savingsGoals, wallets, userProfiles, budgets, aiConversations, aiMessages } from '../database/schema';
import { GroqService } from './groq.service';
import { NotificationsService } from '../notifications/notifications.service';
import { formatCurrency } from '../common/utils/formatter.util';

@Injectable()
export class AiService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly groqService: GroqService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ─────────────────────────────────────────────
  // MULTI-CONVERSATION MANAGEMENT (MAX 10)
  // ─────────────────────────────────────────────
  async getConversations(userId: string) {
    const list = await this.db
      .select({
        id: aiConversations.id,
        title: aiConversations.title,
        createdAt: aiConversations.createdAt,
        updatedAt: aiConversations.updatedAt,
      })
      .from(aiConversations)
      .where(eq(aiConversations.userId, userId))
      .orderBy(desc(aiConversations.updatedAt));

    return {
      conversations: list,
      count: list.length,
      maxLimit: 10,
    };
  }

  async createConversation(userId: string, initialTitle?: string) {
    const existing = await this.db
      .select({ id: aiConversations.id })
      .from(aiConversations)
      .where(eq(aiConversations.userId, userId));

    if (existing.length >= 10) {
      throw new BadRequestException(
        'Batas maksimal 10 percakapan AI telah tercapai. Silakan hapus salah satu percakapan untuk membuat yang baru.',
      );
    }

    const title = initialTitle || `Percakapan ${existing.length + 1}`;
    const [newConv] = await this.db
      .insert(aiConversations)
      .values({
        userId,
        title,
      })
      .returning();

    return newConv;
  }

  async getConversationMessages(userId: string, conversationId: string) {
    const [conv] = await this.db
      .select({ id: aiConversations.id, title: aiConversations.title })
      .from(aiConversations)
      .where(and(eq(aiConversations.id, conversationId), eq(aiConversations.userId, userId)));

    if (!conv) {
      throw new NotFoundException('Percakapan tidak ditemukan.');
    }

    const messagesList = await this.db
      .select({
        id: aiMessages.id,
        role: aiMessages.role,
        content: aiMessages.content,
        createdAt: aiMessages.createdAt,
      })
      .from(aiMessages)
      .where(eq(aiMessages.conversationId, conversationId))
      .orderBy(asc(aiMessages.createdAt));

    return {
      conversation: conv,
      messages: messagesList,
    };
  }

  async updateConversationTitle(userId: string, conversationId: string, title: string) {
    const [updated] = await this.db
      .update(aiConversations)
      .set({ title, updatedAt: new Date() })
      .where(and(eq(aiConversations.id, conversationId), eq(aiConversations.userId, userId)))
      .returning();

    if (!updated) {
      throw new NotFoundException('Percakapan tidak ditemukan.');
    }

    return updated;
  }

  async deleteConversation(userId: string, conversationId: string) {
    const [deleted] = await this.db
      .delete(aiConversations)
      .where(and(eq(aiConversations.id, conversationId), eq(aiConversations.userId, userId)))
      .returning();

    if (!deleted) {
      throw new NotFoundException('Percakapan tidak ditemukan.');
    }

    return { message: 'Percakapan berhasil dihapus.' };
  }

  async chat(userId: string, message: string, conversationId?: string): Promise<{ conversationId: string; reply: string }> {
    let targetConvId = conversationId;

    if (targetConvId) {
      const [conv] = await this.db
        .select({ id: aiConversations.id })
        .from(aiConversations)
        .where(and(eq(aiConversations.id, targetConvId), eq(aiConversations.userId, userId)));

      if (!conv) {
        throw new NotFoundException('Percakapan tidak ditemukan.');
      }
    } else {
      const existing = await this.db
        .select({ id: aiConversations.id })
        .from(aiConversations)
        .where(eq(aiConversations.userId, userId));

      if (existing.length >= 10) {
        throw new BadRequestException(
          'Batas maksimal 10 percakapan AI telah tercapai. Silakan hapus salah satu percakapan untuk membuat yang baru.',
        );
      }

      const generatedTitle = message.length > 30 ? message.substring(0, 30) + '...' : message;
      const [newConv] = await this.db
        .insert(aiConversations)
        .values({
          userId,
          title: generatedTitle,
        })
        .returning();

      targetConvId = newConv.id;
    }

    // Fetch history (last 10 messages)
    const history = await this.db
      .select({ role: aiMessages.role, content: aiMessages.content })
      .from(aiMessages)
      .where(eq(aiMessages.conversationId, targetConvId!))
      .orderBy(desc(aiMessages.createdAt))
      .limit(10);

    const chronologicalHistory = history.reverse();

    // Save user message to database
    await this.db.insert(aiMessages).values({
      conversationId: targetConvId!,
      role: 'user',
      content: message,
    });

    const databaseContext = await this.getUserFinancialDatabaseContext(userId);

    const systemPrompt = `You are a Senior Financial Consultant & Certified Financial Planner (CFP) AI for CuanBuddy.
You have COMPLETE DIRECT ACCESS to the user's financial database records provided below.

### PERSONA & ROLE:
- You are a Senior Financial Consultant with deep expertise in personal finance, wealth management, cash flow analysis, budgeting, and investment strategies.
- You provide professional, highly actionable, empathetic, and data-backed financial guidance.
- ALWAYS analyze the user's REAL database figures (wallets, total net worth, income, expenses, category spending, budgets, savings goals, recent transactions) to give exact, customized advice.

### LANGUAGE MATCHING MANDATE (CRITICAL - MUST FOLLOW STRICTLY):
- You MUST automatically detect the language of the user's prompt ("${message}").
- IF THE USER PROMPT IS IN ENGLISH: You MUST reply 100% in English.
- IF THE USER PROMPT IS IN INDONESIAN (Bahasa Indonesia): You MUST reply 100% in Bahasa Indonesia.
- ALWAYS respond strictly in the SAME language as the user's prompt. Do NOT switch or mix languages.

### FINANCIAL CONSULTING STANDARDS:
- Reference specific numbers from their database records when answering.
- Utilize recognized financial benchmarks such as the 50/30/20 budgeting rule (50% Needs, 30% Wants, 20% Savings/Investment), Emergency Fund recommendations (3-6x monthly expenses), and debt reduction strategies where relevant.
- Structure your response cleanly with bullet points, bold key figures, and concise actionable steps.

User Financial Database Context:
${databaseContext}`;

    const llmPayload: Array<{ role: 'system' | 'user' | 'assistant'; content: string }> = [
      { role: 'system', content: systemPrompt },
      ...chronologicalHistory.map((m: any) => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      })),
      { role: 'user', content: message },
    ];

    const reply = await this.groqService.chat(llmPayload, 800);

    // Save assistant reply to database
    await this.db.insert(aiMessages).values({
      conversationId: targetConvId!,
      role: 'assistant',
      content: reply,
    });

    // Update conversation updatedAt
    await this.db
      .update(aiConversations)
      .set({ updatedAt: new Date() })
      .where(eq(aiConversations.id, targetConvId!));

    return { conversationId: targetConvId!, reply };
  }

  /**
   * Fetches comprehensive user financial database context across all tables.
   */
  private async getUserFinancialDatabaseContext(userId: string): Promise<string> {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    try {
      const [
        profileResult,
        userWallets,
        monthlySummary,
        topCategories,
        userBudgets,
        userGoals,
        recentTxs,
      ] = await Promise.all([
        // 1. Profile
        this.db
          .select({
            fullName: userProfiles.fullName,
            username: userProfiles.username,
            streak: userProfiles.recordingStreakCount,
          })
          .from(userProfiles)
          .where(eq(userProfiles.userId, userId))
          .then((r: any[]) => r[0]),

        // 2. Wallets
        this.db
          .select({
            name: wallets.name,
            type: wallets.type,
            currency: wallets.currency,
            balance: wallets.balance,
            isBaseCurrency: wallets.isBaseCurrency,
          })
          .from(wallets)
          .where(eq(wallets.userId, userId)),

        // 3. Monthly Cash Flow Summary (Current Month)
        this.db
          .select({
            income: sql<number>`COALESCE(SUM(CASE WHEN type='income' THEN amount::numeric ELSE 0 END),0)`,
            expense: sql<number>`COALESCE(SUM(CASE WHEN type='expense' THEN amount::numeric ELSE 0 END),0)`,
          })
          .from(transactions)
          .where(and(eq(transactions.userId, userId), gte(transactions.date, startOfMonth)))
          .then((r: any[]) => r[0]),

        // 4. Expense by Category (Current Month)
        this.db
          .select({
            categoryName: sql<string>`COALESCE(c.name, 'Uncategorized')`,
            total: sql<number>`SUM(t.amount::numeric)`,
          })
          .from(sql`${transactions} t`)
          .leftJoin(sql`categories c ON c.id = t.category_id`)
          .where(sql`t.user_id = ${userId} AND t.type = 'expense' AND t.date >= ${startOfMonth}`)
          .groupBy(sql`COALESCE(c.name, 'Uncategorized')`)
          .orderBy(sql`SUM(t.amount::numeric) DESC`)
          .limit(8),

        // 5. Budgets
        this.db
          .select({
            name: budgets.name,
            limitAmount: budgets.limitAmount,
            monthYear: budgets.monthYear,
            categoryName: categories.name,
          })
          .from(budgets)
          .leftJoin(categories, eq(budgets.categoryId, categories.id))
          .where(eq(budgets.userId, userId)),

        // 6. Savings Goals
        this.db
          .select({
            name: savingsGoals.name,
            target: savingsGoals.targetAmount,
            current: savingsGoals.currentAmount,
            targetDate: savingsGoals.targetDate,
            status: savingsGoals.status,
          })
          .from(savingsGoals)
          .where(eq(savingsGoals.userId, userId)),

        // 7. Recent Transactions (Last 15)
        this.db
          .select({
            title: transactions.title,
            type: transactions.type,
            amount: transactions.amount,
            date: transactions.date,
            note: transactions.note,
            categoryName: sql<string>`COALESCE(c.name, 'Uncategorized')`,
            walletName: sql<string>`COALESCE(w.name, 'Wallet')`,
          })
          .from(sql`${transactions} t`)
          .leftJoin(sql`categories c ON c.id = t.category_id`)
          .leftJoin(sql`wallets w ON w.id = t.wallet_id`)
          .where(sql`t.user_id = ${userId}`)
          .orderBy(desc(transactions.date))
          .limit(15),
      ]);

      let totalNetWorth = 0;
      const walletLines = (userWallets || []).map((w: any) => {
        const bal = Number(w.balance);
        totalNetWorth += bal;
        return `- ${w.name} (${w.type.toUpperCase()}, ${w.currency}): ${formatCurrency(bal)}`;
      });

      const income = Number(monthlySummary?.income ?? 0);
      const expense = Number(monthlySummary?.expense ?? 0);
      const netCashFlow = income - expense;
      const savingsRate = income > 0 ? ((netCashFlow / income) * 100).toFixed(1) : '0';

      const categoryLines = (topCategories || []).map((c: any) => {
        const total = Number(c.total);
        const pct = expense > 0 ? ((total / expense) * 100).toFixed(1) : '0';
        return `- ${c.categoryName}: ${formatCurrency(total)} (${pct}% of monthly expenses)`;
      });

      const budgetLines = (userBudgets || []).map((b: any) => {
        const limit = Number(b.limitAmount);
        const label = b.name || b.categoryName || 'General Budget';
        return `- ${label}: Limit ${formatCurrency(limit)} (${b.monthYear})`;
      });

      const goalLines = (userGoals || []).map((g: any) => {
        const current = Number(g.current);
        const target = Number(g.target);
        const pct = target > 0 ? ((current / target) * 100).toFixed(1) : '0';
        const targetDateStr = g.targetDate ? new Date(g.targetDate).toISOString().split('T')[0] : 'No deadline';
        return `- ${g.name}: ${formatCurrency(current)} / ${formatCurrency(target)} (${pct}%, target date: ${targetDateStr}, status: ${g.status})`;
      });

      const recentTxLines = (recentTxs || []).map((t: any) => {
        const dateStr = t.date ? new Date(t.date).toISOString().split('T')[0] : '';
        const title = t.title || t.note || 'Untitled';
        return `- [${dateStr}] [${t.type.toUpperCase()}] ${title}: ${formatCurrency(Number(t.amount))} (Cat: ${t.categoryName}, Wallet: ${t.walletName})`;
      });

      const userName = profileResult?.fullName || profileResult?.username || 'Valued User';

      return `
=== USER DATABASE FINANCIAL PROFILE ===
User Name: ${userName}
Streak Count: ${profileResult?.streak ?? 0} days

1. WALLETS & TOTAL NET WORTH:
- Total Net Worth: ${formatCurrency(totalNetWorth)}
${walletLines.length ? walletLines.join('\n') : '- No wallets recorded.'}

2. MONTHLY CASH FLOW SUMMARY (Current Month):
- Total Income: ${formatCurrency(income)}
- Total Expenses: ${formatCurrency(expense)}
- Net Cash Flow: ${formatCurrency(netCashFlow)}
- Savings Rate: ${savingsRate}%

3. EXPENSES BY CATEGORY (Current Month):
${categoryLines.length ? categoryLines.join('\n') : '- No expense records this month.'}

4. BUDGETS:
${budgetLines.length ? budgetLines.join('\n') : '- No active budgets set.'}

5. SAVINGS GOALS:
${goalLines.length ? goalLines.join('\n') : '- No active savings goals set.'}

6. RECENT TRANSACTIONS (Last 15):
${recentTxLines.length ? recentTxLines.join('\n') : '- No recent transactions found.'}
======================================`;
    } catch (error) {
      return `Error fetching database context: ${error?.message || error}`;
    }
  }

  // ─────────────────────────────────────────────
  // 2. SPENDING INSIGHTS
  // ─────────────────────────────────────────────
  async getInsights(userId: string): Promise<{ insights: string }> {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(now.getMonth() - 3);

    // 2 aggregate queries — no raw rows fetched
    const [monthlyTrend, categorySpend] = await Promise.all([
      this.db
        .select({
          month: sql<string>`TO_CHAR(date, 'YYYY-MM')`,
          income: sql<number>`COALESCE(SUM(CASE WHEN type='income' THEN amount::numeric ELSE 0 END),0)`,
          expense: sql<number>`COALESCE(SUM(CASE WHEN type='expense' THEN amount::numeric ELSE 0 END),0)`,
        })
        .from(transactions)
        .where(and(eq(transactions.userId, userId), gte(transactions.date, threeMonthsAgo)))
        .groupBy(sql`TO_CHAR(date, 'YYYY-MM')`)
        .orderBy(sql`TO_CHAR(date, 'YYYY-MM') ASC`),

      this.db
        .select({
          categoryName: sql<string>`COALESCE(c.name, 'Uncategorized')`,
          total: sql<number>`SUM(t.amount::numeric)`,
        })
        .from(sql`${transactions} t`)
        .leftJoin(sql`categories c ON c.id = t.category_id`)
        .where(sql`t.user_id = ${userId} AND t.type = 'expense' AND t.date >= ${startOfMonth}`)
        .groupBy(sql`COALESCE(c.name, 'Uncategorized')`)
        .orderBy(sql`SUM(t.amount::numeric) DESC`)
        .limit(5),
    ]);

    const trendText = monthlyTrend
      .map((r: any) => `${r.month}: Income ${formatCurrency(r.income)}, Expenses ${formatCurrency(r.expense)}`)
      .join('\n');

    const categoryText = categorySpend
      .map((r: any) => `${r.categoryName}: ${formatCurrency(r.total)}`)
      .join(', ');

    const prompt = `Generate a VERY SHORT, CONCISE AI financial insight (1 to 2 sentences MAX, under 25 words).
Be direct, encouraging, and practical.
Do NOT write paragraphs, intros, or long essays. Write in the user's primary language.

Monthly trend (last 3 months):
${trendText}

This month's spending by category (top 5):
${categoryText}`;

    const insights = await this.groqService.chat(
      [{ role: 'user', content: prompt }],
      80,
    );

    return { insights };
  }

  // ─────────────────────────────────────────────
  // 3. AUTO-CATEGORIZE TRANSACTION
  // ─────────────────────────────────────────────
  async categorize(note: string): Promise<{ categoryName: string; confidence: string }> {
    // Fetch only id + name — minimal data
    const cats = await this.db
      .select({ id: categories.id, name: categories.name })
      .from(categories);

    if (!cats.length) {
      return { categoryName: 'Uncategorized', confidence: 'low' };
    }

    const categoryList = cats.map((c: any) => c.name).join(', ');

    const prompt = `You are a financial transaction categorization system.
Choose ONE category that best matches the transaction note below.
Reply ONLY with valid JSON: {"category": "CategoryName", "confidence": "high|medium|low"}
Do not add any explanation.

Available categories: ${categoryList}
Transaction note: "${note}"`;

    const raw = await this.groqService.chat(
      [{ role: 'user', content: prompt }],
      80, // Very short — just JSON output
    );

    try {
      const jsonMatch = raw.match(/\{.*?\}/s);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        return {
          categoryName: parsed.category ?? 'Uncategorized',
          confidence: parsed.confidence ?? 'low',
        };
      }
    } catch {
      // Fallback silently
    }

    return { categoryName: 'Uncategorized', confidence: 'low' };
  }

  // ─────────────────────────────────────────────
  // 4. BUDGET RECOMMENDATION
  // ─────────────────────────────────────────────
  async getBudgetRecommendation(userId: string): Promise<{ recommendations: any[] }> {
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    // Single SQL query — avg per category over last 3 months
    const avgByCategory = await this.db
      .select({
        categoryId: sql<string>`t.category_id`,
        categoryName: sql<string>`COALESCE(c.name, 'Uncategorized')`,
        avgMonthly: sql<number>`ROUND(SUM(t.amount::numeric) / 3, 0)`,
        totalSpent: sql<number>`SUM(t.amount::numeric)`,
      })
      .from(sql`${transactions} t`)
      .leftJoin(sql`categories c ON c.id = t.category_id`)
      .where(sql`t.user_id = ${userId} AND t.type = 'expense' AND t.date >= ${threeMonthsAgo}`)
      .groupBy(sql`t.category_id, COALESCE(c.name, 'Uncategorized')`)
      .orderBy(sql`SUM(t.amount::numeric) DESC`)
      .limit(8); // Top 8 categories only

    if (!avgByCategory.length) {
      return { recommendations: [] };
    }

    const spendingData = avgByCategory
      .map((r: any) => `${r.categoryName}: avg ${formatCurrency(r.avgMonthly)}/month`)
      .join('\n');

    const prompt = `You are a financial advisor. Based on the average monthly spending data below,
recommend a realistic budget limit for next month per category.
Reply ONLY with a valid JSON array, no extra explanation:
[{"category": "name", "recommendedLimit": 123456, "reasoning": "brief reason max 10 words"}]

Spending data (last 3 months average):
${spendingData}`;

    const raw = await this.groqService.chat(
      [{ role: 'user', content: prompt }],
      600,
    );

    try {
      const jsonMatch = raw.match(/\[.*?\]/s);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        // Merge AI output with categoryId from DB
        const merged = parsed.map((item: any) => {
          const match = avgByCategory.find(
            (r: any) => r.categoryName.toLowerCase() === item.category?.toLowerCase(),
          );
          return {
            categoryId: match?.categoryId ?? null,
            categoryName: item.category,
            avgSpent3Months: match ? Number(match.avgMonthly) : 0,
            recommendedLimit: Number(item.recommendedLimit),
            reasoning: item.reasoning,
          };
        });
        return { recommendations: merged };
      }
    } catch {
      // Fallback silently
    }

    return { recommendations: [] };
  }

  // ─────────────────────────────────────────────
  // 5. ANOMALY DETECTION (fire-and-forget, no AI call)
  // Pure SQL math — no Groq needed, saves tokens entirely
  // ─────────────────────────────────────────────
  async detectAnomaly(
    userId: string,
    transactionId: string,
    categoryId: string | null,
    amount: number,
    type: string,
  ): Promise<void> {
    // Only check expense transactions with a category
    if (type !== 'expense' || !categoryId) return;

    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    // Single AVG query — no Groq call, pure math
    const [result] = await this.db
      .select({
        avgAmount: sql<number>`COALESCE(AVG(amount::numeric), 0)`,
        txCount: sql<number>`COUNT(*)`,
      })
      .from(transactions)
      .where(
        and(
          eq(transactions.userId, userId),
          eq(transactions.categoryId, categoryId),
          eq(transactions.type, 'expense'),
          gte(transactions.date, threeMonthsAgo),
        ),
      );

    const avg = Number(result?.avgAmount ?? 0);
    const count = Number(result?.txCount ?? 0);

    // Need at least 3 historical transactions to reliably detect anomaly
    if (count < 3 || avg === 0) return;

    const ratio = amount / avg;

    // Threshold: 2.5x above average = anomaly
    if (ratio >= 2.5) {
      void this.notificationsService.createAndBroadcast(
        userId,
        '⚠️ Unusual Spending Detected',
        `Your latest transaction (${formatCurrency(amount)}) is ${ratio.toFixed(1)}x higher than your average spending in this category (${formatCurrency(avg)}). Please verify this was intentional.`,
        'anomaly',
      );
    }
  }

  // ─────────────────────────────────────────────
  // 6. VOICE TRANSACTION PROCESSING
  // ─────────────────────────────────────────────
  async processVoiceTransaction(userId: string, audioBuffer: Buffer, originalName: string): Promise<any> {
    // 1. Transcribe audio to text using Whisper
    const text = await this.groqService.transcribeAudio(audioBuffer, originalName);

    if (!text || text.trim().length === 0) {
      throw new Error('Suara tidak terdengar jelas atau kosong.');
    }

    // 2. Fetch categories for precise matching
    const cats = await this.db
      .select({ id: categories.id, name: categories.name })
      .from(categories);

    // Fetch default currency from wallets
    const [baseWallet] = await this.db
      .select({ currency: wallets.currency })
      .from(wallets)
      .where(and(eq(wallets.userId, userId), eq(wallets.isBaseCurrency, true)));
    const defaultCurrency = baseWallet?.currency ?? 'IDR';

    const categoryList = cats.map((c: any) => c.name).join(', ');

    const prompt = `You are an AI that extracts transaction details from a transcribed voice message.
Extract the following information:
1. amount: The total money spent or received (as a pure number, no currency symbols).
2. currency: The currency mentioned in the voice (e.g. "USD", "IDR"). If the user says "ribu", "rupiah", "perak" it means IDR. If they say "dollar" it usually means USD. If no currency is mentioned, use the user's default currency: "${defaultCurrency}".
3. category: The best matching category from this list: [${categoryList}]. If none matches perfectly, pick the closest or "Uncategorized".
4. type: Either "income" or "expense".
5. title: A short title for the transaction (e.g. "Makan Siang" or "Gaji").
6. note: Any additional description/note if specified, otherwise an empty string.

Voice Transcription: "${text}"

Reply ONLY with valid JSON:
{
  "amount": 25000,
  "currency": "IDR",
  "category": "Food & Drink",
  "type": "expense",
  "title": "Makan siang",
  "note": "di warteg"
}
Do not add any explanations or markdown formatting.`;

    const raw = await this.groqService.chat(
      [{ role: 'user', content: prompt }],
      200,
    );

    let parsed: any;
    try {
      const jsonMatch = raw.match(/\{.*?\}/s);
      if (jsonMatch) {
        parsed = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('Failed to parse AI response');
      }
    } catch {
      throw new Error('Gagal mengekstrak data dari suara.');
    }

    // Find category ID (similar/exact match)
    const normalizedParsedName = parsed.category?.trim().toLowerCase();
    const catMatch = cats.find((c: any) =>
      c.name.trim().toLowerCase() === normalizedParsedName ||
      c.name.trim().toLowerCase().includes(normalizedParsedName) ||
      (normalizedParsedName && normalizedParsedName.includes(c.name.trim().toLowerCase()))
    );

    let categoryId = catMatch ? catMatch.id : null;

    if (!categoryId && parsed.category && parsed.category.toLowerCase() !== 'uncategorized') {
      const [newCat] = await this.db
        .insert(categories)
        .values({
          userId,
          name: parsed.category,
          emojiIcon: parsed.type === 'income' ? '💰' : '💸',
          colorCode: '#6C63FF',
        })
        .returning({ id: categories.id });
      categoryId = newCat.id;
    }

    return {
      transcription: text,
      extracted: {
        ...parsed,
        categoryId,
      },
    };
  }

  // ─────────────────────────────────────────────
  // 7. RECEIPT SCAN TRANSACTION PROCESSING
  // ─────────────────────────────────────────────
  async processReceiptTransaction(userId: string, imageBuffer: Buffer, mimeType: string): Promise<any> {
    // 1. Fetch categories for precise matching
    const cats = await this.db
      .select({ id: categories.id, name: categories.name })
      .from(categories);

    // Fetch default currency from wallets
    const [baseWallet] = await this.db
      .select({ currency: wallets.currency })
      .from(wallets)
      .where(and(eq(wallets.userId, userId), eq(wallets.isBaseCurrency, true)));
    const defaultCurrency = baseWallet?.currency ?? 'IDR';

    const categoryList = cats.map((c: any) => c.name).join(', ');

    const prompt = `You are an AI that extracts transaction details from a receipt image.
Extract the following information:
1. amount: The total amount paid (as a pure number, no currency symbols). Look for "Total", "Amount Due", or the largest number at the bottom.
2. currency: The currency on the receipt (e.g. "USD", "IDR", "Rp"). If no currency is visible, use the user's default currency: "${defaultCurrency}".
3. category: The best matching category from this list based on the items purchased or the merchant: [${categoryList}]. If none matches perfectly, pick the closest or "Uncategorized".
4. type: Receipts are generally "expense", unless it's a refund or deposit slip, then "income".
5. title: A short title for the transaction, usually the merchant or store name (e.g. "Indomaret", "Starbucks").
6. note: Any additional description based on the items on the receipt (e.g. "Groceries", "Coffee"), otherwise an empty string.

Reply ONLY with valid JSON:
{
  "amount": 25000,
  "currency": "IDR",
  "category": "Food & Drink",
  "type": "expense",
  "title": "Makan siang",
  "note": "di warteg"
}
Do not add any explanations or markdown formatting.`;

    const raw = await this.groqService.processImage(imageBuffer, mimeType, prompt);

    let parsed: any;
    try {
      const jsonMatch = raw.match(/\{.*?\}/s);
      if (jsonMatch) {
        parsed = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('Failed to parse AI response');
      }
    } catch {
      throw new Error('Gagal mengekstrak data dari struk.');
    }

    // Find category ID (similar/exact match)
    const normalizedParsedName = parsed.category?.trim().toLowerCase();
    const catMatch = cats.find((c: any) =>
      c.name.trim().toLowerCase() === normalizedParsedName ||
      c.name.trim().toLowerCase().includes(normalizedParsedName) ||
      (normalizedParsedName && normalizedParsedName.includes(c.name.trim().toLowerCase()))
    );

    let categoryId = catMatch ? catMatch.id : null;

    if (!categoryId && parsed.category && parsed.category.toLowerCase() !== 'uncategorized') {
      const [newCat] = await this.db
        .insert(categories)
        .values({
          userId,
          name: parsed.category,
          emojiIcon: parsed.type === 'income' ? '💰' : '💸',
          colorCode: '#6C63FF',
        })
        .returning({ id: categories.id });
      categoryId = newCat.id;
    }

    return {
      transcription: `Scanned receipt from ${parsed.title || 'store'}`,
      extracted: {
        ...parsed,
        categoryId,
      },
    };
  }
}
