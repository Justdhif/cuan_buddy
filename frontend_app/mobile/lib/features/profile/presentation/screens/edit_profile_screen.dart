import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../providers/profile_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/avatar_border_helper.dart';

const List<String> _avatarSeeds = [
  'alpha',
  'bravo',
  'charlie',
  'delta',
  'echo',
  'foxtrot',
  'golf',
  'hotel',
  'india',
];

String _dicebearUrl(String seed) =>
    'https://api.dicebear.com/8.x/avataaars/png?seed=$seed';

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
  late List<String> _avatarOptions;

  // Border
  String _selectedBorderId = 'none';
  String _selectedBorderAsset = '';

  @override
  void initState() {
    super.initState();
    _selectedAvatarUrl = widget.profile['avatar'] as String?;
    _avatarOptions = _avatarSeeds.map(_dicebearUrl).toList();
    _initBorder();
    
    // Paksa refresh data unlocked borders dari server saat halaman edit dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(unlockedBordersProvider);
    });
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

  /// Simpan border ke SharedPreferences (cache), backend, dan update UI.
  Future<void> _saveBorder(String borderId, String borderAsset) async {
    // Update UI dulu (optimistic)
    setState(() {
      _selectedBorderId = borderId;
      _selectedBorderAsset = borderAsset;
    });
    // Cache lokal
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kBorderPrefKey, borderId);
    // Simpan ke backend agar user lain bisa melihat
    try {
      await ref.read(profileRepositoryProvider).updateBorder(borderId: borderId);
    } catch (_) {
      // Gagal sync ke backend tidak menghalangi UX — tetap tersimpan lokal
    }
  }

  Future<void> _pickAvatarAndCrop() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Avatar',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Avatar',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedLocalFile = File(croppedFile.path);
        _selectedAvatarUrl = null; // Prioritize local file
      });
    }
  }

  Future<void> _saveAvatarOnly() async {
    final l10n = AppLocalizations.of(context);

    try {
      String? finalAvatarUrl = _selectedAvatarUrl;

      // If user picked a local file, upload it
      if (_selectedLocalFile != null) {
        final dio = ref.read(dioClientProvider).dio;
        final Uint8List rawBytes = await _selectedLocalFile!.readAsBytes();
        final ext = _selectedLocalFile!.path.split('.').last.toLowerCase();
        final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(rawBytes, filename: filename),
        });

        final response = await dio.post(
          '/profiles/avatar/upload',
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        );
        finalAvatarUrl = response.data['avatar'] as String;
      }

      final currentAvatar = widget.profile['avatar'] as String?;
      if (finalAvatarUrl != null && finalAvatarUrl != currentAvatar) {
        await ref
            .read(profileRepositoryProvider)
            .updateAvatar(avatarUrl: finalAvatarUrl);
      }

      ref.invalidate(profileProvider);

      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: l10n.profilePhotoUpdatedSuccess,
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: l10n.failedToUpdateAvatar(e.toString()),
          type: SnackbarType.error,
        );
      }
    }
  }

  void _showAvatarEditSheet() {
    // Refresh data unlocked borders dari server sesaat sebelum bottom sheet dibuka
    ref.invalidate(unlockedBordersProvider);
    
    bool isSavingInSheet = false;
    // Ambil state border saat ini agar sheet bisa track perubahan sementara
    String sheetBorderId = _selectedBorderId;
    String sheetBorderAsset = _selectedBorderAsset;

    AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            // Helper: widget preview avatar di dalam sheet
            Widget buildSheetAvatarPreview() {
              return UserAvatar(
                size: 160,
                borderAsset: sheetBorderAsset,
                avatarUrl: _selectedAvatarUrl,
                localFile: _selectedLocalFile,
                fallbackName: '?',
              );
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Judul sheet ──
                    Text(
                      l10n.profilePhoto,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // ── Preview avatar + border ──
                    Center(child: buildSheetAvatarPreview()),
                    const SizedBox(height: 24),

                    // ── Section: Pilih Avatar ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.chooseAvatar,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _avatarOptions.length,
                        itemBuilder: (context, index) {
                          final url = _avatarOptions[index];
                          final isSelected = url == _selectedAvatarUrl && _selectedLocalFile == null;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _selectedAvatarUrl = url;
                                _selectedLocalFile = null;
                              });
                              setState(() {
                                _selectedAvatarUrl = url;
                                _selectedLocalFile = null;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(strokeWidth: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section: Pilih Border Avatar ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Avatar Border',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 72,
                      child: Builder(
                        builder: (context) {
                          final unlockedBordersAsync = ref.watch(unlockedBordersProvider);
                          final borders = kAllBorders;

                          return unlockedBordersAsync.when(
                            data: (unlockedBorders) {
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: borders.length,
                                itemBuilder: (context, index) {
                                  final border = borders[index];
                                  final isNoBorder = border.isNone;
                                  final isSelected = border.id == sheetBorderId;
                                  final isUnlocked = border.isGlobal || unlockedBorders.contains(border.id);

                                  return GestureDetector(
                                    onTap: () {
                                      if (!isUnlocked) {
                                        showDialog<void>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Row(
                                              children: [
                                                Icon(border.tier.icon, color: border.tier.color),
                                                const SizedBox(width: 8),
                                                Text(border.label),
                                              ],
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Tier: ${border.tier.label}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: border.tier.color,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(border.requirementDescription),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Tutup'),
                                              ),
                                            ],
                                          ),
                                        );
                                        return;
                                      }

                                      setModalState(() {
                                        sheetBorderId = border.id;
                                        sheetBorderAsset = border.asset;
                                      });
                                      // Langsung simpan ke prefs & update parent state
                                      _saveBorder(border.id, border.asset);
                                    },
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          isNoBorder
                                              // Opsi "Tanpa Border" — tampilkan icon slash
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected
                                                        ? AppColors.primary.withValues(alpha: 0.15)
                                                        : Colors.grey.withValues(alpha: 0.15),
                                                  ),
                                                  child: Icon(
                                                    Icons.block_rounded,
                                                    size: 28,
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : Colors.grey,
                                                  ),
                                                )
                                              // Opsi border dengan gambar asset
                                              : ClipOval(
                                                  child: Image.asset(
                                                    border.asset,
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                          if (!isUnlocked)
                                            Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.lock_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (err, _) => Center(
                              child: Text('Gagal memuat border: $err'),
                            ),
                          );
                        }
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Tombol upload foto ──
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isSavingInSheet
                            ? null
                            : () async {
                                Navigator.pop(sheetContext);
                                await _pickAvatarAndCrop();
                                if (mounted) _showAvatarEditSheet();
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.upload_file_outlined, color: AppColors.primary),
                        label: Text(
                          l10n.uploadNewPhoto,
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Tombol Simpan ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSavingInSheet
                            ? null
                            : () async {
                                setModalState(() => isSavingInSheet = true);
                                await _saveAvatarOnly();
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSavingInSheet
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                l10n.saveButton,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                        onTap: _showAvatarEditSheet,
                        child: Hero(
                          tag: 'avatar',
                          child: UserAvatar(
                            size: 160,
                            borderAsset: _selectedBorderAsset,
                            avatarUrl: _selectedAvatarUrl,
                            localFile: _selectedLocalFile,
                            fallbackName: '?',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _showAvatarEditSheet,
                        child: Text(
                          l10n.editPhoto,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, thickness: 0.5),

                // 2. Info Fields List
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
