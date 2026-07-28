import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Groq from 'groq-sdk';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

@Injectable()
export class GroqService {
  private readonly logger = new Logger(GroqService.name);
  private readonly client: Groq;

  private readonly defaultTextModel: string;
  private readonly defaultVisionModel: string;
  private readonly defaultAudioModel: string;

  constructor(private readonly configService: ConfigService) {
    this.client = new Groq({
      apiKey: this.configService.get<string>('GROQ_API_TOKEN'),
    });

    this.defaultTextModel =
      this.configService.get<string>('GROQ_MODEL') || 'llama-3.3-70b-versatile';
    this.defaultVisionModel =
      this.configService.get<string>('GROQ_VISION_MODEL') || 'qwen/qwen3.6-27b';
    this.defaultAudioModel =
      this.configService.get<string>('GROQ_AUDIO_MODEL') || 'whisper-large-v3-turbo';
  }

  async chat(
    messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }>,
    maxTokens = 512,
  ): Promise<string> {
    const primaryModel = this.defaultTextModel;
    try {
      const response = await this.client.chat.completions.create({
        model: primaryModel,
        messages,
        max_tokens: maxTokens,
        temperature: 0.5,
      });
      return response.choices[0]?.message?.content ?? '';
    } catch (err: any) {
      this.logger.warn(
        `Primary text model (${primaryModel}) failed: ${err?.message}. Trying fallback 'llama-3.1-8b-instant'...`,
      );
      try {
        const fallbackResponse = await this.client.chat.completions.create({
          model: 'llama-3.1-8b-instant',
          messages,
          max_tokens: maxTokens,
          temperature: 0.5,
        });
        return fallbackResponse.choices[0]?.message?.content ?? '';
      } catch (fallbackErr: any) {
        this.logger.error(`Fallback model also failed: ${fallbackErr?.message}`);
        throw fallbackErr;
      }
    }
  }

  /**
   * Transcribe an audio file to text using Groq Whisper model.
   */
  async transcribeAudio(buffer: Buffer, originalName: string): Promise<string> {
    const ext = path.extname(originalName) || '.m4a';
    const tempFileName = `audio_${Date.now()}_${Math.random().toString(36).substring(7)}${ext}`;
    const tempFilePath = path.join(os.tmpdir(), tempFileName);
    fs.writeFileSync(tempFilePath, buffer);

    try {
      const audioModel = this.defaultAudioModel;
      try {
        const response = await this.client.audio.transcriptions.create({
          file: fs.createReadStream(tempFilePath),
          model: audioModel,
        });
        return response.text ?? '';
      } catch (err: any) {
        this.logger.warn(
          `Primary audio model (${audioModel}) failed: ${err?.message}. Trying 'whisper-large-v3'...`,
        );
        const fallbackResponse = await this.client.audio.transcriptions.create({
          file: fs.createReadStream(tempFilePath),
          model: 'whisper-large-v3',
        });
        return fallbackResponse.text ?? '';
      }
    } finally {
      if (fs.existsSync(tempFilePath)) {
        fs.unlinkSync(tempFilePath);
      }
    }
  }

  /**
   * Process an image using Groq Vision Model.
   * Replaces decommissioned 'Llama 4 Scout 17B' with Groq recommended 'qwen/qwen3.6-27b' or 'llama-3.2-11b-vision-preview'.
   */
  async processImage(
    imageBuffer: Buffer,
    mimeType: string,
    prompt: string,
  ): Promise<string> {
    const base64Image = imageBuffer.toString('base64');
    const dataUrl = `data:${mimeType};base64,${base64Image}`;

    const visionModel = this.defaultVisionModel;

    try {
      const response = await this.client.chat.completions.create({
        model: visionModel,
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
        temperature: 0.2,
        max_tokens: 1024,
      });
      return response.choices[0]?.message?.content ?? '';
    } catch (err: any) {
      this.logger.warn(
        `Primary vision model (${visionModel}) failed: ${err?.message}. Trying fallback 'llama-3.2-11b-vision-preview'...`,
      );
      try {
        const fallbackResponse = await this.client.chat.completions.create({
          model: 'llama-3.2-11b-vision-preview',
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
          temperature: 0.2,
          max_tokens: 1024,
        });
        return fallbackResponse.choices[0]?.message?.content ?? '';
      } catch (fallbackErr: any) {
        this.logger.error(`All vision fallback models failed: ${fallbackErr?.message}`);
        throw fallbackErr;
      }
    }
  }
}
