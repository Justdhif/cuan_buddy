import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const CreateTransactionSchema = z.object({
  title: z.string().max(255).optional(),
  type: z.enum(['income', 'expense']),
  amount: z.number().positive(),
  walletId: z.string().uuid(),
  exchangeRate: z.number().positive().default(1),
  categoryId: z.string().uuid().nullable().optional(),
  savingsGoalId: z.string().uuid().nullable().optional(),
  note: z.string().max(255).nullable().optional(),
  date: z.string().datetime(),
});

export const UpdateTransactionSchema = CreateTransactionSchema.partial();

export class CreateTransactionDto extends createZodDto(CreateTransactionSchema) {}
export class UpdateTransactionDto extends createZodDto(UpdateTransactionSchema) {}
