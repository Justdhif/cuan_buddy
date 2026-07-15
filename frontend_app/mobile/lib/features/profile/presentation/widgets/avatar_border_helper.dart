/// Shared config & utilities untuk sistem avatar border.
///
/// Untuk menambah border baru:
///   1. Taruh file PNG di `assets/borders/`
///   2. Tambah entry di [kAvailableBorders]
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';

const String kBorderPrefKey = 'selected_avatar_border';

/// Daftar semua border yang tersedia di aplikasi.
const List<Map<String, String>> kAvailableBorders = [
  {'id': 'none',     'label': 'None',     'asset': ''},
  {'id': 'border-1', 'label': 'Border 1', 'asset': 'assets/borders/border-1.png'},
  {'id': 'border-2', 'label': 'Border 2', 'asset': 'assets/borders/border-2.png'},
];

/// Mengembalikan asset path dari border ID.
/// Jika ID tidak ditemukan, mengembalikan string kosong (no border).
String borderAssetFromId(String? id) {
  if (id == null) return '';
  return kAvailableBorders
      .firstWhere(
        (b) => b['id'] == id,
        orElse: () => kAvailableBorders.first,
      )['asset']!;
}

/// Widget avatar dengan border overlay yang presisi.
///
/// Menampilkan foto profil user dengan border dekoratif di atasnya.
/// Border PNG di-overlay di atas avatar, dengan Stack yang cukup besar
/// agar dekorasi border tidak terpotong.
///
/// [size] adalah ukuran total widget termasuk border.
/// [borderAsset] adalah path asset border PNG, kosong jika tidak ada border.
/// [avatarUrl] adalah URL network image avatar.
/// [localFile] adalah File lokal jika user baru memilih dari galeri.
/// [fallbackName] digunakan untuk menampilkan initial huruf jika tidak ada avatar.
class AvatarWithBorder extends StatelessWidget {
  const AvatarWithBorder({
    super.key,
    required this.size,
    this.borderAsset = '',
    this.avatarUrl,
    this.localFile,
    this.fallbackName = '?',
  });

  final double size;
  final String borderAsset;
  final String? avatarUrl;
  final File? localFile;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final hasBorder = borderAsset.isNotEmpty;

    // Ukuran avatar selalu konstan (76% dari total size) baik saat ada border maupun tidak.
    // Hal ini agar posisi dan ukuran wajah tidak berubah atau membesar/mengecil.
    final double avatarSize = size * 0.76;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Avatar ──
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: ClipOval(
              child: _buildAvatarContent(avatarSize),
            ),
          ),

          // ── Border overlay ──
          if (hasBorder)
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  borderAsset,
                  fit: BoxFit.fill,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(double size) {
    if (localFile != null) {
      return Image.file(localFile!, width: size, height: size, fit: BoxFit.cover);
    }
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, __, ___) => _fallbackWidget(size),
      );
    }
    return _fallbackWidget(size);
  }

  Widget _fallbackWidget(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          fallbackName.isNotEmpty ? fallbackName[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}
