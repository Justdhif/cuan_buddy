import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/user_avatar.dart';

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
  final String fallback;
  final Color hintColor;
  final VoidCallback onAvatarEditTap;
  final VoidCallback onFullNameTap;
  final VoidCallback onUsernameTap;
  final VoidCallback onBioTap;
  final VoidCallback onBirthdateTap;
  final VoidCallback onGenderTap;
  final Widget Function({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? subtitleColor,
  }) buildInfoTile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lengkapi Identitas Profil',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sesuaikan foto, nama, username, dan bio aplikasi Anda.',
                style: TextStyle(
                  fontSize: 13,
                  color: hintColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: onAvatarEditTap,
                child: UserAvatar(
                  size: 120,
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
        const Divider(height: 1, thickness: 0.5),

        buildInfoTile(
          icon: Icons.badge_outlined,
          title: l10n.languageCode == 'id' ? 'Nama Lengkap' : 'Full Name',
          subtitle: fullName.isNotEmpty ? fullName : fallback,
          onTap: onFullNameTap,
          subtitleColor: fullName.isEmpty ? hintColor : null,
        ),
        buildInfoTile(
          icon: Icons.alternate_email_rounded,
          title: 'Username',
          subtitle: username.isNotEmpty ? '@$username' : fallback,
          onTap: onUsernameTap,
          subtitleColor: username.isEmpty ? hintColor : null,
        ),
        buildInfoTile(
          icon: Icons.notes_rounded,
          title: 'Bio',
          subtitle: bio.isNotEmpty ? bio : fallback,
          onTap: onBioTap,
          subtitleColor: bio.isEmpty ? hintColor : null,
        ),
        buildInfoTile(
          icon: Icons.cake_outlined,
          title: l10n.languageCode == 'id' ? 'Tanggal Lahir' : 'Birthdate',
          subtitle: birthdateDisplay.isNotEmpty ? birthdateDisplay : fallback,
          onTap: onBirthdateTap,
          subtitleColor: birthdateDisplay.isEmpty ? hintColor : null,
        ),
        buildInfoTile(
          icon: Icons.person_outline,
          title: l10n.languageCode == 'id' ? 'Jenis Kelamin' : 'Gender',
          subtitle: genderDisplay.isNotEmpty ? genderDisplay : fallback,
          onTap: onGenderTap,
          subtitleColor: genderDisplay.isEmpty ? hintColor : null,
        ),
      ],
    );
  }
}
