import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'avatar_border_helper.dart';

class ProfileSetupStep1 extends StatelessWidget {
  const ProfileSetupStep1({
    super.key,
    required this.fullName,
    required this.username,
    required this.bio,
    required this.birthdateDisplay,
    required this.genderDisplay,
    required this.selectedAvatarUrl,
    required this.selectedLocalFile,
    required this.selectedBorderAsset,
    required this.fallback,
    required this.hintColor,
    required this.onAvatarEditTap,
    required this.onFullNameTap,
    required this.onUsernameTap,
    required this.onBioTap,
    required this.onBirthdateTap,
    required this.onGenderTap,
    required this.buildInfoTile,
  });

  final String fullName;
  final String username;
  final String bio;
  final String birthdateDisplay;
  final String genderDisplay;
  final String? selectedAvatarUrl;
  final File? selectedLocalFile;
  final String selectedBorderAsset;
  final String fallback;
  final Color hintColor;
  final VoidCallback onAvatarEditTap;
  final VoidCallback onFullNameTap;
  final VoidCallback onUsernameTap;
  final VoidCallback onBioTap;
  final VoidCallback onBirthdateTap;
  final VoidCallback onGenderTap;
  final Widget Function({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) buildInfoTile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Subtitle for Step 1
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.completeYourProfile,
                style: AppTypography.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.profileSetupSubtitle,
                style: AppTypography.textTheme.bodyLarge?.copyWith(color: hintColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Interactive Avatar Editor
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: onAvatarEditTap,
                child: UserAvatar(
                  size: 140,
                  borderAsset: selectedBorderAsset,
                  avatarUrl: selectedAvatarUrl,
                  localFile: selectedLocalFile,
                  fallbackName: fullName.isNotEmpty ? fullName : '?',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onAvatarEditTap,
                child: Text(
                  l10n.editPhoto,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        buildInfoTile(
          context: context,
          icon: Icons.person_outline_rounded,
          title: l10n.fullName,
          subtitle: fullName.isNotEmpty ? fullName : fallback,
          onTap: onFullNameTap,
        ),
        buildInfoTile(
          context: context,
          icon: Icons.alternate_email_rounded,
          title: 'Username',
          subtitle: username.isNotEmpty ? '@$username' : fallback,
          onTap: onUsernameTap,
        ),
        buildInfoTile(
          context: context,
          icon: Icons.info_outline_rounded,
          title: l10n.bioField,
          subtitle: bio.isNotEmpty ? bio : fallback,
          onTap: onBioTap,
        ),
        buildInfoTile(
          context: context,
          icon: Icons.cake_outlined,
          title: l10n.dateOfBirth,
          subtitle: birthdateDisplay,
          onTap: onBirthdateTap,
        ),
        buildInfoTile(
          context: context,
          icon: Icons.wc_outlined,
          title: l10n.genderField,
          subtitle: genderDisplay,
          onTap: onGenderTap,
        ),
      ],
    );
  }
}
