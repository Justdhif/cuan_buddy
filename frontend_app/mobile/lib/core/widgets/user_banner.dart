import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserBanner extends StatelessWidget {
  const UserBanner({
    super.key,
    required this.bannerColor,
    this.bannerType = 'color',
    this.bannerImage,
    this.localFile,
  });

  final String bannerColor;
  final String bannerType;
  final String? bannerImage;
  final dynamic localFile;

  Color _parseHexColor(String hexColor) {
    try {
      final cleanHex = hexColor.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF6C63FF);
  }

  @override
  Widget build(BuildContext context) {
    final parsedBannerColor = _parseHexColor(bannerColor);

    return AspectRatio(
      aspectRatio: 2.5,
      child: Container(
        decoration: BoxDecoration(
          color: parsedBannerColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildBannerContent(parsedBannerColor),
      ),
    );
  }

  Widget? _buildBannerContent(Color parsedBannerColor) {
    if (localFile != null) {

      return Image.file(
        localFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (bannerType == 'image' && bannerImage != null && bannerImage!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: bannerImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        errorWidget: (_, __, ___) => Container(color: parsedBannerColor),
      );
    } else if (bannerType == 'image' && localFile == null && (bannerImage == null || bannerImage!.isEmpty)) {
      return Container(
        color: parsedBannerColor,
        child: const Center(
          child: Text(
            'No Image Selected',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return null;
  }
}
