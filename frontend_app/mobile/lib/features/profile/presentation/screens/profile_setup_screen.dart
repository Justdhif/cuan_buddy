import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/providers/core_providers.dart';
import '../../presentation/providers/profile_provider.dart';

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

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final _formKey = GlobalKey<FormState>();

  // Navigation state
  int _currentStep = 1; // 1: Profile Details, 2: WhatsApp Number & OTP

  // State Variables
  String _fullName = '';
  String _username = '';
  String _bio = '';
  DateTime? _selectedDate;
  String? _selectedGender;

  // Phone OTP State
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _isVerifying = false;
  bool _isPhoneVerified = false;

  // Avatar State
  String? _selectedAvatarUrl;
  File? _selectedLocalFile;
  late List<String> _avatarOptions;

  bool _isSaving = false;

  // Countdown Timer
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _avatarOptions = _avatarSeeds.map(_dicebearUrl).toList();
    _selectedAvatarUrl = _avatarOptions.first;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ─── Timer Logic ──────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 300; // 5 minutes
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ─── Avatar Bottom Sheet ───────────────────────────────────────────────────
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
          toolbarTitle: l10n.cropAvatar,
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: l10n.cropAvatar,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
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

  void _showAvatarEditSheet() {
    AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.profilePhoto,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: ClipOval(
                          child: _selectedLocalFile != null
                              ? Image.file(_selectedLocalFile!, fit: BoxFit.cover)
                              : (_selectedAvatarUrl != null && _selectedAvatarUrl!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: _selectedAvatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      errorWidget: (_, __, ___) => const Icon(Icons.person, size: 60),
                                    )
                                  : const Icon(Icons.person, size: 60),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _pickAvatarAndCrop();
                          _showAvatarEditSheet();
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.selectLanguage,
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

  // ─── Input Bottom Sheets ───────────────────────────────────────────────────
  void _showEditNameSheet() {
    final controller = TextEditingController(text: _fullName);
    final formKey = GlobalKey<FormState>();

    AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: controller,
                  hint: l10n.fullNameHint,
                  autofocus: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.fullNameRequired;
                    if (v.trim().length < 2) return l10n.nameTooShortSetup;
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => _fullName = controller.text.trim());
                      Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.saveButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditUsernameSheet() {
    final controller = TextEditingController(text: _username);
    final formKey = GlobalKey<FormState>();

    AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.usernameField,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: controller,
                  hint: l10n.usernameHint,
                  autofocus: true,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.usernameCannotBeEmpty;
                    if (v.trim().length < 3) return l10n.usernameInvalidFormat;
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => _username = controller.text.trim());
                      Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.saveButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditBioSheet() {
    final controller = TextEditingController(text: _bio);

    AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bioField,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: controller,
                hint: l10n.bioHint,
                autofocus: true,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _bio = controller.text.trim());
                    Navigator.pop(sheetContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.saveButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Birthdate Logic ───────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }


  // ─── Gender Bottom Sheet ───────────────────────────────────────────────────
  Widget _buildGenderOption({
    required String value,
    required String label,
    required IconData icon,
    required bool isDark,
    required StateSetter setModalState,
  }) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setModalState(() => _selectedGender = value);
        setState(() => _selectedGender = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.surfaceDark : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isDark ? AppColors.backgroundDark : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : (isDark ? Colors.white60 : Colors.black45),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white38 : Colors.black26),
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGenderSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.genderField,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildGenderOption(
                      value: 'male',
                      label: l10n.genderMale,
                      icon: Icons.male_rounded,
                      isDark: isDark,
                      setModalState: setModalState,
                    ),
                    const SizedBox(height: 12),
                    _buildGenderOption(
                      value: 'female',
                      label: l10n.genderFemale,
                      icon: Icons.female_rounded,
                      isDark: isDark,
                      setModalState: setModalState,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.saveButton, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  // ─── OTP / Phone Verification Logic ────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      AppSnackbar.show(
        context,
        title: l10n.error,
        message: l10n.phoneNumberRequired,
        type: SnackbarType.error,
      );
      return;
    }
    if (!phone.startsWith('+') && !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      AppSnackbar.show(
        context,
        title: l10n.error,
        message: l10n.invalidPhoneNumberFormat,
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/profiles/phone/send-otp', data: {'phone': phone});

      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _otpSent = true;
        });
        _startTimer();
        AppSnackbar.show(
          context,
          title: l10n.otpSentTitle,
          message: l10n.otpSentMessage(phone),
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingOtp = false);
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: 'Failed to send OTP: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text;
    if (code.length != 6) return;
    final phone = _phoneController.text.trim();

    setState(() => _isVerifying = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/profiles/phone/verify-otp', data: {'phone': phone, 'code': code});

      if (mounted) {
        setState(() {
          _isPhoneVerified = true;
          _otpSent = false;
        });
        AppSnackbar.show(
          context,
          title: l10n.otpSuccessTitle,
          message: l10n.otpSuccessMessage,
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.otpFailedTitle,
          message: 'Failed to verify OTP: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  // ─── Save & Submit ─────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (_fullName.trim().isEmpty) {
      AppSnackbar.show(
        context,
        title: l10n.error,
        message: l10n.fullNameRequired,
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);

      String? finalAvatarUrl = _selectedAvatarUrl;
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

      if (finalAvatarUrl != null) {
        await repo.updateAvatar(avatarUrl: finalAvatarUrl);
      }

      final birthdateIso = _selectedDate?.toIso8601String().split('T').first;
      await repo.updateProfile(
        fullName: _fullName,
        username: _username.isNotEmpty ? _username : null,
        bio: _bio.isNotEmpty ? _bio : null,
        birthDate: birthdateIso,
        gender: _selectedGender,
        phoneNumber: _isPhoneVerified ? _phoneController.text.trim() : null,
      );

      await ref.read(preferencesServiceProvider).setProfileComplete(true);
      ref.invalidate(profileProvider);

      if (!mounted) return;
      context.go('/wallet-setup');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        title: l10n.error,
        message: '${l10n.failedToSaveProfile}: $e',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Info ListTile Builder ─────────────────────────────────────────────────
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final fallback = l10n.notSet;

    // Formatting date display
    String birthdateDisplay = fallback;
    if (_selectedDate != null) {
      birthdateDisplay = '${_selectedDate!.day} ${l10n.shortMonths[_selectedDate!.month - 1]} ${_selectedDate!.year}';
    }

    // Gender display
    String genderDisplay = fallback;
    if (_selectedGender == 'male') {
      genderDisplay = l10n.genderMale;
    } else if (_selectedGender == 'female') {
      genderDisplay = l10n.genderFemale;
    }

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 48,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        borderRadius: BorderRadius.circular(8),
        color: isDark ? AppColors.surfaceDark : Colors.white,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primary, width: 2),
      ),
    );

    // ─── Dynamic Button Logic (Matches Save Button in transaction_form_screen) ───
    final bool isNameMissing = _fullName.trim().isEmpty;
    final bool isUsernameMissing = _username.trim().isEmpty;

    final String buttonText;
    final VoidCallback? buttonAction;
    final bool isButtonEnabled;

    if (_currentStep == 1) {
      if (isNameMissing) {
        buttonText = l10n.fillFullNameAction;
        buttonAction = _showEditNameSheet;
        isButtonEnabled = false;
      } else if (isUsernameMissing) {
        buttonText = l10n.fillUsernameAction;
        buttonAction = _showEditUsernameSheet;
        isButtonEnabled = false;
      } else {
        buttonText = l10n.continueButton;
        buttonAction = () => setState(() => _currentStep = 2);
        isButtonEnabled = true;
      }
    } else {
      // Step 2
      if (!_isPhoneVerified) {
        buttonText = l10n.verifyWhatsappFirst;
        buttonAction = null;
        isButtonEnabled = false;
      } else {
        buttonText = l10n.saveAndComplete;
        buttonAction = _isSaving ? null : _saveProfile;
        isButtonEnabled = true;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // ─── Premium Dynamic Bottom Navigation Bar ───
      bottomNavigationBar: GestureDetector(
        onTap: buttonAction,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isButtonEnabled
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                    )
                  : Center(
                      child: Text(
                        buttonText,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: isButtonEnabled
                              ? Colors.white
                              : (isDark ? Colors.white60 : Colors.black54),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top step progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_currentStep == 2) ...[
                            GestureDetector(
                              onTap: () => setState(() => _currentStep = 1),
                              child: Icon(
                                Icons.chevron_left_rounded,
                                color: isDark ? Colors.white70 : Colors.black87,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _currentStep == 1 ? 0.5 : 1.0,
                              backgroundColor: isDark ? Colors.white10 : AppColors.borderLight,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _currentStep == 1 ? 'Step 1/2' : 'Step 2/2',
                            style: AppTypography.textTheme.labelSmall?.copyWith(color: hintColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _currentStep == 1 ? l10n.completeYourProfile : l10n.whatsappVerificationTitle,
                        style: AppTypography.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentStep == 1
                            ? l10n.profileSetupSubtitle
                            : l10n.whatsappVerificationSubtitle,
                        style: AppTypography.textTheme.bodyLarge?.copyWith(color: hintColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── STEP 1: Profile Details ───
                if (_currentStep == 1) ...[
                  // Interactive Avatar Editor
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showAvatarEditSheet,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: ClipOval(
                              child: _selectedLocalFile != null
                                  ? Image.file(
                                      _selectedLocalFile!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : (_selectedAvatarUrl != null && _selectedAvatarUrl!.isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: _selectedAvatarUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          errorWidget: (_, __, ___) => const Icon(Icons.person, size: 50),
                                        )
                                      : const Icon(Icons.person, size: 50),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _showAvatarEditSheet,
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

                  _buildInfoTile(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    title: l10n.fullName,
                    subtitle: _fullName.isNotEmpty ? _fullName : fallback,
                    onTap: _showEditNameSheet,
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.alternate_email_rounded,
                    title: 'Username',
                    subtitle: _username.isNotEmpty ? '@$_username' : fallback,
                    onTap: _showEditUsernameSheet,
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    title: l10n.bioField,
                    subtitle: _bio.isNotEmpty ? _bio : fallback,
                    onTap: _showEditBioSheet,
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.cake_outlined,
                    title: l10n.dateOfBirth,
                    subtitle: birthdateDisplay,
                    onTap: _pickDate,
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.wc_outlined,
                    title: l10n.genderField,
                    subtitle: genderDisplay,
                    onTap: _showEditGenderSheet,
                  ),
                ],

                // ─── STEP 2: WhatsApp & OTP Verification ───
                if (_currentStep == 2) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.whatsappPhoneNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                enabled: !_otpSent && !_isPhoneVerified,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. +6282113285557',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: isDark ? AppColors.borderDark.withValues(alpha: 0.4) : AppColors.borderLight.withValues(alpha: 0.4)),
                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  ),
                                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                                  suffixIcon: _isPhoneVerified
                                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                      : null,
                                ),
                              ),
                            ),
                            if (!_isPhoneVerified) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: (_isSendingOtp || _secondsRemaining > 0) ? null : _sendOtp,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isSendingOtp
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(
                                          _otpSent ? 'Resend' : 'Send OTP',
                                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Inline OTP Pinput Area
                        if (_otpSent && !_isPhoneVerified) ...[
                          const SizedBox(height: 20),
                          Text(
                            l10n.enterOtpTitle,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Pinput(
                              controller: _otpController,
                              length: 6,
                              defaultPinTheme: defaultPinTheme,
                              focusedPinTheme: focusedPinTheme,
                              onCompleted: (_) => _verifyOtp(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              _secondsRemaining > 0
                                  ? l10n.resendCodeIn(_formatTimer(_secondsRemaining))
                                  : l10n.didNotReceiveCode,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                          if (_secondsRemaining == 0) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: _isSendingOtp ? null : _sendOtp,
                                child: Text(
                                  l10n.resendAction,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => setState(() => _otpSent = false),
                                child: Text(
                                  l10n.changePhoneNumberLink,
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _isVerifying ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(l10n.verifyAndSave),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
