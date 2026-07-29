import { Controller, Post, Body, UseGuards, Req, BadRequestException } from '@nestjs/common';
import { FeedbackService } from './feedback.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { IsNotEmpty, IsOptional, IsString, IsNumber, Min, Max } from 'class-validator';

class CreateFeedbackDto {
  @IsString()
  @IsNotEmpty()
  message: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(5)
  rating?: number;

  @IsOptional()
  @IsString()
  deviceInfo?: string;

  @IsOptional()
  @IsString()
  appVersion?: string;
}

@UseGuards(JwtAuthGuard)
@Controller('feedback')
export class FeedbackController {
  constructor(private readonly feedbackService: FeedbackService) {}

  @Post()
  async createFeedback(@Req() req, @Body() body: CreateFeedbackDto) {
    if (!body.message || body.message.trim() === '') {
      throw new BadRequestException('Message is required');
    }
    return this.feedbackService.createFeedback(req.user.userId, {
      message: body.message,
      category: body.category,
      rating: body.rating,
      deviceInfo: body.deviceInfo,
      appVersion: body.appVersion,
    });
  }
}
