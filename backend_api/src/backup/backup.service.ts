import { Injectable, Inject, BadRequestException } from '@nestjs/common';
import { eq, and, lte, sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { backupSettings, transactions, budgets, savingsGoals, categories, wallets } from '../database/schema';
import { NotificationsService } from '../notifications/notifications.service';
import { Response } from 'express';

@Injectable()
export class BackupService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ─────────────────────────────────────────────
  // SETTINGS
  // ─────────────────────────────────────────────
  async getSettings(userId: string) {
    let settings = await this.db.query.backupSettings.findFirst({
      where: eq(backupSettings.userId, userId),
    });

    if (!settings) {
      const [newSettings] = await this.db.insert(backupSettings).values({
        userId,
      }).returning();
      settings = newSettings;
    }

    return settings;
  }

  async updateSettings(userId: string, isEnabled?: boolean, interval?: '24h' | '7d' | '1m') {
    let settings = await this.getSettings(userId);
    
    const updateData: any = { updatedAt: new Date() };
    if (isEnabled !== undefined) updateData.isEnabled = isEnabled;
    if (interval !== undefined) updateData.interval = interval;

    if (updateData.isEnabled) {
      const currentInterval = interval || settings.interval;
      updateData.nextBackupAt = this.calculateNextBackupDate(currentInterval);
    } else if (updateData.isEnabled === false) {
      updateData.nextBackupAt = null;
    }

    const [updated] = await this.db.update(backupSettings)
      .set(updateData)
      .where(eq(backupSettings.userId, userId))
      .returning();

    return updated;
  }

  private calculateNextBackupDate(interval: '24h' | '7d' | '1m'): Date {
    const next = new Date();
    if (interval === '24h') next.setDate(next.getDate() + 1);
    else if (interval === '7d') next.setDate(next.getDate() + 7);
    else if (interval === '1m') next.setMonth(next.getMonth() + 1);
    return next;
  }

  // ─────────────────────────────────────────────
  // EXPORT (SQL Database Dump)
  // ─────────────────────────────────────────────
  async exportDatabaseSql(userId: string, res: Response) {
    // Fetch all user records
    const userCategories = await this.db.query.categories.findMany({ where: eq(categories.userId, userId) });
    const userWallets = await this.db.query.wallets.findMany({ where: eq(wallets.userId, userId) });
    const userSavingsGoals = await this.db.query.savingsGoals.findMany({ where: eq(savingsGoals.userId, userId) });
    const userBudgets = await this.db.query.budgets.findMany({ where: eq(budgets.userId, userId) });
    const userTransactions = await this.db.query.transactions.findMany({ where: eq(transactions.userId, userId) });

    let sqlDump = `-- CuanBuddy Database Backup SQL Dump\n`;
    sqlDump += `-- User: ${userId}\n`;
    sqlDump += `-- Date: ${new Date().toISOString()}\n\n`;

    const formatVal = (val: any) => {
      if (val === null || val === undefined) return 'NULL';
      if (typeof val === 'string') return `'${val.replace(/'/g, "''")}'`;
      if (val instanceof Date) return `'${val.toISOString()}'`;
      if (typeof val === 'boolean') return val ? 'TRUE' : 'FALSE';
      if (typeof val === 'object') return `'${JSON.stringify(val).replace(/'/g, "''")}'`;
      return val;
    };

    // 1. Categories
    sqlDump += `-- Table: categories\n`;
    for (const row of userCategories) {
      sqlDump += `INSERT INTO categories (id, user_id, name, emoji_icon, color_code, created_at, updated_at) VALUES (` +
        `${formatVal(row.id)}, ${formatVal(userId)}, ${formatVal(row.name)}, ${formatVal(row.emojiIcon)}, ` +
        `${formatVal(row.colorCode)}, ${formatVal(row.createdAt)}, ${formatVal(row.updatedAt)});\n`;
    }
    sqlDump += `\n`;

    // 2. Wallets
    sqlDump += `-- Table: wallets\n`;
    for (const row of userWallets) {
      sqlDump += `INSERT INTO wallets (id, user_id, name, emoji_icon, color_code, type, currency, is_base_currency, decimal_precision, balance, created_at, updated_at) VALUES (` +
        `${formatVal(row.id)}, ${formatVal(userId)}, ${formatVal(row.name)}, ${formatVal(row.emojiIcon)}, ` +
        `${formatVal(row.colorCode)}, ${formatVal(row.type)}, ${formatVal(row.currency)}, ${formatVal(row.isBaseCurrency)}, ` +
        `${formatVal(row.decimalPrecision)}, ${formatVal(row.balance)}, ${formatVal(row.createdAt)}, ${formatVal(row.updatedAt)});\n`;
    }
    sqlDump += `\n`;

    // 3. Savings Goals
    sqlDump += `-- Table: savings_goals\n`;
    for (const row of userSavingsGoals) {
      sqlDump += `INSERT INTO savings_goals (id, user_id, wallet_id, room_id, name, emoji_icon, color_code, target_amount, current_amount, target_date, status, is_pin, link, created_at, updated_at) VALUES (` +
        `${formatVal(row.id)}, ${formatVal(userId)}, ${formatVal(row.walletId)}, ${formatVal(row.roomId)}, ` +
        `${formatVal(row.name)}, ${formatVal(row.emojiIcon)}, ${formatVal(row.colorCode)}, ${formatVal(row.targetAmount)}, ` +
        `${formatVal(row.currentAmount)}, ${formatVal(row.targetDate)}, ${formatVal(row.status)}, ${formatVal(row.isPin)}, ` +
        `${formatVal(row.link)}, ${formatVal(row.createdAt)}, ${formatVal(row.updatedAt)});\n`;
    }
    sqlDump += `\n`;

    // 4. Budgets
    sqlDump += `-- Table: budgets\n`;
    for (const row of userBudgets) {
      sqlDump += `INSERT INTO budgets (id, user_id, room_id, name, emoji_icon, color_code, type, category_ids, category_id, wallet_id, limit_amount, period_count, start_day, month_year, created_at, updated_at) VALUES (` +
        `${formatVal(row.id)}, ${formatVal(userId)}, ${formatVal(row.roomId)}, ${formatVal(row.name)}, ` +
        `${formatVal(row.emojiIcon)}, ${formatVal(row.colorCode)}, ${formatVal(row.type)}, ${formatVal(row.categoryIds)}, ` +
        `${formatVal(row.categoryId)}, ${formatVal(row.walletId)}, ${formatVal(row.limitAmount)}, ${formatVal(row.periodCount)}, ` +
        `${formatVal(row.startDay)}, ${formatVal(row.monthYear)}, ${formatVal(row.createdAt)}, ${formatVal(row.updatedAt)});\n`;
    }
    sqlDump += `\n`;

    // 5. Transactions
    sqlDump += `-- Table: transactions\n`;
    for (const row of userTransactions) {
      sqlDump += `INSERT INTO transactions (id, user_id, wallet_id, room_id, title, type, amount, exchange_rate, base_amount, category_id, savings_goal_id, note, date, created_at, updated_at) VALUES (` +
        `${formatVal(row.id)}, ${formatVal(userId)}, ${formatVal(row.walletId)}, ${formatVal(row.roomId)}, ` +
        `${formatVal(row.title)}, ${formatVal(row.type)}, ${formatVal(row.amount)}, ${formatVal(row.exchangeRate)}, ` +
        `${formatVal(row.baseAmount)}, ${formatVal(row.categoryId)}, ${formatVal(row.savingsGoalId)}, ${formatVal(row.note)}, ` +
        `${formatVal(row.date)}, ${formatVal(row.createdAt)}, ${formatVal(row.updatedAt)});\n`;
    }

    const dateStr = new Date().toISOString().replaceAll(':', '-').split('.')[0];
    res.setHeader('Content-Type', 'application/sql');
    res.setHeader('Content-Disposition', `attachment; filename=cuanbuddy_backup_${dateStr}.sql`);
    res.send(sqlDump);
  }

  // ─────────────────────────────────────────────
  // IMPORT / RESTORE (SQL Execution)
  // ─────────────────────────────────────────────
  async processImport(userId: string, file: Express.Multer.File) {
    if (!file) throw new BadRequestException('No file uploaded');

    const isSql = file.originalname.endsWith('.sql');
    if (!isSql) throw new BadRequestException('Only .sql database files are allowed');

    const sqlContent = file.buffer.toString('utf-8');

    await this.db.transaction(async (tx: any) => {
      // Delete existing data in proper order to avoid constraint issues
      await tx.execute(sql.raw(`DELETE FROM transactions WHERE user_id = '${userId}';`));
      await tx.execute(sql.raw(`DELETE FROM budgets WHERE user_id = '${userId}';`));
      await tx.execute(sql.raw(`DELETE FROM savings_goals WHERE user_id = '${userId}';`));
      await tx.execute(sql.raw(`DELETE FROM wallets WHERE user_id = '${userId}';`));
      await tx.execute(sql.raw(`DELETE FROM categories WHERE user_id = '${userId}';`));

      const statements = sqlContent
        .split(/;\r?\n/)
        .map(stmt => stmt.trim())
        .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

      for (const stmt of statements) {
        await tx.execute(sql.raw(stmt + ';'));
      }
    });

    return {
      message: 'Database restored successfully',
      type: 'sql',
      fileName: file.originalname,
    };
  }

  // ─────────────────────────────────────────────
  // CRON JOB
  // ─────────────────────────────────────────────
  async processScheduledBackups() {
    const now = new Date();
    
    const dueBackups = await this.db.query.backupSettings.findMany({
      where: and(
        eq(backupSettings.isEnabled, true),
        lte(backupSettings.nextBackupAt, now)
      )
    });

    for (const setting of dueBackups) {
      void this.notificationsService.createAndBroadcast(
        setting.userId,
        'Backup Ready',
        'Your scheduled database backup (.sql) is ready to be downloaded.',
        'system'
      );

      const nextDate = this.calculateNextBackupDate(setting.interval as any);

      void this.db.update(backupSettings)
        .set({ lastBackupAt: now, nextBackupAt: nextDate, updatedAt: new Date() })
        .where(eq(backupSettings.id, setting.id));
    }

    return { processed: dueBackups.length };
  }

  async markBackupCompleted(userId: string) {
    const settings = await this.getSettings(userId);
    if (!settings.isEnabled) return settings;
    
    const now = new Date();
    const nextDate = this.calculateNextBackupDate(settings.interval as any);
    
    const [updated] = await this.db.update(backupSettings)
      .set({ lastBackupAt: now, nextBackupAt: nextDate, updatedAt: new Date() })
      .where(eq(backupSettings.userId, userId))
      .returning();
      
    return updated;
  }
}