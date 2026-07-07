import 'multer';
import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { AiService } from './ai.service';
import { AiChatDto, AiCategorizeDto } from './dto/ai.dto';

@ApiTags('AI')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('chat')
  @ApiOperation({
    summary: '💬 Financial Advisor Chat',
    description: 'Tanya AI tentang kondisi keuangan kamu. AI punya akses ke data transaksi, budget, dan tabungan kamu.',
  })
  @ApiResponse({ status: 201, description: 'AI reply berhasil digenerate' })
  chat(@Request() req: any, @Body() dto: AiChatDto) {
    return this.aiService.chat(req.user.userId, dto.message);
  }

  @Get('insights')
  @ApiOperation({
    summary: '💡 Spending Insights',
    description: 'Generate narasi analisis keuangan personal berdasarkan data 3 bulan terakhir.',
  })
  @ApiResponse({ status: 200, description: 'Insights berhasil digenerate' })
  getInsights(@Request() req: any) {
    return this.aiService.getInsights(req.user.userId);
  }

  @Post('categorize')
  @ApiOperation({
    summary: '🏷️ Auto-Categorize Transaction',
    description: 'Kirim catatan (note) transaksi, AI akan menyarankan kategori yang paling cocok.',
  })
  @ApiResponse({ status: 201, description: 'Kategori berhasil disarankan' })
  categorize(@Body() dto: AiCategorizeDto) {
    return this.aiService.categorize(dto.note);
  }

  @Get('budget-recommendation')
  @ApiOperation({
    summary: '📊 Budget Recommendation',
    description: 'AI analisis pola pengeluaran 3 bulan terakhir dan rekomendasikan limit budget realistis per kategori.',
  })
  @ApiResponse({ status: 200, description: 'Rekomendasi budget berhasil digenerate' })
  getBudgetRecommendation(@Request() req: any) {
    return this.aiService.getBudgetRecommendation(req.user.userId);
  }

  @Post('voice-transaction')
  @UseInterceptors(FileInterceptor('audio'))
  @ApiOperation({
    summary: '🎙️ Voice Transaction Logging',
    description: 'Kirim file suara, AI akan mentranskripsi dan mencatat transaksi otomatis.',
  })
  @ApiResponse({ status: 201, description: 'Transaksi berhasil dicatat' })
  async voiceTransaction(
    @Request() req: any,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('File audio tidak ditemukan');
    }
    return this.aiService.processVoiceTransaction(
      req.user.userId,
      file.buffer,
      file.originalname,
    );
  }

  @Post('scan-receipt')
  @UseInterceptors(FileInterceptor('image'))
  @ApiOperation({
    summary: '📄 Scan Receipt',
    description: 'Kirim foto struk, AI akan mengekstrak detail transaksi otomatis.',
  })
  @ApiResponse({ status: 201, description: 'Struk berhasil diekstrak' })
  async scanReceipt(
    @Request() req: any,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('File gambar tidak ditemukan');
    }
    return this.aiService.processReceiptTransaction(
      req.user.userId,
      file.buffer,
      file.mimetype,
    );
  }
}
