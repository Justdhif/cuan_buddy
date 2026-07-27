/// Widget reusable untuk menampilkan avatar pengguna.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

/// Widget avatar bulat (lingkaran).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.size,
    this.avatarUrl,
    this.localFile,
    this.fallbackName = '?',
    this.onTap,
    this.heroTag,
  });

  /// Ukuran total widget dalam logical pixels (width & height sama).
  final double size;

  /// URL foto profil dari server.
  final String? avatarUrl;

  /// File lokal foto profil (misalnya setelah user crop foto baru sebelum disimpan).
  final File? localFile;

  /// Nama atau teks fallback. Huruf pertama akan ditampilkan jika tidak ada foto.
  final String fallbackName;

  /// Callback ketika widget ditekan. Jika null, widget tidak interaktif.
  final VoidCallback? onTap;

  /// Tag unik untuk animasi Hero. Jika null, tidak menggunakan Hero.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget avatar = _buildCore();

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildCore() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(size),
    );
  }

  /// Membangun konten foto: lokal > URL > initial huruf.
  Widget _buildImage(double imgSize) {
    // 1. File lokal (baru dipilih dari galeri, belum di-upload)
    if (localFile != null) {
      return Image.file(
        localFile!,
        width: imgSize,
        height: imgSize,
        fit: BoxFit.cover,
      );
    }

    // 2. Foto dari URL server
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        width: imgSize,
        height: imgSize,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildSkeleton(imgSize),
        errorWidget: (_, __, ___) => _buildFallback(imgSize),
      );
    }

    // 3. Initial huruf (fallback)
    return _buildFallback(imgSize);
  }

  /// Skeleton loading placeholder sementara foto dimuat.
  Widget _buildSkeleton(double imgSize) {
    return Container(
      width: imgSize,
      height: imgSize,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: SizedBox(
          width: imgSize * 0.3,
          height: imgSize * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  /// Fallback: lingkaran dengan initial huruf pertama nama.
  Widget _buildFallback(double imgSize) {
    final initial = fallbackName.isNotEmpty
        ? fallbackName.trim()[0].toUpperCase()
        : '?';

    return Container(
      width: imgSize,
      height: imgSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.25),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: imgSize * 0.38,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
