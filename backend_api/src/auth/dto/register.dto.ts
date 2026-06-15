import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const RegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(100),
  fullName: z.string().min(2).max(100),
  avatar: z.string().url().optional(),
});

export class RegisterDto extends createZodDto(RegisterSchema) {}
