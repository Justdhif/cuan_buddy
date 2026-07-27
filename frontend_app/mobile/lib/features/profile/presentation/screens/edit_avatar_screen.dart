import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/form_pop_scope.dart';
import '../providers/profile_provider.dart';

class EditAvatarScreen extends ConsumerStatefulWidget {
  const EditAvatarScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<EditAvatarScreen> createState() => _EditAvatarScreenState();
}

class _EditAvatarScreenState extends ConsumerState<EditAvatarScreen> {
  String? _selectedAvatarUrl;
  File? _selectedLocalFile;
  bool _isSaving = false;

  static const List<String> _avatarSeeds = [
    'alpha',
    'beta',
    'gamma',
    'delta',
    'epsilon',
    'zeta',
    'eta',
    'theta',
    'iota',
    'kappa',
    'lambda',
    'mu',
    'nu',
    'xi',
    'omicron',
  ];

  late final List<String> _avatarOptions;

  @override
  void initState() {
    super.initState();
    _selectedAvatarUrl = widget.profile['avatar'] as String?;
    _avatarOptions = _avatarSeeds.map(_dicebearUrl).toList();
  }

  String _dicebearUrl(String seed) =>
      'https://api.dicebear.com/7.x/bottts/png?seed=$seed';

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedLocalFile = File(croppedFile.path);
        _selectedAvatarUrl = null;
      });
    }
  }

  Future<void> _saveAvatar() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(profileRepositoryProvider);

      String targetUrl = _selectedAvatarUrl ?? '';
      if (_selectedLocalFile != null) {
        targetUrl = _selectedLocalFile!.path;
      }

      await repo.updateAvatar(avatarUrl: targetUrl);
      ref.invalidate(profileProvider);

      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: l10n.languageCode == 'id'
              ? 'Foto profil berhasil diperbarui'
              : 'Profile photo updated successfully',
          type: SnackbarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: 'Failed to update avatar: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initialAvatar = widget.profile['avatar'] as String?;
    final isDirty = !_isSaving &&
        (_selectedAvatarUrl != initialAvatar || _selectedLocalFile != null);

    return FormPopScope(
      hasUnsavedChanges: isDirty,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            l10n.profilePhoto,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        bottomNavigationBar: GestureDetector(
          onTap: _isSaving ? null : _saveAvatar,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: _isSaving
                    ? const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          l10n.saveButton,
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Preview Avatar
                Center(
                  child: Hero(
                    tag: 'avatar',
                    child: UserAvatar(
                      size: 150,
                      avatarUrl: _selectedAvatarUrl,
                      localFile: _selectedLocalFile,
                      fallbackName: widget.profile['fullName'] ??
                          widget.profile['username'] ??
                          'U',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Upload Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickAndCropImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(l10n.languageCode == 'id' ? 'Kamera' : 'Camera'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickAndCropImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: Text(l10n.languageCode == 'id' ? 'Galeri' : 'Gallery'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // Preset Avatars Selector
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.chooseAvatar,
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _avatarOptions.length,
                  itemBuilder: (context, index) {
                    final url = _avatarOptions[index];
                    final isSelected = url == _selectedAvatarUrl &&
                        _selectedLocalFile == null;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatarUrl = url;
                          _selectedLocalFile = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
