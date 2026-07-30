import { Module } from '@nestjs/common';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { GroqService } from './groq.service';

@Module({
  controllers: [AiController],
  providers: [AiService, GroqService],
  exports: [AiService, GroqService],
})
export class AiModule {}
