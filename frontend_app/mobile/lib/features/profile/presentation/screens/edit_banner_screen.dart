import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/user_banner.dart';
import '../../../../core/widgets/color_picker_sheet.dart';
import '../../../../core/widgets/form_pop_scope.dart';
import '../providers/profile_provider.dart';

class EditBannerScreen extends ConsumerStatefulWidget {
  const EditBannerScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<EditBannerScreen> createState() => _EditBannerScreenState();
}

class _EditBannerScreenState extends ConsumerState<EditBannerScreen> {
  late String _bannerType;
  late String _bannerColor;
  String? _bannerImage;
  File? _localImageFile;
  bool _isSaving = false;

  static const List<String> _presetColors = [
    '#6C63FF',
    '#66BB6A',
    '#26A69A',
    '#26C6DA',
    '#42A5F5',
    '#7E57C2',
    '#EC407A',
    '#FFA726',
    '#1E293B',
    '#0F172A',
  ];

  @override
  void initState() {
    super.initState();
    _bannerType = widget.profile['bannerType'] as String? ?? 'color';
    _bannerColor = widget.profile['bannerColor'] as String? ?? '#6C63FF';
    _bannerImage = widget.profile['bannerImage'] as String?;
  }

  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Banner',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.ratio3x2,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Banner',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _localImageFile = File(croppedFile.path);
        _bannerType = 'image';
      });
    }
  }

  Future<void> _showColorPicker() async {
    final initialColor = _parseColor(_bannerColor);
    final selectedColor = await showCustomColorPicker(
      context: context,
      initialColor: initialColor,
    );

    if (selectedColor != null) {
      final hex = '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      setState(() {
        _bannerColor = hex;
        _bannerType = 'color';
        _localImageFile = null;
      });
    }
  }

  Color _parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _saveBanner() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(profileRepositoryProvider);

      String? targetImage = _bannerImage;
      if (_localImageFile != null) {
        targetImage = _localImageFile!.path;
      }

      await repo.updateProfile(
        bannerType: _bannerType,
        bannerColor: _bannerColor,
        bannerImage: _bannerType == 'image' ? targetImage : null,
      );

      ref.invalidate(profileProvider);

      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: l10n.languageCode == 'id'
              ? 'Banner profil berhasil diperbarui'
              : 'Profile banner updated successfully',
          type: SnackbarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: 'Failed to update banner: $e',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialType = widget.profile['bannerType'] as String? ?? 'color';
    final initialColor = widget.profile['bannerColor'] as String? ?? '#6C63FF';
    final isDirty = !_isSaving &&
        (_bannerType != initialType ||
            _bannerColor != initialColor ||
            _localImageFile != null);

    return FormPopScope(
      hasUnsavedChanges: isDirty,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            l10n.languageCode == 'id' ? 'Banner Profil' : 'Profile Banner',
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
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview Banner
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: UserBanner(
                          bannerType: _bannerType,
                          bannerColor: _bannerColor,
                          bannerImage: _bannerImage,
                          localFile: _localImageFile,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Upload custom image banner button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickBannerImage,
                          icon: const Icon(Icons.add_photo_alternate_rounded),
                          label: Text(l10n.languageCode == 'id'
                              ? 'Unggah Gambar Banner'
                              : 'Upload Banner Image'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Color Options Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.languageCode == 'id'
                                ? 'Warna Banner'
                                : 'Banner Color',
                            style: AppTypography.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showColorPicker,
                            icon: const Icon(Icons.palette_outlined, size: 18),
                            label: Text(l10n.languageCode == 'id'
                                ? 'Kustom'
                                : 'Custom'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Preset Color Palette Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: _presetColors.length,
                        itemBuilder: (context, index) {
                          final hex = _presetColors[index];
                          final color = _parseColor(hex);
                          final isSelected = _bannerType == 'color' &&
                              _bannerColor.toUpperCase() == hex.toUpperCase() &&
                              _localImageFile == null;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _bannerColor = hex;
                                _bannerType = 'color';
                                _localImageFile = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark ? Colors.white : Colors.black)
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Save Button
              GestureDetector(
                onTap: _isSaving ? null : _saveBanner,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
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
            ],
          ),
        ),
      ),
    );
  }
}
