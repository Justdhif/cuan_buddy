import { Controller, Get, UseGuards, Req, Query } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('summary')
  getSummary(@Req() req) {
    return this.analyticsService.getSummary(req.user.userId);
  }

  @Get('spending-category')
  getSpendingByCategory(@Req() req) {
    return this.analyticsService.getSpendingByCategory(req.user.userId);
  }

  @Get('monthly-trend')
  getMonthlyTrend(@Req() req) {
    return this.analyticsService.getMonthlyTrend(req.user.userId);
  }

  @Get('financial-health')
  getFinancialHealth(@Req() req) {
    return this.analyticsService.getFinancialHealth(req.user.userId);
  }

  @Get('savings-progress')
  getSavingsProgress(@Req() req) {
    return this.analyticsService.getSavingsProgress(req.user.userId);
  }

  @Get('daily-burn-rate')
  getDailyBurnRate(@Req() req, @Query('monthYear') monthYear?: string) {
    return this.analyticsService.getDailyBurnRate(req.user.userId, monthYear);
  }
}

