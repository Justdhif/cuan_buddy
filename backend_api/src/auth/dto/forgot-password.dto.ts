import { IsEmail, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ForgotPasswordDto {
  @ApiProperty({ example: 'user@cuanbuddy.com', description: 'The email address of the user' })
  @IsEmail()
  @IsNotEmpty()
  email!: string;
}
