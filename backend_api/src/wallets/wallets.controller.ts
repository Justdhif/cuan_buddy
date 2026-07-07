import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { WalletsService } from './wallets.service';
import { CreateWalletDto, UpdateWalletDto } from './dto/wallet.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('wallets')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('wallets')
export class WalletsController {
  constructor(private readonly walletsService: WalletsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new wallet' })
  @ApiResponse({ status: 201, description: 'Wallet successfully created.' })
  create(@Req() req, @Body() createWalletDto: CreateWalletDto) {
    return this.walletsService.create(req.user.userId, createWalletDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all wallets for logged in user' })
  @ApiResponse({ status: 200, description: 'Return all wallets.' })
  findAll(@Req() req) {
    return this.walletsService.findAll(req.user.userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a wallet by id' })
  @ApiResponse({ status: 200, description: 'Return the wallet.' })
  findOne(@Req() req, @Param('id') id: string) {
    return this.walletsService.findOne(req.user.userId, id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a wallet' })
  @ApiResponse({ status: 200, description: 'Wallet successfully updated.' })
  update(
    @Req() req,
    @Param('id') id: string,
    @Body() updateWalletDto: UpdateWalletDto,
  ) {
    return this.walletsService.update(req.user.userId, id, updateWalletDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a wallet' })
  @ApiResponse({ status: 200, description: 'Wallet successfully deleted.' })
  remove(@Req() req, @Param('id') id: string) {
    return this.walletsService.remove(req.user.userId, id);
  }
}
