import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const CreateSavingsGoalSchema = z.object({
  name: z.string().min(1),
  targetAmount: z.number().positive(),
  currentAmount: z.number().min(0).optional(),
  targetDate: z.string().optional(),
  status: z.enum(['in_progress', 'completed']).optional(),
});

export const UpdateSavingsGoalSchema = CreateSavingsGoalSchema.partial();

export class CreateSavingsGoalDto extends createZodDto(CreateSavingsGoalSchema) {}
export class UpdateSavingsGoalDto extends createZodDto(UpdateSavingsGoalSchema) {}
