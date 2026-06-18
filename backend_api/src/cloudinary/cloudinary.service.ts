import { Injectable } from '@nestjs/common';
import { v2 as cloudinary, UploadApiResponse, UploadApiErrorResponse } from 'cloudinary';
import { Readable } from 'stream';

@Injectable()
export class CloudinaryService {
  async uploadImage(
    file: Express.Multer.File,
  ): Promise<UploadApiResponse | UploadApiErrorResponse> {
    return new Promise((resolve, reject) => {
      const upload = cloudinary.uploader.upload_stream(
        {
          folder: 'cuan_buddy_avatars',
          transformation: [{ width: 400, height: 400, crop: 'fill', gravity: 'face' }],
        },
        (error, result) => {
          if (error) return reject(error);
          if (!result) return reject(new Error('No result from cloudinary'));
          resolve(result);
        },
      );
      Readable.from(file.buffer).pipe(upload);
    });
  }
}
