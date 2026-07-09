import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const CreateSavingsGoalSchema = z.object({
  name: z.string().min(1),
  walletId: z.string().uuid().optional().nullable(),
  emojiIcon: z.string().optional(),
  colorCode: z.string().optional(),
  targetAmount: z.number().positive(),
  currentAmount: z.number().min(0).optional(),
  currency: z.string().optional(),
  targetDate: z.string().optional(),
  status: z.enum(['in_progress', 'completed']).optional(),
  isPin: z.boolean().optional(),
  link: z.string().optional().nullable(),
});

export const UpdateSavingsGoalSchema = CreateSavingsGoalSchema.partial();

export class CreateSavingsGoalDto extends createZodDto(CreateSavingsGoalSchema) {}
export class UpdateSavingsGoalDto extends createZodDto(UpdateSavingsGoalSchema) {}
