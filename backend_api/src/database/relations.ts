import { relations } from 'drizzle-orm';
import { users, userProfiles, categories, transactions, budgets, savingsGoals, notifications, backupSettings, feedbacks, wallets, friendships, rooms, roomMembers } from './schema';

export const usersRelations = relations(users, ({ one, many }) => ({
  profile: one(userProfiles, {
    fields: [users.id],
    references: [userProfiles.userId],
  }),
  transactions: many(transactions),
  budgets: many(budgets),
  savingsGoals: many(savingsGoals),
  notifications: many(notifications),
  feedbacks: many(feedbacks),
  wallets: many(wallets),
  backupSettings: one(backupSettings, {
    fields: [users.id],
    references: [backupSettings.userId],
  }),
  friendshipsSent: many(friendships, { relationName: 'sender' }),
  friendshipsReceived: many(friendships, { relationName: 'receiver' }),
  roomMemberships: many(roomMembers),
}));

export const walletsRelations = relations(wallets, ({ one, many }) => ({
  user: one(users, {
    fields: [wallets.userId],
    references: [users.id],
  }),
  transactions: many(transactions),
  budgets: many(budgets),
  savingsGoals: many(savingsGoals),
}));

export const userProfilesRelations = relations(userProfiles, ({ one }) => ({
  user: one(users, {
    fields: [userProfiles.userId],
    references: [users.id],
  }),
}));

export const categoriesRelations = relations(categories, ({ many }) => ({
  transactions: many(transactions),
  budgets: many(budgets),
}));

export const friendshipsRelations = relations(friendships, ({ one }) => ({
  sender: one(users, {
    fields: [friendships.senderId],
    references: [users.id],
    relationName: 'sender',
  }),
  receiver: one(users, {
    fields: [friendships.receiverId],
    references: [users.id],
    relationName: 'receiver',
  }),
}));

export const roomsRelations = relations(rooms, ({ one, many }) => ({
  creator: one(users, {
    fields: [rooms.createdBy],
    references: [users.id],
  }),
  members: many(roomMembers),
  transactions: many(transactions),
  budgets: many(budgets),
  savingsGoals: many(savingsGoals),
}));

export const roomMembersRelations = relations(roomMembers, ({ one }) => ({
  room: one(rooms, {
    fields: [roomMembers.roomId],
    references: [rooms.id],
  }),
  user: one(users, {
    fields: [roomMembers.userId],
    references: [users.id],
  }),
}));

export const transactionsRelations = relations(transactions, ({ one }) => ({
  user: one(users, {
    fields: [transactions.userId],
    references: [users.id],
  }),
  wallet: one(wallets, {
    fields: [transactions.walletId],
    references: [wallets.id],
  }),
  category: one(categories, {
    fields: [transactions.categoryId],
    references: [categories.id],
  }),
  savingsGoal: one(savingsGoals, {
    fields: [transactions.savingsGoalId],
    references: [savingsGoals.id],
  }),
  room: one(rooms, {
    fields: [transactions.roomId],
    references: [rooms.id],
  }),
}));

export const budgetsRelations = relations(budgets, ({ one }) => ({
  user: one(users, {
    fields: [budgets.userId],
    references: [users.id],
  }),
  category: one(categories, {
    fields: [budgets.categoryId],
    references: [categories.id],
  }),
  wallet: one(wallets, {
    fields: [budgets.walletId],
    references: [wallets.id],
  }),
  room: one(rooms, {
    fields: [budgets.roomId],
    references: [rooms.id],
  }),
}));

export const savingsGoalsRelations = relations(savingsGoals, ({ one, many }) => ({
  user: one(users, {
    fields: [savingsGoals.userId],
    references: [users.id],
  }),
  transactions: many(transactions),
  wallet: one(wallets, {
    fields: [savingsGoals.walletId],
    references: [wallets.id],
  }),
  room: one(rooms, {
    fields: [savingsGoals.roomId],
    references: [rooms.id],
  }),
}));

export const notificationsRelations = relations(notifications, ({ one }) => ({
  user: one(users, {
    fields: [notifications.userId],
    references: [users.id],
  }),
}));

export const backupSettingsRelations = relations(backupSettings, ({ one }) => ({
  user: one(users, {
    fields: [backupSettings.userId],
    references: [users.id],
  }),
}));

export const feedbacksRelations = relations(feedbacks, ({ one }) => ({
  user: one(users, {
    fields: [feedbacks.userId],
    references: [users.id],
  }),
}));

