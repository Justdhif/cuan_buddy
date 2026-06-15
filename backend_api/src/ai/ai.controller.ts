import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
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
    return this.aiService.chat(req.user.sub, dto.message);
  }

  @Get('insights')
  @ApiOperation({
    summary: '💡 Spending Insights',
    description: 'Generate narasi analisis keuangan personal berdasarkan data 3 bulan terakhir.',
  })
  @ApiResponse({ status: 200, description: 'Insights berhasil digenerate' })
  getInsights(@Request() req: any) {
    return this.aiService.getInsights(req.user.sub);
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
    return this.aiService.getBudgetRecommendation(req.user.sub);
  }
}
