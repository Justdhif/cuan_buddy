import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq, and } from 'drizzle-orm';
import { DATABASE_CONNECTION } from '../database/database.module';
import { wallets } from '../database/schema';
import { CreateWalletDto, UpdateWalletDto } from './dto/wallet.dto';
import { roundDecimal } from '../common/utils/formatter.util';

@Injectable()
export class WalletsService {
  constructor(
    @Inject(DATABASE_CONNECTION) private readonly db: any,
  ) {}

  async create(userId: string, createWalletDto: CreateWalletDto) {
    if (createWalletDto.isBaseCurrency) {
      await this.db.update(wallets)
        .set({ isBaseCurrency: false })
        .where(eq(wallets.userId, userId));
    }

    const decimalPrecision = createWalletDto.decimalPrecision ?? 2;

    const [newWallet] = await this.db
      .insert(wallets)
      .values({
        userId,
        name: createWalletDto.name,
        type: createWalletDto.type,
        currency: createWalletDto.currency,
        isBaseCurrency: createWalletDto.isBaseCurrency || false,
        decimalPrecision,
        balance: roundDecimal(createWalletDto.balance, decimalPrecision).toString(),
        emojiIcon: createWalletDto.emojiIcon,
        colorCode: createWalletDto.colorCode,
      })
      .returning();

    return newWallet;
  }

  async findAll(userId: string) {
    return await this.db.query.wallets.findMany({
      where: eq(wallets.userId, userId),
      orderBy: (wallets, { asc }) => [asc(wallets.createdAt)],
    });
  }

  async findOne(userId: string, id: string) {
    const wallet = await this.db.query.wallets.findFirst({
      where: and(eq(wallets.id, id), eq(wallets.userId, userId)),
    });

    if (!wallet) {
      throw new NotFoundException('Wallet not found');
    }

    return wallet;
  }

  async update(userId: string, id: string, updateWalletDto: UpdateWalletDto) {
    const existingWallet = await this.db.query.wallets.findFirst({
      where: and(eq(wallets.id, id), eq(wallets.userId, userId)),
    });

    if (!existingWallet) {
      throw new NotFoundException('Wallet not found');
    }

    if (updateWalletDto.isBaseCurrency) {
      await this.db.update(wallets)
        .set({ isBaseCurrency: false })
        .where(eq(wallets.userId, userId));
    }

    const decimalPrecision = updateWalletDto.decimalPrecision ?? existingWallet.decimalPrecision ?? 2;

    const updateData: any = { ...updateWalletDto, updatedAt: new Date(), decimalPrecision };
    if (updateWalletDto.balance !== undefined) {
      updateData.balance = roundDecimal(updateWalletDto.balance, decimalPrecision).toString();
    } else if (updateWalletDto.decimalPrecision !== undefined) {
      updateData.balance = roundDecimal(existingWallet.balance, decimalPrecision).toString();
    }

    const [updated] = await this.db
      .update(wallets)
      .set(updateData)
      .where(and(eq(wallets.id, id), eq(wallets.userId, userId)))
      .returning();

    return updated;
  }

  async remove(userId: string, id: string) {
    const [deleted] = await this.db
      .delete(wallets)
      .where(and(eq(wallets.id, id), eq(wallets.userId, userId)))
      .returning();

    if (!deleted) {
      throw new NotFoundException('Wallet not found');
    }

    return { message: 'Wallet removed successfully' };
  }
}
