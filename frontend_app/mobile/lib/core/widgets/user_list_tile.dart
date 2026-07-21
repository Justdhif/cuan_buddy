import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'user_avatar.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.name,
    this.username,
    this.avatarUrl,
    this.avatarBorderAsset = '',
    this.listBackground,
    this.heroTag,
    this.actionWidget,
    this.onTap,
    this.isDark = false,
  });

  final String name;
  final String? username;
  final String? avatarUrl;
  final String avatarBorderAsset;
  final String? listBackground;
  final String? heroTag;
  final Widget? actionWidget;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme;
    final hasBackground = listBackground != null && listBackground!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: hasBackground ? null : (isDark ? AppColors.surfaceDark : Colors.white),
          image: hasBackground
              ? DecorationImage(
                  image: listBackground!.startsWith('http')
                      ? CachedNetworkImageProvider(listBackground!) as ImageProvider
                      : AssetImage(listBackground!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.65), // Darken the wallpaper so text is readable
                    BlendMode.darken,
                  ),
                )
              : null,
          boxShadow: hasBackground
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (heroTag != null)
              Hero(
                tag: heroTag!,
                child: _buildAvatar(),
              )
            else
              _buildAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (username != null && username!.isNotEmpty) ...[
                    Text(
                      '@$username',
                      style: textTheme.bodySmall?.copyWith(
                        color: hasBackground ? AppColors.primaryLight : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    name,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: hasBackground ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (actionWidget != null) ...[
              const SizedBox(width: 12),
              actionWidget!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return UserAvatar(
      size: 52,
      borderAsset: avatarBorderAsset,
      avatarUrl: avatarUrl,
      fallbackName: name,
    );
  }
}
