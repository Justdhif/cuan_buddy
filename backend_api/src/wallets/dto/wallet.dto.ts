import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const CreateWalletSchema = z.object({
  name: z.string().min(1).max(255),
  type: z.enum(['cash', 'bank', 'e_wallet', 'crypto', 'other']).default('cash'),
  currency: z.string().min(2).max(10).default('IDR'),
  balance: z.number().default(0),
});

export const UpdateWalletSchema = CreateWalletSchema.partial();

export class CreateWalletDto extends createZodDto(CreateWalletSchema) {}
export class UpdateWalletDto extends createZodDto(UpdateWalletSchema) {}
