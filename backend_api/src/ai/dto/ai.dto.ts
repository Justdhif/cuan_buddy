import { IsString, IsNotEmpty, MaxLength, IsOptional, IsUUID } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AiChatDto {
  @ApiPropertyOptional({ example: '123e4567-e89b-12d3-a456-426614174000' })
  @IsOptional()
  @IsUUID()
  conversationId?: string;

  @ApiProperty({ example: 'Where did I overspend this month?' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  message!: string;
}

export class AiCategorizeDto {
  @ApiProperty({ example: 'Lunch at a nearby restaurant' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  note!: string;
}

export class UpdateConversationDto {
  @ApiProperty({ example: 'Analisis Anggaran Juli' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  title!: string;
}
