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

      if (file.buffer) {
        Readable.from(file.buffer).pipe(upload);
      } else if (file.stream) {
        file.stream.pipe(upload);
      } else if (file.path) {
        const fs = require('fs');
        fs.createReadStream(file.path).pipe(upload);
      } else {
        reject(new Error('File buffer, stream, and path are all missing'));
      }
    });
  }
}
