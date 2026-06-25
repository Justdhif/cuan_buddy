import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const CreateTransactionSchema = z.object({
  title: z.string().max(255).optional(),
  type: z.enum(['income', 'expense']),
  amount: z.number().positive(),
  currency: z.string().optional(),
  categoryId: z.string().uuid().nullable().optional(),
  savingsGoalId: z.string().uuid().nullable().optional(),
  note: z.string().max(255).nullable().optional(),
  date: z.string().datetime(),
});

export const UpdateTransactionSchema = CreateTransactionSchema.partial();

export class CreateTransactionDto extends createZodDto(CreateTransactionSchema) {}
export class UpdateTransactionDto extends createZodDto(UpdateTransactionSchema) {}
