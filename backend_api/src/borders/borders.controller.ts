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
        id: 'border-profile-completed',
        label: 'Bronze: Profile Completed',
        asset: `assets/borders/border-profile-completed.png`,
        tier: 'bronze',
        requirementDescription: 'Telah melengkapi semua data profil.',
        isGlobal: false,
      },
      {
        id: 'border-millionaire',
        label: 'Cuan Millionaire',
        asset: `assets/borders/border-millionaire.png`,
        tier: 'platinum',
        requirementDescription: 'Mencapai status Cuan Millionaire di aplikasi Cuan Buddy.',
        isGlobal: false,
      },
      {
        id: 'border-billionaire',
        label: 'Cuan Billionaire',
        asset: `assets/borders/border-billionaire.png`,
        tier: 'platinum',
        requirementDescription: 'Mencapai total saldo Rp 1.000.000.000 di Cuan Buddy.',
        isGlobal: false,
      },
      {
        id: 'border-streak',
        label: 'Streak Master',
        asset: `assets/borders/border-streak.png`,
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
        id: 'border-millionaire',
        label: 'Cuan Millionaire (Banner)',
        asset: `assets/banners/banner-millionaire.png`,
        tier: 'platinum',
        requirementDescription: 'Mencapai status Cuan Millionaire di aplikasi Cuan Buddy.',
        isGlobal: false,
      },
      {
        id: 'border-billionaire',
        label: 'Cuan Billionaire (Banner)',
        asset: `assets/banners/banner-billionaire.png`,
        tier: 'platinum',
        requirementDescription: 'Mencapai total saldo Rp 1.000.000.000 di Cuan Buddy.',
        isGlobal: false,
      },
      {
        id: 'border-streak',
        label: 'Streak Master (Banner)',
        asset: `assets/banners/banner-streak.png`,
        tier: 'platinum',
        requirementDescription: 'Mencatat transaksi berturut-turut selama minimal 30 hari.',
        isGlobal: false,
      }
    ];
  }
}







