import 'dart:io';
import 'dart:typed_data';
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
import '../../../../core/widgets/app_button.dart';
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
  
  // Input Controllers
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // Date of Birth & Gender State
  DateTime? _selectedDate;
  String? _selectedGender;

  // Avatar State (Same as EditProfile)
  String? _selectedAvatarUrl;
  File? _selectedLocalFile;
  late List<String> _avatarOptions;

  // Phone OTP Flow State
  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _isVerifying = false;
  bool _isPhoneVerified = false;

  // Loading indicator for profile save
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _avatarOptions = _avatarSeeds.map(_dicebearUrl).toList();
    // Default to the first avatar option
    _selectedAvatarUrl = _avatarOptions.first;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ─── Avatar Logic ──────────────────────────────────────────────────────────
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
                          l10n.selectLanguage, // Just a confirmation button labeled Select
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

  String _formatDate(DateTime date) {
    return '${date.day} ${l10n.shortMonths[date.month - 1]} ${date.year}';
  }

  // ─── OTP Logic ─────────────────────────────────────────────────────────────
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

    // Simulate OTP WhatsApp sending
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSendingOtp = false;
        _otpSent = true;
      });
      AppSnackbar.show(
        context,
        title: l10n.otpSentTitle,
        message: l10n.otpSentMessage(phone),
        type: SnackbarType.success,
      );
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text;
    if (code.length != 6) return;

    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      if (code == '123456') {
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
      } else {
        AppSnackbar.show(
          context,
          title: l10n.otpInvalidCodeTitle,
          message: l10n.otpInvalidCodeMessage,
          type: SnackbarType.error,
        );
      }
      setState(() => _isVerifying = false);
    }
  }

  // ─── Save Logic ────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      
      // Upload avatar first if local file selected
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

      // Sync Avatar URL to server
      if (finalAvatarUrl != null) {
        await repo.updateAvatar(avatarUrl: finalAvatarUrl);
      }

      // Sync remaining details
      final birthdateIso = _selectedDate?.toIso8601String().split('T').first;
      await repo.updateProfile(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim().isNotEmpty ? _usernameController.text.trim() : null,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        birthDate: birthdateIso,
        gender: _selectedGender,
        phoneNumber: _isPhoneVerified ? _phoneController.text.trim() : null,
      );

      // Complete profile preferences flag
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Pin theme definitions for OTP verification code
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step header progress indicator
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: isDark ? Colors.white10 : AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.step1of2,
                      style: AppTypography.textTheme.labelSmall
                          ?.copyWith(color: hintColor),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('🎉', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  l10n.completeYourProfile,
                  style: AppTypography.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.profileSetupSubtitle,
                  style: AppTypography.textTheme.bodyLarge
                      ?.copyWith(color: hintColor),
                ),
                const SizedBox(height: 28),

                // ─── Interactive Circle Avatar Picker (Identical to EditProfile) ───
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

                // ─── Input Fields Form ───
                AppTextField(
                  controller: _fullNameController,
                  label: l10n.fullName,
                  hint: l10n.fullNameHint,
                  keyboardType: TextInputType.name,
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.fullNameRequired;
                    }
                    if (v.trim().length < 2) return l10n.nameTooShortSetup;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'e.g. janesmith',
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _bioController,
                  label: l10n.bioField,
                  hint: 'e.g. Financial enthusiast',
                  keyboardType: TextInputType.multiline,
                  prefixIcon: const Icon(Icons.info_outline_rounded, size: 20),
                ),
                const SizedBox(height: 16),

                // Date of Birth Field
                Text(
                  l10n.dateOfBirth,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          color: isDark ? Colors.white60 : Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? _formatDate(_selectedDate!)
                                : l10n.selectBirthdate,
                            style: TextStyle(
                              fontSize: 15,
                              color: _selectedDate != null
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : hintColor,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Gender Fields Selection Row
                Text(
                  l10n.genderField,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Male Chip Option
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.male_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.genderMale),
                          ],
                        ),
                        selected: _selectedGender == 'male',
                        onSelected: (selected) {
                          setState(() {
                            _selectedGender = selected ? 'male' : null;
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedGender == 'male' ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Female Chip Option
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.female_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.genderFemale),
                          ],
                        ),
                        selected: _selectedGender == 'female',
                        onSelected: (selected) {
                          setState(() {
                            _selectedGender = selected ? 'female' : null;
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedGender == 'female' ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Phone Number OTP verification section ───
                Text(
                  l10n.whatsappPhoneNumber,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
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
                          onPressed: _isSendingOtp ? null : _sendOtp,
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

                // OTP verification Pinput widget
                if (_otpSent && !_isPhoneVerified) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.enterOtpTitle,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      l10n.useDemoCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                const SizedBox(height: 48),

                // Main Save & Continue button
                AppButton(
                  label: l10n.continueButton,
                  onPressed: _saveProfile,
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
