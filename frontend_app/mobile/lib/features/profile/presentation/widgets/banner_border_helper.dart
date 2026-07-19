import '../../../../core/constants/app_constants.dart';
import 'avatar_border_helper.dart' show BorderTier;

const String kBannerBorderPrefKey = 'selected_banner_border';

class BannerBorderInfo {
  const BannerBorderInfo({
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
  final BorderTier tier;
  final String requirementDescription;
  final bool isGlobal;

  bool get hasAsset => asset.isNotEmpty;
  bool get isNone => id == 'none';
}

const List<BannerBorderInfo> kGlobalBannerBorders = [
  BannerBorderInfo(
    id: 'none',
    label: 'Tanpa Bingkai',
    asset: '',
    tier: BorderTier.none,
    requirementDescription: '',
    isGlobal: true,
  ),
];

final List<BannerBorderInfo> kAchievementBannerBorders = [
  BannerBorderInfo(
    id: 'border-legend',
    label: 'Cuan Legend (Banner)',
    asset: '${AppConstants.baseUrl.replaceAll('/api', '')}/assets/banners/banner-legend.png',
    tier: BorderTier.platinum,
    requirementDescription: 'Aktif menggunakan Cuan Buddy selama 1 tahun penuh sejak bergabung.',
  ),
];

List<BannerBorderInfo> get kAllBannerBorders => [...kGlobalBannerBorders, ...kAchievementBannerBorders];

BannerBorderInfo bannerBorderInfoFromId(String? id) {
  if (id == null || id.isEmpty) return kGlobalBannerBorders.first;
  return kAllBannerBorders.firstWhere(
    (b) => b.id == id,
    orElse: () => kGlobalBannerBorders.first,
  );
}

String bannerBorderAssetFromId(String? id) => bannerBorderInfoFromId(id).asset;

class BannerWallpaperInfo {
  const BannerWallpaperInfo({
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
  final BorderTier tier;
  final String requirementDescription;
  final bool isGlobal;

  bool get isNone => id == 'none';
}

const List<BannerWallpaperInfo> kGlobalWallpapers = [
  BannerWallpaperInfo(
    id: 'none',
    label: 'Tanpa Wallpaper',
    asset: '',
    tier: BorderTier.none,
    requirementDescription: '',
    isGlobal: true,
  ),
];

final List<BannerWallpaperInfo> kAchievementWallpapers = [
  BannerWallpaperInfo(
    id: 'border-legend',
    label: 'Cuan Legend (Wallpaper)',
    asset: '${AppConstants.baseUrl.replaceAll('/api', '')}/assets/wallpapers/banners/wallpaper-banner-legend.png',
    tier: BorderTier.platinum,
    requirementDescription: 'Aktif menggunakan Cuan Buddy selama 1 tahun penuh sejak bergabung.',
  ),
];

List<BannerWallpaperInfo> get kAllWallpapers => [...kGlobalWallpapers, ...kAchievementWallpapers];
