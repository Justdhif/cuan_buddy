import { IsBoolean, IsIn, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateBackupSettingsDto {
  @ApiProperty({ example: true, description: 'Enable or disable scheduled backups' })
  @IsOptional()
  @IsBoolean()
  isEnabled?: boolean;

  @ApiProperty({ example: '7d', enum: ['24h', '7d', '1m'], description: 'Backup interval' })
  @IsOptional()
  @IsIn(['24h', '7d', '1m'])
  interval?: '24h' | '7d' | '1m';
}
