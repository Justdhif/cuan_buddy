import { Controller, Get, Put, Post, Body, UseGuards, Request, Response, UnauthorizedException, UseInterceptors, UploadedFile } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { FileInterceptor } from '@nestjs/platform-express';
import { ConfigService } from '@nestjs/config';
import { BackupService } from './backup.service';
import { UpdateBackupSettingsDto } from './dto/backup-settings.dto';

@ApiTags('Backup & Restore')
@Controller('backup')
export class BackupController {
  constructor(
    private readonly backupService: BackupService,
    private readonly configService: ConfigService,
  ) {}

  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Get('settings')
  @ApiOperation({ summary: 'Get backup settings' })
  getSettings(@Request() req: any) {
    return this.backupService.getSettings(req.user.userId);
  }

  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Put('settings')
  @ApiOperation({ summary: 'Update backup settings' })
  updateSettings(@Request() req: any, @Body() dto: UpdateBackupSettingsDto) {
    return this.backupService.updateSettings(req.user.userId, dto.isEnabled, dto.interval);
  }

  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Get('export')
  @ApiOperation({ summary: 'Export database as SQL file' })
  exportDatabaseSql(@Request() req: any, @Response() res: any) {
    return this.backupService.exportDatabaseSql(req.user.userId, res);
  }

  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Post('import')
  @ApiOperation({ summary: 'Import and Restore data from SQL database file' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @UseInterceptors(FileInterceptor('file'))
  importData(@Request() req: any, @UploadedFile() file: Express.Multer.File) {
    return this.backupService.processImport(req.user.userId, file);
  }

  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Post('mark-completed')
  @ApiOperation({ summary: 'Mark backup as completed' })
  markCompleted(@Request() req: any) {
    return this.backupService.markBackupCompleted(req.user.userId);
  }

  // ─────────────────────────────────────────────
  // VERCEL CRON ENDPOINT
  // ─────────────────────────────────────────────
  @Get('process-cron')
  @ApiOperation({ summary: 'Vercel Cron Trigger (Requires CRON_SECRET)' })
  processCron(@Request() req: any) {
    const authHeader = req.headers.authorization;
    const expectedSecret = this.configService.get<string>('CRON_SECRET');
    
    if (!expectedSecret || authHeader !== `Bearer ${expectedSecret}`) {
      throw new UnauthorizedException('Invalid cron secret');
    }

    return this.backupService.processScheduledBackups();
  }
}
