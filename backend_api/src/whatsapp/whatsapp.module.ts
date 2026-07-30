import { Module } from '@nestjs/common';
import { WhatsappController } from './whatsapp.controller';
import { WhatsappService } from './whatsapp.service';
import { DatabaseModule } from '../database/database.module';
import { TransactionsModule } from '../transactions/transactions.module';
import { AiModule } from '../ai/ai.module';

@Module({
  imports: [DatabaseModule, TransactionsModule, AiModule],
  controllers: [WhatsappController],
  providers: [WhatsappService],
  exports: [WhatsappService],
})
export class WhatsappModule {}
