import { Module } from '@nestjs/common';
import { BordersController } from './borders.controller';

@Module({
  controllers: [BordersController],
})
export class BordersModule {}
