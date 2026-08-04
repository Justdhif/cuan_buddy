import { Controller, Post, Body, UseGuards, Req, BadRequestException } from '@nestjs/common';
import { WhatsappService } from './whatsapp.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('whatsapp')
export class WhatsappController {
  constructor(
    private readonly whatsappService: WhatsappService,
  ) {}

  /**
   * 1. POST /whatsapp/connect-otp
   * Protected API Endpoint for CuanBuddy web/mobile app to request 6-digit OTP for WA pairing
   */
  @UseGuards(JwtAuthGuard)
  @Post('connect-otp')
  async getConnectOtp(@Req() req: any) {
    const userId = req.user.userId;
    return this.whatsappService.generateConnectOtp(userId);
  }

  /**
   * 2. POST /whatsapp/connect
   * Public API Endpoint for Bot WhatsApp Service to pair a phone number with an OTP
   */
  @Post('connect')
  async connectAccount(@Body() body: { phoneNumber: string; otp: string }) {
    if (!body.phoneNumber || !body.otp) {
      throw new BadRequestException('phoneNumber dan otp wajib dikirimkan.');
    }
    return this.whatsappService.connectAccountViaOtp(body.phoneNumber, body.otp);
  }
}

