import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dio/dio.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/profile_provider.dart';

const List<String> _avatarSeeds = [
  'alpha', 'bravo', 'charlie', 'delta', 'echo',
  'foxtrot', 'golf', 'hotel', 'india',
];

String _dicebearUrl(String seed) =>
    'https://api.dicebear.com/8.x/avataaars/png?seed=$seed';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  DateTime? _selectedDate;
  bool _isSaving = false;

  // Avatar
  late String? _selectedAvatarUrl;
  File? _selectedLocalFile;
  late List<String> _avatarOptions;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.profile['fullName'] as String? ?? '');
    _phoneController = TextEditingController(
        text: widget.profile['phoneNumber'] as String? ??
            widget.profile['phone'] as String? ??
            '');

    final birthDateStr = widget.profile['birthDate'] as String?;
    if (birthDateStr != null) {
      _selectedDate = DateTime.tryParse(birthDateStr);
    }

    _selectedAvatarUrl = widget.profile['avatar'] as String?;
    _avatarOptions = _avatarSeeds.map(_dicebearUrl).toList();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? finalAvatarUrl = _selectedAvatarUrl;

      // If user picked a local file, upload it now
      if (_selectedLocalFile != null) {
        final dio = ref.read(dioClientProvider).dio;
        
        // Read file bytes and validate size (max ~3MB to stay under Vercel 4.5MB limit)
        final Uint8List rawBytes = await _selectedLocalFile!.readAsBytes();
        
        // Determine file extension for filename
        final ext = _selectedLocalFile!.path.split('.').last.toLowerCase();
        final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            rawBytes,
            filename: filename,
          ),
        });
        
        final response = await dio.post(
          '/profiles/avatar/upload',
          data: formData,
          options: Options(
            headers: {'Content-Type': 'multipart/form-data'},
          ),
        );
        finalAvatarUrl = response.data['avatar'] as String;
      }

      // Update profile fields
      await ref.read(profileRepositoryProvider).updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            dateOfBirth: _selectedDate?.toUtc().toIso8601String(),
          );

      // If user picked a dicebear avatar, update it (if it's local file, upload endpoint already updated DB)
      final currentAvatar = widget.profile['avatar'] as String?;
      if (finalAvatarUrl != null && finalAvatarUrl != currentAvatar && _selectedLocalFile == null) {
        await ref
            .read(profileRepositoryProvider)
            .updateAvatar(avatarUrl: finalAvatarUrl);
      }

      ref.invalidate(profileProvider);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: l10n.profileUpdatedSuccess,
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackbar.show(context, title: l10n.error, message: '${l10n.failedToUpdateProfile}: $e', type: SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Avatar Picker ─────────────────────────────────────────
                _AvatarPickerSection(
                  avatarOptions: _avatarOptions,
                  selectedAvatarUrl: _selectedAvatarUrl,
                  selectedLocalFile: _selectedLocalFile,
                  onDicebearSelected: (url) => setState(() {
                    _selectedAvatarUrl = url;
                    _selectedLocalFile = null;
                  }),
                  onUploadTap: _pickAvatarAndCrop,
                  isDark: isDark,
                  currentProfileAvatar: widget.profile['avatar'] as String?,
                ),
                const SizedBox(height: 32),

                // ─── Full Name ─────────────────────────────────────────────
                Text(
                  l10n.personalInfo,
                  style: AppTypography.textTheme.titleSmall
                      ?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _nameController,
                  label: l10n.fullName,
                  hint: l10n.fullNameHint,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.fullNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Phone Number ──────────────────────────────────────────
                AppTextField(
                  controller: _phoneController,
                  label: l10n.phoneNumberOptional,
                  hint: l10n.phoneHint,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // ─── Date of Birth ─────────────────────────────────────────
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ??
                          DateTime.now()
                              .subtract(const Duration(days: 365 * 20)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null && pickedDate != _selectedDate) {
                      setState(() => _selectedDate = pickedDate);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.dateOfBirthOptional,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate != null
                              ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                              : l10n.selectDateHint,
                          style: AppTypography.textTheme.bodyLarge?.copyWith(
                            color: _selectedDate == null
                                ? (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight)
                                : null,
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // ─── Save Button ───────────────────────────────────────────
                AppButton(
                  label: l10n.saveChanges,
                  onPressed: _save,
                  isLoading: _isSaving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Avatar Picker Section ────────────────────────────────────────────────────
class _AvatarPickerSection extends StatelessWidget {
  const _AvatarPickerSection({
    required this.avatarOptions,
    required this.selectedAvatarUrl,
    required this.selectedLocalFile,
    required this.onDicebearSelected,
    required this.onUploadTap,
    required this.isDark,
    required this.currentProfileAvatar,
  });

  final List<String> avatarOptions;
  final String? selectedAvatarUrl;
  final File? selectedLocalFile;
  final ValueChanged<String> onDicebearSelected;
  final VoidCallback onUploadTap;
  final bool isDark;
  final String? currentProfileAvatar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // We display 1 preview + 1 upload circle + 9 dicebears = 10 items total
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Big Preview ───────────────────────────────────────────────────
        Center(
          child: Hero(
            tag: 'avatar',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: selectedLocalFile != null
                    ? Image.file(
                        selectedLocalFile!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      )
                    : (selectedAvatarUrl != null && selectedAvatarUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: selectedAvatarUrl!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.primary,
                          ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        Text(
          l10n.chooseAvatar,
          style: AppTypography.textTheme.titleSmall
              ?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: 1 + avatarOptions.length,
          itemBuilder: (context, index) {
            // First item is the "Upload" circle
            if (index == 0) {
              final isSelected = selectedLocalFile != null || 
                (selectedAvatarUrl != null && !avatarOptions.contains(selectedAvatarUrl));
              
              return GestureDetector(
                onTap: onUploadTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      ClipOval(
                        child: selectedLocalFile != null
                            ? Image.file(
                                selectedLocalFile!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : (currentProfileAvatar != null && !avatarOptions.contains(currentProfileAvatar))
                                ? CachedNetworkImage(
                                    imageUrl: currentProfileAvatar!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      color: AppColors.primary.withValues(alpha: 0.8),
                                      size: 28,
                                    ),
                                  ),
                      ),
                      if (selectedLocalFile != null || (currentProfileAvatar != null && !avatarOptions.contains(currentProfileAvatar)))
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      if (isSelected)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 3),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            // Dicebear avatars
            final url = avatarOptions[index - 1];
            final isSelected = url == selectedAvatarUrl && selectedLocalFile == null;

            return GestureDetector(
              onTap: () => onDicebearSelected(url),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.borderLight.withValues(alpha: 0.4),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.person, color: AppColors.primary, size: 24),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
