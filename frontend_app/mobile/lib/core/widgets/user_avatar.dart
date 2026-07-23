/// Widget reusable untuk menampilkan avatar pengguna dengan bingkai (border) dekoratif.
///
/// Fitur:
///  - Mendukung foto dari URL jaringan (CachedNetworkImage), file lokal, dan initial huruf
///  - Overlay border PNG yang melingkar di atas avatar
///  - Fallback elegan dengan initial nama jika foto tidak tersedia
///  - Ukuran avatar selalu proporsional terhadap ukuran total widget
///
/// Cara penggunaan paling sederhana:
/// ```dart
/// UserAvatar(
///   size: 80,
///   avatarUrl: profile['avatar'],
///   borderAsset: borderAssetFromId(profile['avatarBorder']),
///   fallbackName: profile['displayName'] ?? 'U',
/// )
/// ```
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

/// Widget avatar bulat (lingkaran) yang mendukung overlay bingkai dekoratif.
///
/// Parameter:
/// - [size]         : Ukuran total widget (width & height) dalam logical pixels.
/// - [avatarUrl]    : URL foto profil dari server (optional).
/// - [localFile]    : File lokal jika foto baru dipilih dari galeri (optional).
/// - [fallbackName] : Teks (nama / huruf) yang ditampilkan jika tidak ada foto.
/// - [borderAsset]  : Path asset PNG bingkai. Kosong string ('') = tanpa bingkai.
/// - [onTap]        : Callback saat widget ditekan (optional).
/// - [heroTag]      : Tag untuk animasi Hero (optional).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.size,
    this.avatarUrl,
    this.localFile,
    this.fallbackName = '?',
    this.borderAsset = '',
    this.backAsset,
    this.wingsAsset,
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

  /// Path asset PNG bingkai overlay. Kosongkan ('') jika tidak ingin bingkai.
  final String borderAsset;
  final String? backAsset;
  final String? wingsAsset;

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
    final hasBorder = borderAsset.isNotEmpty;
    final effectiveWings = (wingsAsset != null && wingsAsset!.isNotEmpty)
        ? wingsAsset
        : (backAsset != null && backAsset!.isNotEmpty ? backAsset : null);
    final hasWings = effectiveWings != null;

    const double avatarRatio = 600 / 1024;
    const double kBorderYOffset = 19.5 / 1024; 
    final double avatarSize = size * avatarRatio;
    final double borderOffset = size * kBorderYOffset;

    Widget buildWingsWidget() {
      return Positioned(
        top: -borderOffset,
        left: 0,
        right: 0,
        bottom: borderOffset,
        child: IgnorePointer(
          child: effectiveWings!.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: effectiveWings,
                  fit: BoxFit.fill,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                )
              : Image.asset(
                  effectiveWings,
                  fit: BoxFit.fill,
                ),
        ),
      );
    }

    if (!hasBorder) {
      final double ringStroke = (avatarSize * 0.05).clamp(1.5, 3.5);
      final double ringGap    = (avatarSize * 0.02).clamp(1.0, 2.5);
      final double ringWidget = avatarSize + (ringGap + ringStroke) * 2;

      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasWings) buildWingsWidget(),
            SizedBox(
              width: ringWidget,
              height: ringWidget,
              child: CustomPaint(
                painter: _GradientRingPainter(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
                  ),
                  strokeWidth: ringStroke,
                ),
              ),
            ),
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImage(avatarSize),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (hasWings) buildWingsWidget(),

              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImage(avatarSize),
              ),

              Positioned(
                top: -borderOffset,
                left: 0,
                right: 0,
                bottom: borderOffset,
                child: IgnorePointer(
                  child: borderAsset.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: borderAsset,
                          fit: BoxFit.fill,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        )
                      : Image.asset(
                          borderAsset,
                          fit: BoxFit.fill,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
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

// ─── Gradient Ring Painter ───────────────────────────────────────────────────────────────────
/// Melukis lingkaran ring dengan gradient warna tema.
/// Digunakan saat avatar tidak menggunakan border PNG dekoratif.
class _GradientRingPainter extends CustomPainter {
  const _GradientRingPainter({
    required this.gradient,
    required this.strokeWidth,
  });

  final LinearGradient gradient;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect   = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    final paint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round
      ..shader      = gradient.createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) =>
      old.gradient != gradient || old.strokeWidth != strokeWidth;
}
