import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/profile_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/avatar_border_helper.dart';

// Konfigurasi border dikelola terpusat di avatar_border_helper.dart

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  // Avatar
  String? _selectedAvatarUrl;
  File? _selectedLocalFile;

  // Border & Wings
  String _selectedBorderId = 'none';
  String _selectedBorderAsset = '';
  String _selectedWingsId = 'none';
  String _selectedWingsAsset = '';

  @override
  void initState() {
    super.initState();
    _selectedAvatarUrl = widget.profile['avatar'] as String?;
    _initBorder();
    _initWings();
  }

  /// Load border: prioritas dari data profil (backend), fallback ke SharedPreferences.
  Future<void> _initBorder() async {
    // Cek dulu apakah profile sudah punya border dari backend
    final profileBorderId = widget.profile['avatarBorder'] as String?;
    if (profileBorderId != null && profileBorderId.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedBorderId = profileBorderId;
          _selectedBorderAsset = borderAssetFromId(profileBorderId);
        });
      }
      // Sync juga ke SharedPreferences sebagai cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kBorderPrefKey, profileBorderId);
      return;
    }

    // Fallback: baca dari SharedPreferences (cache lokal)
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(kBorderPrefKey) ?? 'none';
    if (mounted) {
      setState(() {
        _selectedBorderId = savedId;
        _selectedBorderAsset = borderAssetFromId(savedId);
      });
    }
  }

  Future<void> _initWings() async {
    final profileWingsId = widget.profile['avatarWings'] as String?;
    if (profileWingsId != null && profileWingsId.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedWingsId = profileWingsId;
          _selectedWingsAsset = wingsAssetFromId(profileWingsId);
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kWingsPrefKey, profileWingsId);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedWingsId = prefs.getString(kWingsPrefKey) ?? 'none';
    if (mounted) {
      setState(() {
        _selectedWingsId = savedWingsId;
        _selectedWingsAsset = wingsAssetFromId(savedWingsId);
      });
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white60 : Colors.black54,
              size: 24,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    // Panggil watch di sini agar data terbaru selalu ditarik dan di-cache
    ref.watch(unlockedBordersProvider);

    ref.listen<AsyncValue<Map<String, dynamic>>>(profileProvider, (previous, next) {
      if (next.hasValue) {
        final profile = next.value!;
        setState(() {
          _selectedAvatarUrl = profile['avatar'] as String?;
          _selectedBorderId = profile['avatarBorder'] as String? ?? 'none';
          _selectedBorderAsset = borderAssetFromId(_selectedBorderId);
          _selectedWingsId = profile['avatarWings'] as String? ?? 'none';
          _selectedWingsAsset = wingsAssetFromId(_selectedWingsId);
          _selectedLocalFile = null;
        });
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (profile) {
          final fullName = profile['fullName'] as String? ?? '';
          final username = profile['username'] as String? ?? '';
          final bio = profile['bio'] as String? ?? '';
          final rawBirthdate = profile['birthDate'] as String? ?? profile['birthdate'] as String? ?? '';
          final gender = profile['gender'] as String?;

          // Format birthdate display
          String birthdateDisplay = '';
          if (rawBirthdate.isNotEmpty) {
            try {
              final date = DateTime.parse(rawBirthdate);
              birthdateDisplay = '${date.day} ${l10n.shortMonths[date.month - 1]} ${date.year}';
            } catch (_) {
              birthdateDisplay = rawBirthdate;
            }
          }

          // Gender display label
          String genderDisplay = '';
          if (gender == 'male') {
            genderDisplay = l10n.genderMale;
          } else if (gender == 'female') {
            genderDisplay = l10n.genderFemale;
          }

          final fallback = l10n.notSet;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Center(
                  child: Column(
                     children: [
                      GestureDetector(
                        onTap: () {
                          if (profileAsync.hasValue) {
                            context.push('/profile/edit-photo', extra: profileAsync.value);
                          }
                        },
                        child: Hero(
                          tag: 'avatar',
                          child: UserAvatar(
                            size: 160,
                            borderAsset: _selectedBorderAsset,
                            wingsAsset: _selectedWingsAsset,
                            backAsset: borderInfoFromId(_selectedBorderId).backAsset,
                            avatarUrl: _selectedAvatarUrl,
                            localFile: _selectedLocalFile,
                            fallbackName: '?',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, thickness: 0.5),

                // 2. Media & Customization Fields List
                _buildInfoTile(
                  context: context,
                  icon: Icons.image_outlined,
                  title: l10n.profilePhoto,
                  subtitle: l10n.profilePhotoSubtitle,
                  onTap: () {
                    if (profileAsync.hasValue) {
                      context.push('/profile/edit-photo', extra: profileAsync.value);
                    }
                  },
                ),
                _buildInfoTile(
                  context: context,
                  icon: Icons.panorama_outlined,
                  title: l10n.profileBanner,
                  subtitle: l10n.profileBannerSubtitle,
                  onTap: () {
                    if (profileAsync.hasValue) {
                      context.push('/profile/edit-banner', extra: profileAsync.value);
                    }
                  },
                ),
                _buildInfoTile(
                  context: context,
                  icon: Icons.wallpaper_outlined,
                  title: l10n.listBackground,
                  subtitle: l10n.listBackgroundSubtitle,
                  onTap: () {
                    if (profileAsync.hasValue) {
                      context.push('/profile/edit-list-background', extra: profileAsync.value);
                    }
                  },
                ),
                const Divider(height: 1, thickness: 0.5),

                // 3. Info Fields List
                _buildInfoTile(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  title: l10n.fullName,
                  subtitle: fullName.isNotEmpty ? fullName : fallback,
                  onTap: () => context.push('/profile/edit-name', extra: fullName),
                ),
                _buildInfoTile(
                  context: context,
                  icon: Icons.alternate_email_rounded,
                  title: 'Username',
                  subtitle: username.isNotEmpty ? '@$username' : fallback,
                  onTap: () => context.push('/profile/edit-username', extra: username),
                ),
                _buildInfoTile(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  title: l10n.bioField,
                  subtitle: bio.isNotEmpty ? bio : fallback,
                  onTap: () => context.push('/profile/edit-bio', extra: bio),
                ),
                _buildInfoTile(
                  context: context,
                  icon: Icons.cake_outlined,
                  title: l10n.dateOfBirth,
                  subtitle: birthdateDisplay.isNotEmpty ? birthdateDisplay : fallback,
                  onTap: () => context.push('/profile/edit-birthdate', extra: rawBirthdate),
                ),
                _buildInfoTile(
                  context: context,
                  icon: Icons.wc_outlined,
                  title: l10n.genderField,
                  subtitle: genderDisplay.isNotEmpty ? genderDisplay : fallback,
                  onTap: () => context.push('/profile/edit-gender', extra: gender),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}
