import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const CreateWalletSchema = z.object({
  name: z.string().min(1).max(255),
  type: z.enum(['cash', 'bank', 'e_wallet', 'crypto', 'other']).default('cash'),
  currency: z.string().min(2).max(10).default('IDR'),
  isBaseCurrency: z.boolean().default(false).optional(),
  decimalPrecision: z.number().int().min(0).max(2).default(2),
  balance: z.number().default(0),
  emojiIcon: z.string().optional().default('💼'),
  colorCode: z.string().optional().default('#6C63FF'),
});

export const UpdateWalletSchema = CreateWalletSchema.partial();

export class CreateWalletDto extends createZodDto(CreateWalletSchema) {}
export class UpdateWalletDto extends createZodDto(UpdateWalletSchema) {}
