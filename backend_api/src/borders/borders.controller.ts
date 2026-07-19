import { Controller, Get, Req } from '@nestjs/common';
import type { Request } from 'express';

@Controller('borders')
export class BordersController {
  
  private getBaseUrl(req: Request): string {
    return `${req.protocol}://${req.get('host')}`;
  }

  @Get('avatars')
  getAvatarBorders(@Req() req: Request) {
    const baseUrl = this.getBaseUrl(req);
    return [
      {
        id: 'none',
        label: 'Tanpa Bingkai',
        asset: '',
        tier: 'none',
        requirementDescription: '',
        isGlobal: true,
      },
      {
        id: 'border-legend',
        label: 'Cuan Legend',
        asset: `${baseUrl}/assets/borders/border-legend.png`,
        tier: 'platinum',
        requirementDescription: 'Aktif menggunakan Cuan Buddy selama 1 tahun penuh sejak bergabung.',
        isGlobal: false,
      }
    ];
  }

  @Get('banners')
  getBannerBorders(@Req() req: Request) {
    const baseUrl = this.getBaseUrl(req);
    return [
      {
        id: 'none',
        label: 'Tanpa Bingkai',
        asset: '',
        tier: 'none',
        requirementDescription: '',
        isGlobal: true,
      },
      {
        id: 'border-legend',
        label: 'Cuan Legend (Banner)',
        asset: `${baseUrl}/assets/banners/banner-legend.png`,
        tier: 'platinum',
        requirementDescription: 'Aktif menggunakan Cuan Buddy selama 1 tahun penuh sejak bergabung.',
        isGlobal: false,
      }
    ];
  }
}
