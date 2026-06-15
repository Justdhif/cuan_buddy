import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const CreateBudgetSchema = z.object({
  categoryId: z.string().uuid(),
  limitAmount: z.number().positive(),
  monthYear: z.string().regex(/^\d{4}-\d{2}$/, 'Must be in YYYY-MM format'),
});

export const UpdateBudgetSchema = CreateBudgetSchema.partial();

export class CreateBudgetDto extends createZodDto(CreateBudgetSchema) {}
export class UpdateBudgetDto extends createZodDto(UpdateBudgetSchema) {}
