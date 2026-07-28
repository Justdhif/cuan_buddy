import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/profile_provider.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/user_banner.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: Navigator.of(context).canPop() ? 0 : 20,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: _buildProfileContent(context, ref, profileAsync, isDark),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>> profileAsync,
    bool isDark,
  ) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
      child: Column(
        children: [
          profileAsync.when(
            data: (profile) => _buildProfileHeader(context, profile),
            loading: () => _buildProfileHeaderSkeleton(context),
            error: (_, __) => _buildProfileHeaderError(context, ref),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 12),

          profileAsync.when(
            data: (profile) {
              final fullName = profile['fullName'] as String? ?? '';
              final username = profile['username'] as String? ?? '';
              final bio = profile['bio'] as String? ?? '';
              final rawBirthdate = profile['birthDate'] as String? ??
                  profile['birthdate'] as String? ??
                  '';
              final gender = profile['gender'] as String?;
              final instagram = profile['instagram'] as String? ??
                  profile['socialLink'] as String? ??
                  '';

              final l10n = AppLocalizations.of(context);

              String birthdateDisplay = '';
              if (rawBirthdate.isNotEmpty) {
                try {
                  final date = DateTime.parse(rawBirthdate);
                  birthdateDisplay =
                      '${date.day} ${l10n.shortMonths[date.month - 1]} ${date.year}';
                } catch (_) {
                  birthdateDisplay = rawBirthdate;
                }
              }

              String genderDisplay = '';
              if (gender == 'male') {
                genderDisplay = l10n.genderMale;
              } else if (gender == 'female') {
                genderDisplay = l10n.genderFemale;
              }

              final fallback = l10n.notSet;

              return Column(
                children: [
                  _buildInfoTile(
                    context: context,
                    icon: Icons.wallpaper_rounded,
                    title: l10n.languageCode == 'id' ? 'Wallpaper List Card' : 'Wallpaper List Card',
                    subtitle: profile['listBackground'] != null ? (l10n.languageCode == 'id' ? 'Wallpaper Aktif' : 'Active Wallpaper') : fallback,
                    onTap: () =>
                        context.push('/profile/edit-list-background', extra: profile),
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.badge_outlined,
                    title: l10n.languageCode == 'id' ? 'Nama Lengkap' : 'Full Name',
                    subtitle: fullName.isNotEmpty ? fullName : fallback,
                    onTap: () =>
                        context.push('/profile/edit-name', extra: profile),
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.alternate_email_rounded,
                    title: 'Username',
                    subtitle:
                        username.isNotEmpty ? '@$username' : fallback,
                    onTap: () => context.push('/profile/edit-username',
                        extra: profile),
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.notes_rounded,
                    title: 'Bio',
                    subtitle: bio.isNotEmpty ? bio : fallback,
                    onTap: () =>
                        context.push('/profile/edit-bio', extra: profile),
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.link_rounded,
                    title: 'Instagram / Social',
                    subtitle: instagram.isNotEmpty ? instagram : fallback,
                    onTap: () =>
                        context.push('/profile/edit-link', extra: profile),
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.cake_outlined,
                    title: l10n.languageCode == 'id' ? 'Tanggal Lahir' : 'Birthdate',
                    subtitle: birthdateDisplay.isNotEmpty
                        ? birthdateDisplay
                        : fallback,
                    onTap: () => context.push('/profile/edit-birthdate',
                        extra: profile),
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.person_outline,
                    title: l10n.languageCode == 'id' ? 'Jenis Kelamin' : 'Gender',
                    subtitle:
                        genderDisplay.isNotEmpty ? genderDisplay : fallback,
                    onTap: () => context.push('/profile/edit-gender',
                        extra: profile),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, Map<String, dynamic> profile) {
    final l10n = AppLocalizations.of(context);
    final name = profile['fullName'] as String? ?? l10n.you;
    final avatar = profile['avatar'] as String?;
    final username = profile['username'] as String?;
    final bio = profile['bio'] as String?;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final bannerType = profile['bannerType'] as String? ?? 'color';
    final bannerColor = profile['bannerColor'] as String? ?? '#6C63FF';
    final bannerImage = profile['bannerImage'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [

              GestureDetector(
                onTap: () => context.push('/profile/edit-banner', extra: profile),
                child: Stack(
                  children: [
                    UserBanner(
                      bannerColor: bannerColor,
                      bannerType: bannerType,
                      bannerImage: bannerImage,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: -50,
                left: 16,
                child: GestureDetector(
                  onTap: () => context.push('/profile/edit-photo', extra: profile),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Hero(
                        tag: 'avatar',
                        child: UserAvatar(
                          size: 110,
                          avatarUrl: avatar,
                          fallbackName: name,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
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
              const SizedBox(height: 8),
              (bio != null && bio.isNotEmpty)
                  ? Text(
                      bio,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    )
                  : Text(
                      l10n.noBioFallback,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                            : AppColors.textSecondaryLight
                                .withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white60 : Colors.black54,
              size: 22,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
      highlightColor:
          isDark ? const Color(0xFF4A5568) : const Color(0xFFF7FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AspectRatio(
                  aspectRatio: 2.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: 16,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 24,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderError(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.danger.withValues(alpha: 0.1),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.failedToLoadProfile,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => ref.invalidate(profileProvider),
                  child: Text(
                    'Tap to retry',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
