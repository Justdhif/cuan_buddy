import { Provider } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';

export const CLOUDINARY = 'Cloudinary';

export const CloudinaryProvider: Provider = {
  provide: CLOUDINARY,
  useFactory: () => {
    if (process.env.CLOUDINARY_URL) {
      cloudinary.config(true);
    }
    return cloudinary;
  },
};
