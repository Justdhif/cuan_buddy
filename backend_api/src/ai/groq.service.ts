import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Groq from 'groq-sdk';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

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

  /**
   * Transcribe an audio file to text using Groq Whisper model.
   */
  async transcribeAudio(buffer: Buffer, originalName: string): Promise<string> {
    // Write buffer to a temp file since the SDK expects a stream/file
    const ext = path.extname(originalName) || '.m4a';
    const tempFileName = `audio_${Date.now()}_${Math.random().toString(36).substring(7)}${ext}`;
    const tempFilePath = path.join(os.tmpdir(), tempFileName);
    fs.writeFileSync(tempFilePath, buffer);
    
    try {
      const response = await this.client.audio.transcriptions.create({
        file: fs.createReadStream(tempFilePath),
        model: 'whisper-large-v3',
      });
      return response.text ?? '';
    } finally {
      if (fs.existsSync(tempFilePath)) {
        fs.unlinkSync(tempFilePath);
      }
    }
  }

  /**
   * Process an image using Groq Vision Model
   */
  async processImage(
    imageBuffer: Buffer,
    mimeType: string,
    prompt: string,
  ): Promise<string> {
    const base64Image = imageBuffer.toString('base64');
    const dataUrl = `data:${mimeType};base64,${base64Image}`;

    const response = await this.client.chat.completions.create({
      model: 'meta-llama/llama-4-scout-17b-16e-instruct',
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: prompt },
            {
              type: 'image_url',
              image_url: {
                url: dataUrl,
              },
            },
          ],
        },
      ],
      temperature: 0.2, // Lower temperature for more deterministic data extraction
      max_tokens: 1024,
    });
    return response.choices[0]?.message?.content ?? '';
  }
}
