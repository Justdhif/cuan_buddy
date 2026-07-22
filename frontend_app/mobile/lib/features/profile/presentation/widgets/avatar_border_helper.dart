library;

import 'package:flutter/material.dart';
import '../../../../core/widgets/user_avatar.dart';
export '../../../../core/widgets/user_avatar.dart' show UserAvatar;

const String kBorderPrefKey = 'selected_avatar_border';

// ─── Tier System ─────────────────────────────────────────────────────────────

enum BorderTier { none, bronze, silver, gold, platinum }

extension BorderTierX on BorderTier {
  Color get color {
    switch (this) {
      case BorderTier.none:     return Colors.grey;
      case BorderTier.bronze:   return const Color(0xFFCD7F32);
      case BorderTier.silver:   return const Color(0xFFC0C0C0);
      case BorderTier.gold:     return const Color(0xFFFFD700);
      case BorderTier.platinum: return const Color(0xFFE5E4E2);
    }
  }

  String get label {
    switch (this) {
      case BorderTier.none:     return '';
      case BorderTier.bronze:   return 'Bronze';
      case BorderTier.silver:   return 'Silver';
      case BorderTier.gold:     return 'Gold';
      case BorderTier.platinum: return 'Platinum';
    }
  }

  IconData get icon {
    switch (this) {
      case BorderTier.none:     return Icons.circle_outlined;
      case BorderTier.bronze:   return Icons.military_tech_outlined;
      case BorderTier.silver:   return Icons.military_tech;
      case BorderTier.gold:     return Icons.emoji_events_outlined;
      case BorderTier.platinum: return Icons.diamond_outlined;
    }
  }
}

// ─── Border Model ─────────────────────────────────────────────────────────────

class AvatarBorderInfo {
  const AvatarBorderInfo({
    required this.id,
    required this.label,
    required this.asset,
    this.backAsset,
    required this.tier,
    required this.requirementDescription,
    this.isGlobal = false,
  });

  /// ID unik border, disimpan di backend.
  final String id;

  /// Nama display border.
  final String label;

  /// URL asset PNG (dari backend), kosong jika tidak ada border.
  final String asset;
  final String? backAsset;

  /// Tier pencapaian border.
  final BorderTier tier;

  /// Deskripsi syarat untuk membuka border ini (ditampilkan di dialog locked).
  final String requirementDescription;

  /// Jika true, border selalu tersedia tanpa kondisi.
  final bool isGlobal;

  bool get hasAsset => asset.isNotEmpty;
  bool get isNone   => id == 'none';
}

// ─── Daftar Border Global (Selalu Tersedia) ───────────────────────────────────

const List<AvatarBorderInfo> kGlobalBorders = [
  AvatarBorderInfo(
    id: 'none',
    label: 'Tanpa Bingkai',
    asset: '',
    tier: BorderTier.none,
    requirementDescription: '',
    isGlobal: true,
  ),
  AvatarBorderInfo(
    id: 'border-all-completed',
    label: 'The Completionist',
    asset: 'assets/borders/border-all-completed.png',
    backAsset: 'assets/borders/wings.png',
    tier: BorderTier.platinum,
    requirementDescription: 'Membuka semua medali yang ada.',
  ),
];

// ─── Daftar Border Achievement (Harus Di-unlock) ──────────────────────────────

final List<AvatarBorderInfo> kAchievementBorders = [
  AvatarBorderInfo(
    id: 'border-profile-completed',
    label: 'Bronze: Profile Completed',
    asset: 'assets/borders/border-profile-completed.png',
    tier: BorderTier.bronze,
    requirementDescription: 'Telah melengkapi semua data profil.',
  ),
  AvatarBorderInfo(
    id: 'border-millionaire',
    label: 'Cuan Millionaire',
    asset: 'assets/borders/border-millionaire.png',
    tier: BorderTier.platinum,
    requirementDescription: 'Mencapai status Cuan Millionaire di aplikasi Cuan Buddy.',
  ),
  AvatarBorderInfo(
    id: 'border-billionaire',
    label: 'Cuan Billionaire',
    asset: 'assets/borders/border-billionaire.png',
    tier: BorderTier.platinum,
    requirementDescription: 'Mencapai total saldo Rp 1.000.000.000 di Cuan Buddy.',
  ),
  AvatarBorderInfo(
    id: 'border-all-completed',
    label: 'The Completionist',
    asset: 'assets/borders/border-all-completed.png',
    backAsset: 'assets/borders/wings.png',
    tier: BorderTier.platinum,
    requirementDescription: 'Membuka semua medali yang ada.',
  ),
];

/// Semua border digabung: global + achievement.
List<AvatarBorderInfo> get kAllBorders => [...kGlobalBorders, ...kAchievementBorders];

// ─── Helper Functions ─────────────────────────────────────────────────────────

/// Mengembalikan AvatarBorderInfo berdasarkan ID.
AvatarBorderInfo borderInfoFromId(String? id) {
  if (id == null || id.isEmpty) return kGlobalBorders.first;
  return kAllBorders.firstWhere(
    (b) => b.id == id,
    orElse: () => kGlobalBorders.first,
  );
}

/// Mengembalikan asset path dari border ID.
String borderAssetFromId(String? id) => borderInfoFromId(id).asset;

// ─── Alias backward-compatibility ────────────────────────────────────────────
/// [AvatarWithBorder] adalah alias lama. Gunakan [UserAvatar] untuk kode baru.
typedef AvatarWithBorder = UserAvatar;





