import { pgTable, text, timestamp, boolean, uuid, integer, decimal, pgEnum } from 'drizzle-orm/pg-core';

export const transactionTypeEnum = pgEnum('transaction_type', ['income', 'expense']);
export const walletTypeEnum = pgEnum('wallet_type', ['cash', 'bank', 'e_wallet', 'crypto', 'other']);

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  isActive: boolean('is_active').default(false).notNull(),
  provider: text('provider').default('local'),
  providerId: text('provider_id'),
  resetOtp: text('reset_otp'),
  resetOtpExpiresAt: timestamp('reset_otp_expires_at'),
  lastLoginAt: timestamp('last_login_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const userProfiles = pgTable('user_profiles', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }).unique(),
  fullName: text('full_name'),
  username: text('username').unique(),
  avatar: text('avatar'),
  phoneNumber: text('phone_number'),
  birthDate: timestamp('birth_date'),
  gender: text('gender'),
  bio: text('bio'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const categories = pgTable('categories', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  emojiIcon: text('emoji_icon'),
  colorCode: text('color_code'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const wallets = pgTable('wallets', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  emojiIcon: text('emoji_icon').default('💼'),
  colorCode: text('color_code').default('#6C63FF'),
  type: walletTypeEnum('type').default('cash').notNull(),
  currency: text('currency').default('IDR').notNull(),
  isBaseCurrency: boolean('is_base_currency').default(false).notNull(),
  balance: decimal('balance', { precision: 19, scale: 2 }).default('0').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const transactions = pgTable('transactions', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  walletId: uuid('wallet_id').notNull().references(() => wallets.id, { onDelete: 'cascade' }),
  title: text('title'),
  type: transactionTypeEnum('type').notNull(),
  amount: decimal('amount', { precision: 19, scale: 2 }).notNull(),
  exchangeRate: decimal('exchange_rate', { precision: 19, scale: 6 }).default('1').notNull(),
  baseAmount: decimal('base_amount', { precision: 19, scale: 2 }).notNull(),
  categoryId: uuid('category_id').references(() => categories.id, { onDelete: 'set null' }),
  savingsGoalId: uuid('savings_goal_id').references(() => savingsGoals.id, { onDelete: 'set null' }),
  note: text('note'),
  date: timestamp('date').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const budgets = pgTable('budgets', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  categoryId: uuid('category_id').notNull().references(() => categories.id, { onDelete: 'cascade' }),
  walletId: uuid('wallet_id').references(() => wallets.id, { onDelete: 'set null' }),
  limitAmount: decimal('limit_amount', { precision: 19, scale: 2 }).notNull(),
  periodCount: integer('period_count').default(1).notNull(), // how many months this budget spans
  startDay: integer('start_day').default(1).notNull(),       // which day of month the period starts
  monthYear: text('month_year').notNull(), // format YYYY-MM (start month)
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const savingsGoals = pgTable('savings_goals', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  walletId: uuid('wallet_id').references(() => wallets.id, { onDelete: 'set null' }),
  name: text('name').notNull(),
  emojiIcon: text('emoji_icon').default('🎯'),
  colorCode: text('color_code').default('#6C63FF'),
  targetAmount: decimal('target_amount', { precision: 19, scale: 2 }).notNull(),
  currentAmount: decimal('current_amount', { precision: 19, scale: 2 }).default('0').notNull(),
  targetDate: timestamp('target_date'),
  status: text('status').default('in_progress'), // in_progress, completed
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const notifications = pgTable('notifications', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  title: text('title').notNull(),
  message: text('message').notNull(),
  isRead: boolean('is_read').default(false).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const backupSettings = pgTable('backup_settings', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }).unique(),
  isEnabled: boolean('is_enabled').default(false).notNull(),
  interval: text('interval').default('7d').notNull(), // '24h', '7d', '1m'
  lastBackupAt: timestamp('last_backup_at'),
  nextBackupAt: timestamp('next_backup_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const feedbacks = pgTable('feedbacks', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
  message: text('message').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});


