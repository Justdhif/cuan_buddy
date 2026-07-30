import { Controller, Get, Post, Query, Body, Res, HttpStatus, UseGuards, Req } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Response } from 'express';
import { WhatsappService } from './whatsapp.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('whatsapp')
export class WhatsappController {
  constructor(
    private readonly whatsappService: WhatsappService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * 1. GET /whatsapp/webhook
   * Verification Endpoint for Meta / WhatsApp Cloud API Webhook Setup
   */
  @Get('webhook')
  verifyWebhook(
    @Query('hub.mode') mode: string,
    @Query('hub.verify_token') token: string,
    @Query('hub.challenge') challenge: string,
    @Res() res: Response,
  ) {
    const verifyToken = this.configService.get<string>('WA_VERIFY_TOKEN') || 'cuanbuddy_wa_verify_secret';

    if (mode && token === verifyToken) {
      return res.status(HttpStatus.OK).send(challenge);
    }
    return res.status(HttpStatus.FORBIDDEN).send('Verification failed');
  }

  /**
   * 2. POST /whatsapp/webhook
   * Receiver for all WhatsApp incoming messages & notifications from Meta
   */
  @Post('webhook')
  async handleWebhook(@Body() payload: any, @Res() res: Response) {
    try {
      await this.whatsappService.handleWebhookPayload(payload);
    } catch (e) {
      console.error('Webhook error:', e);
    }
    return res.status(HttpStatus.OK).send('EVENT_RECEIVED');
  }

  /**
   * 3. POST /whatsapp/connect-otp
   * Protected API Endpoint for CuanBuddy web/mobile app to request 6-digit OTP for WA pairing
   */
  @UseGuards(JwtAuthGuard)
  @Post('connect-otp')
  async getConnectOtp(@Req() req: any) {
    const userId = req.user.id;
    return this.whatsappService.generateConnectOtp(userId);
  }
}
