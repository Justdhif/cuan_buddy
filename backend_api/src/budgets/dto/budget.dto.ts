import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const CreateBudgetSchema = z.object({
  name: z.string().optional().nullable(),
  emojiIcon: z.string().optional().nullable(),
  colorCode: z.string().optional().nullable(),
  type: z.enum(['standalone', 'category']).optional().default('category'),
  categoryIds: z.array(z.string().uuid()).optional().nullable(),
  categoryId: z.string().uuid().optional().nullable(),
  walletId: z.string().uuid().optional().nullable(),
  limitAmount: z.number().positive(),
  currency: z.string().optional(),
  monthYear: z.string().regex(/^\d{4}-\d{2}$/, 'Must be in YYYY-MM format'),
  periodCount: z.number().int().min(1).optional().default(1),
  startDay: z.number().int().min(1).max(28).optional().default(1),
});

export const UpdateBudgetSchema = CreateBudgetSchema.partial();

export class CreateBudgetDto extends createZodDto(CreateBudgetSchema) {}
export class UpdateBudgetDto extends createZodDto(UpdateBudgetSchema) {}
