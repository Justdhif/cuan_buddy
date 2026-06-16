import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private transporter: nodemailer.Transporter;
  private readonly logger = new Logger(EmailService.name);

  private isProduction = process.env.NODE_ENV === 'production';

  constructor(private readonly configService: ConfigService) {
    const host = this.configService.get<string>('SMTP_HOST');
    const user = this.configService.get<string>('SMTP_USER');

    if (host && user) {
      this.transporter = nodemailer.createTransport({
        host,
        port: this.configService.get<number>('SMTP_PORT'),
        secure: false, // true for 465, false for other ports
        auth: {
          user,
          pass: this.configService.get<string>('SMTP_PASS'),
        },
      });
    } else {
      if (this.isProduction) {
        this.logger.warn('SMTP configuration is missing in PRODUCTION environment!');
      } else {
        this.logger.log('SMTP configuration missing in dev, falling back to console mock.');
      }
    }
  }

  private async sendMailOrLog(mailOptions: any) {
    if (this.transporter) {
      try {
        await this.transporter.sendMail(mailOptions);
        this.logger.debug(`Email sent to ${mailOptions.to}`);
      } catch (error) {
        this.logger.error(`Failed to send email to ${mailOptions.to}`, error);
        if (this.isProduction) {
          // In production, we might want to alert or throw depending on critical path.
          // For now, logging is sufficient as per fire-and-forget pattern.
        }
      }
    } else {
      // Mock email delivery for local development without SMTP
      this.logger.log(`
      ========== MOCK EMAIL DELIVERY ==========
      TO: ${mailOptions.to}
      SUBJECT: ${mailOptions.subject}
      HTML: ${mailOptions.html}
      =========================================
      `);
    }
  }

  async sendVerificationEmail(to: string, token: string) {
    const frontendUrl =
      this.configService.get<string>('FRONTEND_URL') || 'http://localhost:3000';
    // We can point this directly to our backend GET /api/auth/verify?token=... for testing
    // In production, it usually points to frontend, which then calls backend POST /api/auth/verify
    const verifyUrl = `${frontendUrl}/api/auth/verify?token=${token}`;

    const mailOptions = {
      from: `"CuanBuddy" <${this.configService.get<string>('SMTP_USER')}>`,
      to,
      subject: 'Verify your CuanBuddy Account',
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Welcome to CuanBuddy! 🎉</h2>
          <p>Thank you for registering. To activate your account and start tracking your finances, please verify your email by clicking the button below:</p>
          <a href="${verifyUrl}" style="display: inline-block; padding: 10px 20px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px;">Verify My Account</a>
          <p style="margin-top: 20px; color: #666;">If the button doesn't work, copy and paste this link into your browser:</p>
          <p style="word-break: break-all; color: #0066cc;">${verifyUrl}</p>
        </div>
      `,
    };

    await this.sendMailOrLog(mailOptions);
  }

  async sendPasswordResetOtp(to: string, otp: string) {
    const mailOptions = {
      from: `"CuanBuddy Support" <${this.configService.get<string>('SMTP_USER') || 'no-reply@cuanbuddy.com'}>`,
      to,
      subject: 'Password Reset OTP - CuanBuddy',
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Password Reset Request</h2>
          <p>We received a request to reset your CuanBuddy password.</p>
          <p>Your One-Time Password (OTP) is:</p>
          <div style="background-color: #f3f4f6; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; border-radius: 8px; margin: 20px 0;">
            ${otp}
          </div>
          <p>This code will expire in 15 minutes. If you did not request a password reset, please ignore this email.</p>
        </div>
      `,
    };

    await this.sendMailOrLog(mailOptions);
  }
}
