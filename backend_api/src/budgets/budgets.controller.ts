import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Req, Query } from '@nestjs/common';
import { BudgetsService } from './budgets.service';
import { CreateBudgetDto, UpdateBudgetDto } from './dto/budget.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('budgets')
export class BudgetsController {
  constructor(private readonly budgetsService: BudgetsService) {}

  @Post()
  create(@Req() req, @Body() createBudgetDto: CreateBudgetDto) {
    return this.budgetsService.create(req.user.userId, createBudgetDto);
  }

  @Get()
  findAll(@Req() req, @Query() query: any) {
    return this.budgetsService.findAll(req.user.userId, query);
  }

  @Get(':id')
  findOne(@Req() req, @Param('id') id: string) {
    return this.budgetsService.findOne(req.user.userId, id);
  }

  @Patch(':id')
  update(@Req() req, @Param('id') id: string, @Body() updateBudgetDto: UpdateBudgetDto) {
    return this.budgetsService.update(req.user.userId, id, updateBudgetDto);
  }

  @Delete(':id')
  remove(@Req() req, @Param('id') id: string) {
    return this.budgetsService.remove(req.user.userId, id);
  }
}
