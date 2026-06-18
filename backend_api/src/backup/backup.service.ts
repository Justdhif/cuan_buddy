import { Injectable, Inject, NotFoundException, BadRequestException, StreamableFile } from '@nestjs/common';
import { eq, and, lte } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { users, backupSettings, transactions, budgets, savingsGoals, categories } from '../database/schema';
import { NotificationsService } from '../notifications/notifications.service';
import * as ExcelJS from 'exceljs';
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

    // Calculate nextBackupAt if enabling
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
  // EXPORT (Highly Optimized Streaming)
  // ─────────────────────────────────────────────
  
  // Creates an Excel workbook in memory for a specific table
    private async createExcelWorkbook(userId: string, tableName: string): Promise<ExcelJS.Workbook> {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet(tableName);

    // Helper to map categories
    const categoriesList = await this.db.query.categories.findMany();
    const categoriesMap = new Map();
    for (const c of categoriesList) categoriesMap.set(c.id, c);

    // Fetch data based on table (excluding notifications as requested)
    if (tableName === 'transactions') {
      const data = await this.db.query.transactions.findMany({ where: eq(transactions.userId, userId) });
      const mappedData = data.map((t: any) => {
        const cat = categoriesMap.get(t.categoryId);
        return {
          ...t,
          categoryName: cat ? cat.name : '',
          categoryEmoji: cat ? cat.emojiIcon : ''
        };
      });
      worksheet.columns = [
        { header: 'ID', key: 'id' }, { header: 'Type', key: 'type' }, 
        { header: 'Amount', key: 'amount' }, { header: 'Date', key: 'date' },
        { header: 'Note', key: 'note' }, 
        { header: 'Category Name', key: 'categoryName' },
        { header: 'Category Emoji', key: 'categoryEmoji' }
      ];
      worksheet.addRows(mappedData);
    } else if (tableName === 'budgets') {
      const data = await this.db.query.budgets.findMany({ where: eq(budgets.userId, userId) });
      const mappedData = data.map((b: any) => {
        const cat = categoriesMap.get(b.categoryId);
        return {
          ...b,
          categoryName: cat ? cat.name : '',
          categoryEmoji: cat ? cat.emojiIcon : ''
        };
      });
      worksheet.columns = [
        { header: 'ID', key: 'id' }, 
        { header: 'Category Name', key: 'categoryName' },
        { header: 'Category Emoji', key: 'categoryEmoji' },
        { header: 'Limit Amount', key: 'limitAmount' }, { header: 'Month Year', key: 'monthYear' }
      ];
      worksheet.addRows(mappedData);
    } else if (tableName === 'savings_goals') {
      const data = await this.db.query.savingsGoals.findMany({ where: eq(savingsGoals.userId, userId) });
      worksheet.columns = [
        { header: 'ID', key: 'id' }, { header: 'Name', key: 'name' }, 
        { header: 'Target Amount', key: 'targetAmount' }, { header: 'Current Amount', key: 'currentAmount' },
        { header: 'Target Date', key: 'targetDate' }, { header: 'Status', key: 'status' }
      ];
      worksheet.addRows(data);
    } else if (tableName === 'categories') {
      // Categories are global or user-specific depending on future design, fetching all for now
      worksheet.columns = [
        { header: 'ID', key: 'id' }, { header: 'Name', key: 'name' }, 
        { header: 'Slug', key: 'slug' }, { header: 'Emoji Icon', key: 'emojiIcon' }
      ];
      worksheet.addRows(categoriesList);
    }

    return workbook;
  }

  async exportSingleTable(userId: string, tableName: string, res: Response) {
    const validTables = ['transactions', 'budgets', 'savings_goals', 'categories'];
    if (!validTables.includes(tableName)) throw new BadRequestException('Invalid table name');

    const workbook = await this.createExcelWorkbook(userId, tableName);
    
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=${tableName}_backup.xlsx`);
    
    // Stream directly to response, no file saved to disk (Compute/Storage optimization)
    await workbook.xlsx.write(res);
    res.end();
  }

    async exportAllAsZip(userId: string, reqTables: string[], res: Response) {
    const validTables = ['transactions', 'budgets', 'savings_goals', 'categories'];
    const tables = reqTables.length > 0 ? reqTables.filter(t => validTables.includes(t)) : validTables;
    
    res.setHeader('Content-Type', 'application/zip');
    res.setHeader('Content-Disposition', 'attachment; filename=cuanbuddy_backup.zip');

    const archiver = require('archiver');
    const archive = archiver('zip', { zlib: { level: 9 } }); // Maximum compression
    archive.pipe(res);

    // Generate Excel files in memory and append to ZIP stream
    for (const table of tables) {
      const workbook = await this.createExcelWorkbook(userId, table);
      const buffer = await workbook.xlsx.writeBuffer();
      archive.append(Buffer.from(buffer), { name: `${table}.xlsx` });
    }

    await archive.finalize();
  }

  // ─────────────────────────────────────────────
  // TEMPLATE
  // ─────────────────────────────────────────────
  async downloadTemplate(tableName: string, res: Response) {
    const validTables = ['transactions', 'budgets', 'savings_goals', 'categories'];
    if (!validTables.includes(tableName)) throw new BadRequestException('Invalid table name');

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet(tableName);

    // Headers only
    if (tableName === 'transactions') worksheet.columns = [{ header: 'Type', key: 'type' }, { header: 'Amount', key: 'amount' }, { header: 'Date', key: 'date' }, { header: 'Note', key: 'note' }, { header: 'CategoryID', key: 'categoryId' }];
    else if (tableName === 'budgets') worksheet.columns = [{ header: 'CategoryID', key: 'categoryId' }, { header: 'Limit Amount', key: 'limitAmount' }, { header: 'Month Year', key: 'monthYear' }];
    else if (tableName === 'savings_goals') worksheet.columns = [{ header: 'Name', key: 'name' }, { header: 'Target Amount', key: 'targetAmount' }, { header: 'Current Amount', key: 'currentAmount' }, { header: 'Target Date', key: 'targetDate' }, { header: 'Status', key: 'status' }];
    else if (tableName === 'categories') worksheet.columns = [{ header: 'Name', key: 'name' }, { header: 'Slug', key: 'slug' }, { header: 'Emoji Icon', key: 'emojiIcon' }];

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=${tableName}_template.xlsx`);
    
    await workbook.xlsx.write(res);
    res.end();
  }

  // ─────────────────────────────────────────────
  // IMPORT (ZIP or Excel)
  // ─────────────────────────────────────────────
  // Note: For a production app, the import logic would parse the Excel/ZIP buffer,
  // validate each row, and use bulk inserts. Due to space constraints in this service,
  // we are implementing the structure. Actual DB inserts would follow Drizzle patterns.
    async processImport(userId: string, file: Express.Multer.File) {
    if (!file) throw new BadRequestException('No file uploaded');

    const isZip = file.originalname.endsWith('.zip');
    const isExcel = file.originalname.endsWith('.xlsx');

    if (!isZip && !isExcel) throw new BadRequestException('Only .zip or .xlsx allowed');

    let buffersToProcess: { name: string; buffer: Buffer }[] = [];

    if (isZip) {
      const AdmZip = await import('adm-zip');
      const zip = new AdmZip.default(file.buffer);
      const zipEntries = zip.getEntries();
      for (const entry of zipEntries) {
        if (!entry.isDirectory && entry.entryName.endsWith('.xlsx')) {
          buffersToProcess.push({ name: entry.entryName.replace('.xlsx', ''), buffer: entry.getData() });
        }
      }
    } else {
      buffersToProcess.push({ name: file.originalname.replace('.xlsx', '').replace('_backup', ''), buffer: file.buffer });
    }

    let importedCount = 0;

    for (const item of buffersToProcess) {
      const workbook = new ExcelJS.Workbook();
      await workbook.xlsx.load(item.buffer as any);
      
      const worksheet = workbook.worksheets[0]; // Assuming one sheet per file
      if (!worksheet) continue;

      const tableName = worksheet.name || item.name;

      // Ensure categories exist
      if (tableName === 'transactions' || tableName === 'budgets') {
        const rows: any[] = [];
        worksheet.eachRow((row, rowNumber) => {
          if (rowNumber === 1) return; // Skip header
          rows.push(row.values);
        });

        // Column mapping depends on what we exported.
        // ID, Type, Amount, Date, Note, Category Name, Category Emoji
        for (const rowVals of rows) {
          const type = rowVals[2];
          const amount = rowVals[3];
          const date = rowVals[4];
          const note = rowVals[5];
          const catName = tableName === 'transactions' ? rowVals[6] : rowVals[2];
          const catEmoji = tableName === 'transactions' ? rowVals[7] : rowVals[3];
          
          let categoryId = null;
          if (catName) {
            const slug = String(catName).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');
            let existingCat = await this.db.query.categories.findFirst({
              where: and(eq(categories.slug, slug), eq(categories.userId, userId))
            });
            if (!existingCat) {
               const [newCat] = await this.db.insert(categories).values({
                 userId,
                 name: String(catName),
                 slug,
                 emojiIcon: catEmoji ? String(catEmoji) : null
               }).returning();
               existingCat = newCat;
            }
            categoryId = existingCat.id;
          }

          if (tableName === 'transactions') {
            await this.db.insert(transactions).values({
              userId,
              type: String(type) === 'income' ? 'income' : 'expense',
              amount: String(amount),
              date: new Date(date),
              note: note ? String(note) : null,
              categoryId
            });
            importedCount++;
          } else if (tableName === 'budgets') {
            const limitAmount = rowVals[4];
            const monthYear = rowVals[5];
            if (categoryId) {
              await this.db.insert(budgets).values({
                userId,
                categoryId,
                limitAmount: String(limitAmount),
                monthYear: String(monthYear)
              });
              importedCount++;
            }
          }
        }
      }
    }
    
    return {
      message: 'File received and processed successfully',
      type: isZip ? 'zip' : 'excel',
      fileName: file.originalname,
      recordsImported: importedCount
    };
  }

  // ─────────────────────────────────────────────
  // CRON JOB (Vercel Endpoint)
  // ─────────────────────────────────────────────
  async processScheduledBackups() {
    const now = new Date();
    
    // Find users whose backup time has arrived
    const dueBackups = await this.db.query.backupSettings.findMany({
      where: and(
        eq(backupSettings.isEnabled, true),
        lte(backupSettings.nextBackupAt, now)
      )
    });

    for (const setting of dueBackups) {
      // 1. Notify user
      void this.notificationsService.createAndBroadcast(
        setting.userId,
        'Backup Ready',
        'Your scheduled backup is ready to be downloaded.',
        'system'
      );

      // 2. Calculate next backup time
      const nextDate = this.calculateNextBackupDate(setting.interval as any);

      // 3. Update setting (fire-and-forget)
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