import { Controller, Post, Body, UseGuards, Req, BadRequestException } from '@nestjs/common';
import { FeedbackService } from './feedback.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { IsNotEmpty, IsString } from 'class-validator';

class CreateFeedbackDto {
  @IsString()
  @IsNotEmpty()
  message: string;
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
    return this.feedbackService.createFeedback(req.user.userId, body.message);
  }
}
