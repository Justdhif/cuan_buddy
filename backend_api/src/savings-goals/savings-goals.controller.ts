import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Req, Query } from '@nestjs/common';
import { SavingsGoalsService } from './savings-goals.service';
import { CreateSavingsGoalDto, UpdateSavingsGoalDto } from './dto/savings-goal.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('goals')
export class SavingsGoalsController {
  constructor(private readonly savingsGoalsService: SavingsGoalsService) {}

  @Post()
  create(@Req() req, @Body() createSavingsGoalDto: CreateSavingsGoalDto) {
    return this.savingsGoalsService.create(req.user.userId, createSavingsGoalDto);
  }

  @Get()
  findAll(@Req() req, @Query() query: any) {
    return this.savingsGoalsService.findAll(req.user.userId, query);
  }

  @Get(':slug')
  findOne(@Req() req, @Param('slug') slug: string) {
    return this.savingsGoalsService.findOne(req.user.userId, slug);
  }

  @Patch(':slug')
  update(@Req() req, @Param('slug') slug: string, @Body() updateSavingsGoalDto: UpdateSavingsGoalDto) {
    return this.savingsGoalsService.update(req.user.userId, slug, updateSavingsGoalDto);
  }

  @Delete(':slug')
  remove(@Req() req, @Param('slug') slug: string) {
    return this.savingsGoalsService.remove(req.user.userId, slug);
  }
}
