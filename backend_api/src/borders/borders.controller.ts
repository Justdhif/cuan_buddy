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
      },
      {
        id: 'border-500-tx',
        label: 'Cuan Master',
        asset: `${baseUrl}/assets/borders/border-500-tx.png`,
        tier: 'platinum',
        requirementDescription: 'Mencatat minimal 500 transaksi di Cuan Buddy.',
        isGlobal: false,
      },
      {
        id: 'border-millionaire',
        label: 'Cuan Millionaire',
        asset: `${baseUrl}/assets/borders/border-millionaire.png`,
        tier: 'platinum',
        requirementDescription: 'Mencapai status Cuan Millionaire di aplikasi Cuan Buddy.',
        isGlobal: false,
      },
      {
        id: 'border-billionaire',
        label: 'Cuan Billionaire',
        asset: `${baseUrl}/assets/borders/border-billionaire.png`,
        tier: 'platinum',
        requirementDescription: 'Mencapai total saldo Rp 1.000.000.000 di Cuan Buddy.',
        isGlobal: false,
      },
      {
        id: 'border-streak',
        label: 'Streak Master',
        asset: `${baseUrl}/assets/borders/border-streak.png`,
        tier: 'platinum',
        requirementDescription: 'Mencatat transaksi berturut-turut selama minimal 30 hari.',
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
      },
      {
        id: 'border-500-tx',
        label: 'Cuan Master (Banner)',
        asset: `${baseUrl}/assets/banners/banner-500-tx.png`,
        tier: 'platinum',
        requirementDescription: 'Mencatat minimal 500 transaksi di Cuan Buddy.',
        isGlobal: false,
      },
      {
        id: 'border-millionaire',
        label: 'Cuan Millionaire (Banner)',
        asset: `${baseUrl}/assets/banners/banner-millionaire.png?v=3`,
        tier: 'platinum',
        requirementDescription: 'Mencapai status Cuan Millionaire di aplikasi Cuan Buddy.',
        isGlobal: false,
      },
      {
        id: 'border-billionaire',
        label: 'Cuan Billionaire (Banner)',
        asset: `${baseUrl}/assets/banners/banner-billionaire.png?v=1`,
        tier: 'platinum',
        requirementDescription: 'Mencapai total saldo Rp 1.000.000.000 di Cuan Buddy.',
        isGlobal: false,
      },
      {
        id: 'border-streak',
        label: 'Streak Master (Banner)',
        asset: `${baseUrl}/assets/banners/banner-streak.png`,
        tier: 'platinum',
        requirementDescription: 'Mencatat transaksi berturut-turut selama minimal 30 hari.',
        isGlobal: false,
      }
    ];
  }
}
