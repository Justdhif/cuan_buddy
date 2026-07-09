import { ApiProperty } from '@nestjs/swagger';
import { z } from 'zod';
import { createZodDto } from 'nestjs-zod';

const ChangePasswordSchema = z.object({
  oldPassword: z.string().min(1, { message: 'Old password is required' }),
  newPassword: z.string().min(8, { message: 'New password must be at least 8 characters long' }),
});

export class ChangePasswordDto extends createZodDto(ChangePasswordSchema) {
  @ApiProperty({ example: 'oldPassword123', description: 'Current password' })
  oldPassword!: string;

  @ApiProperty({ example: 'newPassword123', description: 'New password' })
  newPassword!: string;
}
