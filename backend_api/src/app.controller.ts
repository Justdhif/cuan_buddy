import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello() {
    return {
      status: true,
      message: 'CuanBuddy API is running smoothly 🚀',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
    };
  }
}
