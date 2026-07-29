import 'multer';
import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Param,
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
import { AiChatDto, AiCategorizeDto, UpdateConversationDto } from './dto/ai.dto';

@ApiTags('AI')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Get('conversations')
  @ApiOperation({
    summary: '💬 List AI Conversations',
    description: 'Dapatkan daftar semua percakapan AI pengguna (maksimal 10).',
  })
  getConversations(@Request() req: any) {
    return this.aiService.getConversations(req.user.userId);
  }

  @Post('conversations')
  @ApiOperation({
    summary: '➕ Create New AI Conversation',
    description: 'Buat percakapan AI baru (maksimal 10 per user).',
  })
  createConversation(@Request() req: any, @Body('title') title?: string) {
    return this.aiService.createConversation(req.user.userId, title);
  }

  @Get('conversations/:id/messages')
  @ApiOperation({
    summary: '📜 Get Conversation Messages',
    description: 'Dapatkan riwayat pesan dalam satu percakapan tertentu.',
  })
  getConversationMessages(@Request() req: any, @Param('id') id: string) {
    return this.aiService.getConversationMessages(req.user.userId, id);
  }

  @Patch('conversations/:id')
  @ApiOperation({
    summary: '✏️ Update Conversation Title',
    description: 'Ubah judul percakapan AI.',
  })
  updateConversationTitle(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateConversationDto,
  ) {
    return this.aiService.updateConversationTitle(req.user.userId, id, dto.title);
  }

  @Delete('conversations/:id')
  @ApiOperation({
    summary: '🗑️ Delete Conversation',
    description: 'Hapus satu percakapan AI beserta pesannya.',
  })
  deleteConversation(@Request() req: any, @Param('id') id: string) {
    return this.aiService.deleteConversation(req.user.userId, id);
  }

  @Post('chat')
  @ApiOperation({
    summary: '💬 Financial Advisor Chat',
    description: 'Tanya AI tentang kondisi keuangan kamu. AI punya akses ke data transaksi, budget, dan tabungan kamu.',
  })
  @ApiResponse({ status: 201, description: 'AI reply berhasil digenerate' })
  chat(@Request() req: any, @Body() dto: AiChatDto) {
    return this.aiService.chat(req.user.userId, dto.message, dto.conversationId);
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
