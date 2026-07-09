import { IsString, IsNotEmpty, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AiChatDto {
  @ApiProperty({ example: 'Where did I overspend this month?' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500) // Limit input to prevent token abuse
  message!: string;
}

export class AiCategorizeDto {
  @ApiProperty({ example: 'Lunch at a nearby restaurant' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  note!: string;
}
