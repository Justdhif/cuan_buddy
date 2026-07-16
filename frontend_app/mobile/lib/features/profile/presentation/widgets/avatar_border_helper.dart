/// Shared config & utilities untuk sistem avatar border dengan achievement.
///
/// Untuk menambah border baru:
///   1. Taruh file PNG di `assets/borders/`
///   2. Tambah entry di [kAchievementBorders] dengan kondisi yang sesuai
library;

import 'package:flutter/material.dart';

// Widget avatar dipindahkan ke core/widgets/user_avatar.dart sebagai komponen reusable.
// Di-export dari sini agar semua file yang meng-import avatar_border_helper.dart
// otomatis mendapat akses ke UserAvatar dan AvatarWithBorder tanpa perubahan import.
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
    required this.tier,
    required this.requirementDescription,
    this.isGlobal = false,
  });

  /// ID unik border, disimpan di backend.
  final String id;

  /// Nama display border.
  final String label;

  /// Path asset PNG, kosong jika tidak ada border.
  final String asset;

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
    id: 'border-1',
    label: 'Border 1',
    asset: 'assets/borders/border-1.png',
    tier: BorderTier.none,
    requirementDescription: '',
    isGlobal: true,
  ),
  AvatarBorderInfo(
    id: 'border-2',
    label: 'Border 2',
    asset: 'assets/borders/border-2.png',
    tier: BorderTier.none,
    requirementDescription: '',
    isGlobal: true,
  ),
];

// ─── Daftar Border Achievement (Harus Di-unlock) ──────────────────────────────

const List<AvatarBorderInfo> kAchievementBorders = [
  AvatarBorderInfo(
    id: 'border-rookie',
    label: 'Cuan Rookie',
    asset: 'assets/borders/border-rookie.png',
    tier: BorderTier.bronze,
    requirementDescription: 'Dibuka otomatis untuk semua pengguna Cuan Buddy. Selamat datang!',
  ),
  AvatarBorderInfo(
    id: 'border-first-goal',
    label: 'Goal Achiever',
    asset: 'assets/borders/border-first-goal.png',
    tier: BorderTier.silver,
    requirementDescription: 'Selesaikan 1 saving goal pertamamu.',
  ),
  AvatarBorderInfo(
    id: 'border-cuan-planner',
    label: 'Cuan Planner',
    asset: 'assets/borders/border-cuan-planner.png',
    tier: BorderTier.silver,
    requirementDescription: 'Miliki minimal 3 saving goals aktif secara bersamaan.',
  ),
  AvatarBorderInfo(
    id: 'border-cuan-partner',
    label: 'Cuan Partner',
    asset: 'assets/borders/border-cuan-partner.png',
    tier: BorderTier.silver,
    requirementDescription: 'Selesaikan 1 tabungan bersama di Shared Room bersama teman.',
  ),
  AvatarBorderInfo(
    id: 'border-master-saver',
    label: 'Master Penabung',
    asset: 'assets/borders/border-master-saver.png',
    tier: BorderTier.gold,
    requirementDescription: 'Kumpulkan total tabungan ≥ Rp10.000.000 di seluruh saving goals.',
  ),
  AvatarBorderInfo(
    id: 'border-budget-master',
    label: 'Budget Master',
    asset: 'assets/borders/border-budget-master.png',
    tier: BorderTier.gold,
    requirementDescription: 'Jaga pengeluaran di bawah batas anggaran selama 3 bulan berturut-turut.',
  ),
  AvatarBorderInfo(
    id: 'border-tracker-pro',
    label: 'Financial Tracker Pro',
    asset: 'assets/borders/border-tracker-pro.png',
    tier: BorderTier.gold,
    requirementDescription: 'Gunakan Cuan Buddy aktif selama 6 bulan sejak bergabung.',
  ),
  AvatarBorderInfo(
    id: 'border-consistency',
    label: 'Disiplin Cuan',
    asset: 'assets/borders/border-consistency.png',
    tier: BorderTier.gold,
    requirementDescription: 'Catat transaksi setiap hari tanpa putus selama 30 hari berturut-turut.',
  ),
  AvatarBorderInfo(
    id: 'border-cuan-emperor',
    label: 'Cuan Emperor',
    asset: 'assets/borders/border-cuan-emperor.png',
    tier: BorderTier.platinum,
    requirementDescription: 'Selesaikan 5+ saving goals DAN miliki 3+ saving goals aktif.',
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
