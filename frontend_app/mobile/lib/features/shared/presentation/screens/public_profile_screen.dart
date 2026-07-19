import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/widgets/avatar_border_helper.dart';
import '../../../profile/presentation/widgets/banner_border_helper.dart';
import '../../../../core/widgets/user_banner.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final name = user['fullName'] as String? ?? user['username'] as String? ?? 'User';
    final avatar = user['avatar'] as String?;
    final avatarBorderId = user['avatarBorder'] as String?;
    final borderAsset = borderAssetFromId(avatarBorderId);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final username = user['username'] as String?;
    final bio = user['bio'] as String?;

    final bannerType = user['bannerType'] as String? ?? 'color';
    final bannerColor = user['bannerColor'] as String? ?? '#6C63FF';
    final bannerImage = user['bannerImage'] as String?;
    final bannerBorderId = user['bannerBorder'] as String? ?? 'none';
    final bannerBorderAsset = bannerBorderAssetFromId(bannerBorderId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  UserBanner(
                    bannerColor: bannerColor,
                    bannerType: bannerType,
                    bannerImage: bannerImage,
                    borderAsset: bannerBorderAsset,
                  ),
                  Positioned(
                    bottom: -80,
                    left: 16,
                    child: Hero(
                      tag: 'avatar_${user['email'] ?? user['id'] ?? username}',
                      child: UserAvatar(
                        size: 160,
                        borderAsset: borderAsset,
                        avatarUrl: avatar,
                        fallbackName: name,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 90),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (username != null && username.isNotEmpty)
                    Text(
                      '@$username',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    name,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: (bio != null && bio.isNotEmpty)
                  ? Text(
                      bio,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    )
                  : Text(
                      'Belum ada bio',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                            : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 24),
            // Statistics or other info can go here in the future
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Anggota Cuan Buddy',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
