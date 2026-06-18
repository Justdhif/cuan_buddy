import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const CreateTransactionSchema = z.object({
  type: z.enum(['income', 'expense']),
  amount: z.number().positive(),
  currency: z.string().optional(),
  categoryId: z.string().uuid().optional(),
  note: z.string().max(255).optional(),
  date: z.string().datetime(),
});

export const UpdateTransactionSchema = CreateTransactionSchema.partial();

export class CreateTransactionDto extends createZodDto(CreateTransactionSchema) {}
export class UpdateTransactionDto extends createZodDto(UpdateTransactionSchema) {}
