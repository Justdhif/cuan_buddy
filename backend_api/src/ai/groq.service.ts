import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Groq from 'groq-sdk';

@Injectable()
export class GroqService {
  private readonly client: Groq;
  // Fast, capable model — good balance of quality and speed on Groq
  private readonly model = 'llama-3.3-70b-versatile';

  constructor(private readonly configService: ConfigService) {
    this.client = new Groq({
      apiKey: this.configService.get<string>('GROQ_API_TOKEN'),
    });
  }

  /**
   * Send messages to Groq and return the text response.
   * maxTokens kept low by default to minimize compute usage.
   */
  async chat(
    messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }>,
    maxTokens = 512,
  ): Promise<string> {
    const response = await this.client.chat.completions.create({
      model: this.model,
      messages,
      max_tokens: maxTokens,
      temperature: 0.5, // Lower temp = more deterministic, fewer retries
    });
    return response.choices[0]?.message?.content ?? '';
  }
}
