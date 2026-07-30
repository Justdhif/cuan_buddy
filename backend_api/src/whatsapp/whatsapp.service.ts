import { Injectable, Inject, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { eq, and } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { users, userProfiles, wallets, categories } from '../database/schema';
import { TransactionsService } from '../transactions/transactions.service';
import { AiService } from '../ai/ai.service';
import { GroqService } from '../ai/groq.service';
import { formatCurrency } from '../common/utils/formatter.util';

@Injectable()
export class WhatsappService {
  private readonly logger = Logger.name ? new Logger('WhatsappService') : console;

  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly configService: ConfigService,
    private readonly transactionsService: TransactionsService,
    private readonly aiService: AiService,
    private readonly groqService: GroqService,
  ) {}

  /**
   * Main Webhook Handler for WhatsApp Cloud API
   */
  async handleWebhookPayload(payload: any): Promise<void> {
    try {
      this.logger.log(`Incoming WA Payload: ${JSON.stringify(payload)}`);

      const entry = payload?.entry?.[0];
      const changes = entry?.changes?.[0];
      const value = changes?.value;
      const message = value?.messages?.[0];

      if (!message) {
        this.logger.log(`Payload received but no messages array found (status update or echo)`);
        return;
      }

      const fromNumber = message.from; // User's WhatsApp Phone Number (E.164 without +, e.g. 628123456789)
      const msgType = message.type;

      this.logger.log(`Received WA message from ${fromNumber}, type: ${msgType}`);

      // 1. Check if phone number is connected to a CuanBuddy user
      const profile = await this.db.query.userProfiles.findFirst({
        where: eq(userProfiles.phoneNumber, fromNumber),
      });
      const userId = profile?.userId;

      // 2. Handle text messages
      if (msgType === 'text') {
        const textBody = message.text?.body?.trim();
        if (!textBody) return;

        // Check if it's an OTP connection attempt (6 digits)
        if (/^\d{6}$/.test(textBody) && !userId) {
          await this.connectAccountViaOtp(fromNumber, textBody);
          return;
        }

        if (textBody.toLowerCase() === 'help' || textBody.toLowerCase() === 'bantuan') {
          const statusConnected = userId ? '🟢 *Akun Terhubung*' : '🔴 *Akun Belum Terhubung* (Bisa konsultasi umum)';
          await this.sendTextMessage(
            fromNumber,
            `💡 *Panduan CuanBuddy WA Bot*\n\nStatus: ${statusConnected}\n\n1. *Konsultasi Perencanaan Keuangan:* (Bisa tanpa terhubung!)\n   Tanya saran alokasi gaji, cara hemat, investasi, dll.\n\n2. *Catat Transaksi / Cek Data CuanBuddy:* (Butuh Terhubung WA OTP)\n   Ketik misal: _Beli kopi 25rb_ atau _Berapa sisa uang saya?_\n\n📌 *Menghubungkan Akun:*\nKirim 6-digit kode OTP dari aplikasi CuanBuddy ke chat ini.`,
          );
        } else {
          await this.processTextTransaction(userId || null, fromNumber, textBody);
        }
      }

      // 3. Handle Voice Note messages
      else if (msgType === 'audio') {
        if (!userId) {
          await this.sendTextMessage(
            fromNumber,
            `🔒 *Fitur Pencatatan Voice Note Membutuhkan Akun CuanBuddy*\n\nNomor Anda (*${fromNumber}*) belum terhubung.\n\n📌 *Cara Menghubungkan:* Kirim 6-digit kode OTP dari aplikasi CuanBuddy ke chat WhatsApp ini.`,
          );
          return;
        }

        const audioId = message.audio?.id;
        if (audioId) {
          await this.processAudioTransaction(userId, fromNumber, audioId);
        }
      }
    } catch (error) {
      this.logger.error('Error handling WA webhook payload:', error);
    }
  }

  /**
   * Pair WhatsApp phone number with CuanBuddy user via OTP
   */
  private async connectAccountViaOtp(fromNumber: string, otp: string): Promise<void> {
    const profile = await this.db.query.userProfiles.findFirst({
      where: eq(userProfiles.waConnectOtp, otp),
    });

    if (!profile) {
      await this.sendTextMessage(
        fromNumber,
        `❌ Kode OTP (*${otp}*) tidak valid atau sudah kadaluarsa. Silakan ambil kode OTP baru di profil aplikasi CuanBuddy.`,
      );
      return;
    }

    // Connect user: save WA phone number and clear OTP
    await this.db
      .update(userProfiles)
      .set({
        phoneNumber: fromNumber,
        waConnectOtp: null,
        updatedAt: new Date(),
      })
      .where(eq(userProfiles.userId, profile.userId));

    // Get user email for confirmation message
    const user = await this.db.query.users.findFirst({ where: eq(users.id, profile.userId) });

    await this.sendTextMessage(
      fromNumber,
      `🎉 *Selamat! Akun CuanBuddy Berhasil Terhubung!*\n\nAkun WhatsApp Anda kini terhubung dengan email: *${user?.email}*.\n\nSekarang Anda bisa langsung mencatat pengeluaran/pemasukan dengan mengirim pesan teks biasa atau Voice Note di sini!\n\n_Ketik *help* untuk melihat bantuan._`,
    );
  }

  /**
   * Process Natural Text via AI: Classifies intent into "consultation" vs "transaction"
   */
  private async processTextTransaction(userId: string | null, fromNumber: string, text: string): Promise<void> {
    try {
      // 1. Get user's base wallet (if user is connected)
      let baseWallet = null;
      let targetWallet = null;
      let cats: any[] = [];

      if (userId) {
        const walletList = await this.db
          .select()
          .from(wallets)
          .where(and(eq(wallets.userId, userId), eq(wallets.isBaseCurrency, true)));
        baseWallet = walletList[0];
        targetWallet = baseWallet || (await this.db.query.wallets.findFirst({ where: eq(wallets.userId, userId) }));
        cats = targetWallet ? await this.db.select().from(categories).where(eq(categories.userId, userId)) : [];
      }

      const categoryList = cats.map((c: any) => c.name).join(', ');

      // 2. Prompt AI to detect intent & parse transaction if applicable
      const classificationPrompt = `You are CuanBuddy's AI router and financial parser.
Analyze this user WhatsApp message: "${text}"

Available Categories: [${categoryList}]
Default Currency: "${targetWallet?.currency || 'IDR'}"

Task 1: Determine intent:
- "transaction": User is recording/logging a spend or income (e.g. "Beli kopi 25rb", "Gaji 5jt", "Bayar kos 1.5jt", "dapat komisi 500k").
- "consultation": User is asking a financial question, seeking financial advice, asking about their balance/wealth, chatting, or asking for financial consultation (e.g. "gimana cara atur keuangan?", "berapa saldo saya?", "saran investasi untuk saya", "halo").

Task 2: If intent is "transaction", extract:
- amount: number
- type: "expense" or "income"
- category: matched category name or "Uncategorized"
- title: short title

Reply strictly in JSON:
{
  "intent": "transaction" | "consultation",
  "amount": 25000,
  "type": "expense",
  "category": "Food & Drink",
  "title": "Beli Kopi"
}`;

      const rawClassifier = await this.groqService.chat([{ role: 'user', content: classificationPrompt }], 300);
      const jsonMatch = rawClassifier.match(/\{.*?\}/s);

      let intent = 'consultation';
      let parsed: any = null;

      if (jsonMatch) {
        try {
          parsed = JSON.parse(jsonMatch[0]);
          if (parsed.intent === 'transaction' && parsed.amount && !isNaN(Number(parsed.amount))) {
            intent = 'transaction';
          }
        } catch (e) {
          intent = 'consultation';
        }
      }

      // --- BRANCH 1: FINANCIAL CONSULTATION ---
      if (intent === 'consultation') {
        let dbContext = 'User has not connected their CuanBuddy account yet. Provide general professional financial consultation.';
        if (userId) {
          dbContext = await this.aiService.getUserFinancialDatabaseContext(userId);
        }

        const consultantSystemPrompt = `You are a Senior Financial Consultant & Certified Financial Planner (CFP) AI for CuanBuddy responding via WhatsApp.
${userId ? "You have COMPLETE DIRECT ACCESS to the user's financial database records provided below." : "The user has not connected their CuanBuddy account yet. Provide general expert financial advice."}

### PERSONA & ROLE:
- You are a Senior Financial Consultant with deep expertise in personal finance, wealth management, cash flow analysis, budgeting, and investment strategies.
- You provide professional, highly actionable, empathetic, and data-backed financial guidance.
${userId ? "- ALWAYS analyze the user's REAL database figures (wallets, total net worth, income, expenses, category spending, budgets, savings goals, recent transactions) to give exact, customized advice." : "- Encourage user to link their CuanBuddy account using 6-digit OTP if they ask about their personal CuanBuddy balances or transaction records."}

### WHATSAPP FORMATTING RULES (STRICT):
- Format text cleanly for WhatsApp mobile screens.
- Use single asterisks *bold* for bold text (DO NOT use double asterisks **).
- Use underscores _italic_ for emphasis.
- Use clean bullet points (•) or numbered lists (1., 2., 3.).
- Keep paragraphs concise and easy to read.

### LANGUAGE MATCHING MANDATE:
- Detect the language of the user's prompt ("${text}") and respond 100% in the exact same language (Indonesian or English).

User Financial Database Context:
${dbContext}`;

        const reply = await this.groqService.chat(
          [
            { role: 'system', content: consultantSystemPrompt },
            { role: 'user', content: text },
          ],
          800,
        );

        // Sanitize any stray Markdown double asterisks for WhatsApp
        const waCleanReply = reply.replace(/\*\*(.*?)\*\*/g, '*$1*');

        await this.sendTextMessage(fromNumber, waCleanReply);
        return;
      }

      // --- BRANCH 2: RECORD TRANSACTION ---
      if (!userId) {
        await this.sendTextMessage(
          fromNumber,
          `🔒 *Fitur Pencatatan Transaksi Membutuhkan Akun CuanBuddy*\n\nNomor WhatsApp Anda (*${fromNumber}*) belum terhubung ke CuanBuddy.\n\n📌 *Cara Menghubungkan Akun:*\n1. Buka aplikasi CuanBuddy.\n2. Ambil 6-digit kode OTP di Profil.\n3. Kirim 6-digit kode OTP tersebut ke chat ini.\n\n*Contoh:* 123456`,
        );
        return;
      }

      if (!targetWallet) {
        await this.sendTextMessage(
          fromNumber,
          `⚠️ Anda belum memiliki Dompet/Wallet di CuanBuddy. Silakan buat dompet terlebih dahulu di aplikasi CuanBuddy.`,
        );
        return;
      }

      // Find matching category ID
      const catMatch = cats.find(
        (c: any) => c.name.toLowerCase() === (parsed?.category || '').toLowerCase(),
      );

      // Create transaction via TransactionsService
      const newTx = await this.transactionsService.create(userId, {
        walletId: targetWallet.id,
        categoryId: catMatch?.id || null,
        title: parsed?.title || text,
        type: parsed?.type === 'income' ? 'income' : 'expense',
        amount: Number(parsed?.amount),
        exchangeRate: 1,
        date: new Date().toISOString(),
        note: `[Via WA Bot] ${text}`,
      });

      const icon = newTx.type === 'income' ? '💰' : '💸';
      const typeLabel = newTx.type === 'income' ? 'Pemasukan' : 'Pengeluaran';

      await this.sendTextMessage(
        fromNumber,
        `✅ *Transaksi Berhasil Dicatat!* ${icon}\n\n• *Jenis:* ${typeLabel}\n• *Judul:* ${newTx.title}\n• *Nominal:* ${formatCurrency(Number(newTx.amount))}\n• *Kategori:* ${catMatch?.name || 'Uncategorized'}\n• *Dompet:* ${targetWallet.name}`,
      );
    } catch (err) {
      this.logger.error('Failed to process text message in WA bot:', err);
      await this.sendTextMessage(
        fromNumber,
        `⚠️ Maaf, terjadi kendala saat memproses pesan Anda. Silakan coba lagi beberapa saat lagi.`,
      );
    }
  }

  /**
   * Process Voice Note Transaction via Meta Media API & Groq Whisper
   */
  private async processAudioTransaction(userId: string, fromNumber: string, mediaId: string): Promise<void> {
    try {
      await this.sendTextMessage(fromNumber, `🎧 *Mendengarkan voice note Anda...*`);

      // 1. Download media from WhatsApp API
      const token = this.configService.get<string>('WA_CLOUD_API_ACCESS_TOKEN');
      if (!token) throw new Error('WA Token not configured');

      // Get Media URL
      const mediaRes = await fetch(`https://graph.facebook.com/v19.0/${mediaId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const mediaData = await mediaRes.json();
      if (!mediaData.url) throw new Error('Failed to get media URL');

      // Download Binary Audio
      const audioRes = await fetch(mediaData.url, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const arrayBuffer = await audioRes.arrayBuffer();
      const audioBuffer = Buffer.from(arrayBuffer);

      // 2. Transcribe & Parse with AiService voice processor
      const voiceResult = await this.aiService.processVoiceTransaction(userId, audioBuffer, 'voice_note.ogg');

      // 3. Find base wallet
      const [baseWallet] = await this.db
        .select()
        .from(wallets)
        .where(and(eq(wallets.userId, userId), eq(wallets.isBaseCurrency, true)));

      const targetWallet = baseWallet || (await this.db.query.wallets.findFirst({ where: eq(wallets.userId, userId) }));

      // 4. Save transaction
      const ext = voiceResult.extracted;
      const newTx = await this.transactionsService.create(userId, {
        walletId: targetWallet.id,
        categoryId: ext.categoryId || null,
        title: ext.title || 'Voice Transaction',
        type: ext.type === 'income' ? 'income' : 'expense',
        amount: Number(ext.amount),
        exchangeRate: 1,
        date: new Date().toISOString(),
        note: `[Via WA Voice] "${voiceResult.transcription}"`,
      });

      const icon = newTx.type === 'income' ? '💰' : '💸';
      const typeLabel = newTx.type === 'income' ? 'Pemasukan' : 'Pengeluaran';

      await this.sendTextMessage(
        fromNumber,
        `✅ *Transaksi Voice Note Dicatat!* ${icon}\n\n🗣️ _"${voiceResult.transcription}"_\n\n• *Jenis:* ${typeLabel}\n• *Judul:* ${newTx.title}\n• *Nominal:* ${formatCurrency(Number(newTx.amount))}\n• *Dompet:* ${targetWallet.name}`,
      );
    } catch (err) {
      this.logger.error('Failed to process audio transaction:', err);
      await this.sendTextMessage(
        fromNumber,
        `⚠️ Gagal memproses voice note. Pastikan suara terdengar jelas dan menyebutkan nominal angka.`,
      );
    }
  }

  /**
   * Send HTTP POST Request to WhatsApp Cloud API
   */
  async sendTextMessage(toPhone: string, messageText: string): Promise<void> {
    const phoneNumberId = this.configService.get<string>('WA_PHONE_NUMBER_ID');
    const accessToken = this.configService.get<string>('WA_CLOUD_API_ACCESS_TOKEN');

    if (!phoneNumberId || !accessToken) {
      this.logger.warn('WhatsApp Cloud API Credentials not configured in .env');
      return;
    }

    try {
      const url = `https://graph.facebook.com/v19.0/${phoneNumberId}/messages`;
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: toPhone,
          type: 'text',
          text: { preview_url: false, body: messageText },
        }),
      });

      if (!response.ok) {
        const errJson = await response.json();
        this.logger.error('Error sending WA message:', JSON.stringify(errJson));
      }
    } catch (error) {
      this.logger.error('Failed to send WA message via Graph API:', error);
    }
  }

  /**
   * Generate 6-digit connection OTP for user in mobile/web app
   */
  async generateConnectOtp(userId: string): Promise<{ otp: string }> {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    await this.db
      .update(userProfiles)
      .set({ waConnectOtp: otp, updatedAt: new Date() })
      .where(eq(userProfiles.userId, userId));
    return { otp };
  }
}
