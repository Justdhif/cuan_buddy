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

        // If not connected, check if it's an OTP connection attempt (6 digits)
        if (!userId) {
          if (/^\d{6}$/.test(textBody)) {
            await this.connectAccountViaOtp(fromNumber, textBody);
          } else {
            await this.sendTextMessage(
              fromNumber,
              `👋 Selamat datang di *CuanBuddy WA Bot*!\n\nNomor Anda (*${fromNumber}*) belum terhubung ke akun CuanBuddy.\n\n📌 *Cara Menghubungkan Akun:*\n1. Buka aplikasi/web CuanBuddy.\n2. Buka menu Pengaturan Profil / Connect WA.\n3. Dapatkan 6-digit Kode OTP.\n4. Kirim 6-digit kode OTP tersebut ke chat WhatsApp ini.\n\n*Contoh kirim:* 123456`,
            );
          }
          return;
        }

        // User connected — process commands/transactions
        if (textBody.toLowerCase() === 'help' || textBody.toLowerCase() === 'bantuan') {
          await this.sendTextMessage(
            fromNumber,
            `💡 *Panduan CuanBuddy WA Bot*\n\n1. *Catat Transaksi Teks:*\n   Ketik kalimat santai, contoh:\n   • _Beli kopi 25rb_\n   • _Gaji bulanan 5jt_\n   • _Bayar listrik 150000_\n\n2. *Catat Transaksi Voice Note:*\n   Kirim pesan suara berisi pengeluaran/pemasukan!\n\n3. Ketik *bantuan* untuk melihat panduan ini lagi.`,
          );
        } else {
          await this.processTextTransaction(userId, fromNumber, textBody);
        }
      }

      // 3. Handle Voice Note messages
      else if (msgType === 'audio') {
        if (!userId) {
          await this.sendTextMessage(
            fromNumber,
            `👋 Nomor Anda belum terhubung ke CuanBuddy. Kirim kode OTP 6 digit untuk menghubungkan akun.`,
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
   * Process Natural Text Transaction via AI
   */
  private async processTextTransaction(userId: string, fromNumber: string, text: string): Promise<void> {
    try {
      // 1. Get user's base wallet
      const [baseWallet] = await this.db
        .select()
        .from(wallets)
        .where(and(eq(wallets.userId, userId), eq(wallets.isBaseCurrency, true)));

      const targetWallet = baseWallet || (await this.db.query.wallets.findFirst({ where: eq(wallets.userId, userId) }));

      if (!targetWallet) {
        await this.sendTextMessage(
          fromNumber,
          `⚠️ Anda belum memiliki Dompet/Wallet di CuanBuddy. Silakan buat dompet terlebih dahulu di aplikasi.`,
        );
        return;
      }

      // 2. Fetch categories for AI matching
      const cats = await this.db.select().from(categories).where(eq(categories.userId, userId));
      const categoryList = cats.map((c: any) => c.name).join(', ');

      // 3. Prompt AI for extraction
      const prompt = `You are an AI financial assistant parsing a WhatsApp message from a user trying to record a transaction.
Extract transaction info from this text: "${text}"

Available Categories: [${categoryList}]
Default Currency: "${targetWallet.currency || 'IDR'}"

Instructions:
1. amount: Number value (e.g., "25rb" or "25k" -> 25000, "1.5jt" -> 1500000).
2. type: "expense" or "income".
3. category: Best matching category from the available list, or "Uncategorized".
4. title: Short title (e.g. "Makan Siang", "Beli Kopi").
5. note: Original text or extra details.

Reply ONLY in JSON:
{
  "amount": 25000,
  "type": "expense",
  "category": "Food & Drink",
  "title": "Beli Kopi",
  "note": "${text}"
}`;

      const rawAi = await this.groqService.chat([{ role: 'user', content: prompt }], 200);
      const jsonMatch = rawAi.match(/\{.*?\}/s);
      if (!jsonMatch) throw new Error('AI extraction failed');

      const parsed = JSON.parse(jsonMatch[0]);
      if (!parsed.amount || isNaN(Number(parsed.amount))) {
        await this.sendTextMessage(
          fromNumber,
          `🤔 Maaf, CuanBuddy tidak menemukan nominal transaksi dalam pesan Anda: "${text}".\n\nContoh yang benar: _Beli kopi 25rb_ atau _Gaji 5jt_`,
        );
        return;
      }

      // Find matching category ID
      const catMatch = cats.find(
        (c: any) => c.name.toLowerCase() === (parsed.category || '').toLowerCase(),
      );

      // Create transaction via TransactionsService
      const newTx = await this.transactionsService.create(userId, {
        walletId: targetWallet.id,
        categoryId: catMatch?.id || null,
        title: parsed.title || text,
        type: parsed.type === 'income' ? 'income' : 'expense',
        amount: Number(parsed.amount),
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
      this.logger.error('Failed to process text transaction:', err);
      await this.sendTextMessage(
        fromNumber,
        `⚠️ Gagal mencatat transaksi. Pastikan format pesan memuat nominal yang jelas (contoh: *Beli kopi 25rb*).`,
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
