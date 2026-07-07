import { Injectable, Inject } from '@nestjs/common';
import { eq, and, gte, sql, desc } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { transactions, categories, savingsGoals, wallets } from '../database/schema';
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
  // 1. FINANCIAL ADVISOR CHAT
  // ─────────────────────────────────────────────
  async chat(userId: string, message: string): Promise<{ reply: string }> {
    // Fetch only minimal data needed — 3 parallel SQL queries
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    const [summary, recentTxs, goals] = await Promise.all([
      // 1. Financial summary via aggregate (single query)
      this.db
        .select({
          totalIncome: sql<number>`COALESCE(SUM(CASE WHEN type='income' THEN amount::numeric ELSE 0 END),0)`,
          totalExpense: sql<number>`COALESCE(SUM(CASE WHEN type='expense' THEN amount::numeric ELSE 0 END),0)`,
        })
        .from(transactions)
        .where(and(eq(transactions.userId, userId), gte(transactions.date, threeMonthsAgo)))
        .then((r: any[]) => r[0]),

      // 2. Last 5 transactions only (LIMIT to save bandwidth)
      this.db
        .select({
          type: transactions.type,
          amount: transactions.amount,
          note: transactions.note,
          date: transactions.date,
        })
        .from(transactions)
        .where(eq(transactions.userId, userId))
        .orderBy(desc(transactions.date))
        .limit(5),

      // 3. Savings goals summary
      this.db
        .select({
          name: savingsGoals.name,
          target: savingsGoals.targetAmount,
          current: savingsGoals.currentAmount,
          status: savingsGoals.status,
        })
        .from(savingsGoals)
        .where(eq(savingsGoals.userId, userId))
        .limit(5),
    ]);

    const income = Number(summary.totalIncome);
    const expense = Number(summary.totalExpense);
    const balance = income - expense;

    // Build concise context — fewer tokens = cheaper + faster
    const context = [
      `Last 3 months summary: Income ${formatCurrency(income)}, Expenses ${formatCurrency(expense)}, Balance ${formatCurrency(balance)}.`,
      recentTxs.length
        ? `Last 5 transactions: ${recentTxs.map((t: any) => `${t.type} ${formatCurrency(t.amount)}${t.note ? ` (${t.note})` : ''}`).join('; ')}.`
        : '',
      goals.length
        ? `Savings goals: ${goals.map((g: any) => `${g.name} ${formatCurrency(g.current)}/${formatCurrency(g.target)} (${g.status})`).join(', ')}.`
        : '',
    ]
      .filter(Boolean)
      .join('\n');

    const systemPrompt = `You are CuanBuddy AI, a friendly and practical personal finance assistant.
IMPORTANT: Detect the language of the user's message and always respond in the SAME language.
If the user writes in Indonesian (Bahasa Indonesia), respond in Indonesian.
If the user writes in English, respond in English.
Answer concisely and provide concrete, actionable advice.
Maximum 3 short paragraphs. No filler words.

User financial data:
${context}`;

    const reply = await this.groqService.chat(
      [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: message },
      ],
      400, // Keep reply concise to save tokens
    );

    return { reply };
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

    const prompt = `Generate a concise personal finance report based on the following data.
Write in a friendly, informative, and positive tone.
Maximum 4 short paragraphs. Include 1–2 specific actionable tips at the end.

Monthly trend (last 3 months):
${trendText}

This month's spending by category (top 5):
${categoryText}`;

    const insights = await this.groqService.chat(
      [{ role: 'user', content: prompt }],
      500,
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
