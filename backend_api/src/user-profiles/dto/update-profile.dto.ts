import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const UpdateProfileSchema = z.object({
  fullName: z.string().min(2).max(100).optional(),
  username: z.string().min(3).max(30).optional(),
  phoneNumber: z.string().optional(),
  birthDate: z.string().datetime().optional(),
  gender: z.string().optional(),
  bio: z.string().max(250).optional(),
  language: z.string().optional(),
});

export const UpdateAvatarSchema = z.object({
  avatar: z.string().url(),
});

export class UpdateProfileDto extends createZodDto(UpdateProfileSchema) {}
export class UpdateAvatarDto extends createZodDto(UpdateAvatarSchema) {}
