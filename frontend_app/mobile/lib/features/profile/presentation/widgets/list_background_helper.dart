import 'package:flutter/material.dart';

enum WallpaperTier { none, bronze, silver, gold, platinum }

extension WallpaperTierX on WallpaperTier {
  Color get color {
    switch (this) {
      case WallpaperTier.none:     return Colors.grey;
      case WallpaperTier.bronze:   return const Color(0xFFCD7F32);
      case WallpaperTier.silver:   return const Color(0xFFC0C0C0);
      case WallpaperTier.gold:     return const Color(0xFFFFD700);
      case WallpaperTier.platinum: return const Color(0xFFE5E4E2);
    }
  }
}

class WallpaperInfo {
  const WallpaperInfo({
    required this.id,
    required this.label,
    required this.asset,
    required this.tier,
    required this.requirementDescription,
    this.isGlobal = false,
  });

  final String id;
  final String label;
  final String asset;
  final WallpaperTier tier;
  final String requirementDescription;
  final bool isGlobal;

  bool get isNone => id == 'none';
}

const List<WallpaperInfo> kGlobalWallpapers = [
  WallpaperInfo(
    id: 'none',
    label: 'Tanpa Wallpaper',
    asset: '',
    tier: WallpaperTier.none,
    requirementDescription: '',
    isGlobal: true,
  ),
];

final List<WallpaperInfo> kAchievementWallpapers = [
  WallpaperInfo(
    id: 'border-millionaire',
    label: 'Cuan Millionaire (Wallpaper)',
    asset: 'assets/wallpapers/banners/wallpaper-banner-millionaire.png',
    tier: WallpaperTier.platinum,
    requirementDescription: 'Mencapai status Cuan Millionaire di aplikasi Cuan Buddy.',
  ),
  WallpaperInfo(
    id: 'border-billionaire',
    label: 'Cuan Billionaire (Wallpaper)',
    asset: 'assets/wallpapers/banners/wallpaper-banner-billionaire.png',
    tier: WallpaperTier.platinum,
    requirementDescription: 'Mencapai total saldo Rp 1.000.000.000 di Cuan Buddy.',
  ),
  WallpaperInfo(
    id: 'border-all-completed',
    label: 'All Completed (Wallpaper)',
    asset: 'assets/wallpapers/banners/wallpaper-banner-all-completed.png',
    tier: WallpaperTier.platinum,
    requirementDescription: 'Menyelesaikan semua pencapaian di Cuan Buddy.',
  ),
];

List<WallpaperInfo> get kAllWallpapers => [...kGlobalWallpapers, ...kAchievementWallpapers];
