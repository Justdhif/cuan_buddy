import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Req, Query } from '@nestjs/common';
import { TransactionsService } from './transactions.service';
import { CreateTransactionDto, UpdateTransactionDto } from './dto/transaction.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('transactions')
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Post()
  create(@Req() req, @Body() createTransactionDto: CreateTransactionDto) {
    return this.transactionsService.create(req.user.userId, createTransactionDto);
  }

  @Get()
  findAll(@Req() req, @Query() query: any) {
    return this.transactionsService.findAll(req.user.userId, query);
  }

  @Get(':id')
  findOne(@Req() req, @Param('id') id: string) {
    return this.transactionsService.findOne(req.user.userId, id);
  }

  @Patch(':id')
  update(@Req() req, @Param('id') id: string, @Body() updateTransactionDto: UpdateTransactionDto) {
    return this.transactionsService.update(req.user.userId, id, updateTransactionDto);
  }

  @Delete(':id')
  remove(@Req() req, @Param('id') id: string) {
    return this.transactionsService.remove(req.user.userId, id);
  }
}
