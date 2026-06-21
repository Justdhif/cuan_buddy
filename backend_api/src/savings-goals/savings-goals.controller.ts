import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Req, Query, ParseUUIDPipe } from '@nestjs/common';
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

  @Get(':id')
  findOne(@Req() req, @Param('id', ParseUUIDPipe) id: string) {
    return this.savingsGoalsService.findOne(req.user.userId, id);
  }

  @Patch(':id')
  update(@Req() req, @Param('id', ParseUUIDPipe) id: string, @Body() updateSavingsGoalDto: UpdateSavingsGoalDto) {
    return this.savingsGoalsService.update(req.user.userId, id, updateSavingsGoalDto);
  }

  @Delete(':id')
  remove(@Req() req, @Param('id', ParseUUIDPipe) id: string) {
    return this.savingsGoalsService.remove(req.user.userId, id);
  }
}
