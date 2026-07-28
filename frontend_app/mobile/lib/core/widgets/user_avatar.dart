
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

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

  final double size;

  final String? avatarUrl;

  final File? localFile;

  final String fallbackName;

  final VoidCallback? onTap;

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
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(size),
    );
  }

  Widget _buildImage(double imgSize) {

    if (localFile != null) {
      return Image.file(
        localFile!,
        width: imgSize,
        height: imgSize,
        fit: BoxFit.cover,
      );
    }

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

    return _buildFallback(imgSize);
  }

  Widget _buildSkeleton(double imgSize) {
    return Container(
      width: imgSize,
      height: imgSize,
      color: AppColors.primary,
      child: Center(
        child: SizedBox(
          width: imgSize * 0.3,
          height: imgSize * 0.3,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(double imgSize) {
    final initial = fallbackName.isNotEmpty
        ? fallbackName.trim()[0].toUpperCase()
        : '?';

    return Container(
      width: imgSize,
      height: imgSize,
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: imgSize * 0.38,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
