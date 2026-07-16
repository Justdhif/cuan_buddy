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
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/providers/core_providers.dart';
import '../../presentation/providers/profile_provider.dart';
import '../../../../core/widgets/custom_emoji_picker_sheet.dart';
import '../../../../core/widgets/color_picker_sheet.dart';
import '../../../transactions/presentation/widgets/amount_calculator_sheet.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../wallets/providers/wallet_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/avatar_border_helper.dart';
import '../widgets/profile_setup_step1.dart';
import '../widgets/profile_setup_step2.dart';
import '../widgets/profile_setup_step3.dart';

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
  late final PageController _pageController;

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

  // Border State
  String _selectedBorderId = 'none';
  String _selectedBorderAsset = '';

  bool _isSaving = false;

  // Wallet state variables
  final _walletNameController = TextEditingController(text: 'Main Wallet');
  String _walletType = 'cash';
  String _walletCurrency = 'IDR';
  double _walletBalance = 0.0;
  String _walletEmoji = '💼';
  Color _walletColor = const Color(0xFF6C63FF);
  int _walletDecimalPrecision = 2;

  final List<Color> _walletPresetColors = [
    const Color(0xFF6C63FF),
    const Color(0xFF66BB6A),
    const Color(0xFF26A69A),
    const Color(0xFF26C6DA),
    const Color(0xFF42A5F5),
    const Color(0xFF7E57C2),
  ];

  // Countdown Timer
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep - 1);
    _avatarOptions = _avatarSeeds.map(_dicebearUrl).toList();
    _selectedAvatarUrl = _avatarOptions.first;
    _otpController.addListener(_onOtpChanged);
    _walletNameController.addListener(_onWalletNameChanged);
    _loadSavedBorder();
  }

  Future<void> _loadSavedBorder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(kBorderPrefKey) ?? 'none';
    if (mounted) {
      setState(() {
        _selectedBorderId = savedId;
        _selectedBorderAsset = borderAssetFromId(savedId);
      });
    }
  }

  void _setSelectedBorder(String borderId, String borderAsset) {
    setState(() {
      _selectedBorderId = borderId;
      _selectedBorderAsset = borderAsset;
    });
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(kBorderPrefKey, borderId),
    );
  }

  void _onOtpChanged() {
    setState(() {});
  }

  void _onWalletNameChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _walletNameController.removeListener(_onWalletNameChanged);
    _phoneController.dispose();
    _otpController.dispose();
    _walletNameController.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _navigateToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
    // Ambil state border saat ini agar bisa di-track di dalam sheet
    String sheetBorderId = _selectedBorderId;
    String sheetBorderAsset = _selectedBorderAsset;

    AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            // Helper: widget preview avatar + border
            Widget buildAvatarPreview() {
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
                    // ── Judul ──
                    Text(
                      l10n.profilePhoto,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // ── Preview avatar + border ──
                    Center(child: buildAvatarPreview()),
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

                    // ── Section: Pilih Border ──
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
                          final unlockedBorders = ref.watch(unlockedBordersProvider).valueOrNull ?? [];
                          final borders = kAllBorders;

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
                                  _setSelectedBorder(border.id, border.asset);
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      isNoBorder
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
                                                color: isSelected ? AppColors.primary : Colors.grey,
                                              ),
                                            )
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
                        }
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Upload foto ──
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

                    // ── Tombol Pilih / Done ──
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
                        child: Text(
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

      // Simpan border yang dipilih ke backend
      if (_selectedBorderId != 'none') {
        await repo.updateBorder(borderId: _selectedBorderId);
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

      // Create Main Wallet
      final walletName = _walletNameController.text.trim();
      final colorCode = _colorToHex(_walletColor);
      final walletNotifier = ref.read(walletsProvider.notifier);
      final walletError = await walletNotifier.createWallet({
        'name': walletName.isNotEmpty ? walletName : 'Main Wallet',
        'type': _walletType,
        'currency': _walletCurrency,
        'isBaseCurrency': true,
        'decimalPrecision': _walletDecimalPrecision,
        'balance': _walletBalance,
        'emojiIcon': _walletEmoji,
        'colorCode': colorCode,
      });

      if (walletError != null) {
        throw Exception(walletError);
      }

      // Save base currency in Preferences
      final prefs = ref.read(preferencesServiceProvider);
      await prefs.setCurrencyCode(_walletCurrency);
      await prefs.setProfileComplete(true);
      ref.invalidate(profileProvider);

      if (!mounted) return;
      context.go('/home/dashboard');
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

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';
  }

  void _showWalletEmojiPicker() {
    CustomEmojiPickerSheet.show(
      context: context,
      onEmojiSelected: (emoji) {
        setState(() {
          _walletEmoji = emoji;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _showWalletColorPicker() async {
    final newColor = await showCustomColorPicker(
      context: context,
      initialColor: _walletColor,
    );
    if (newColor != null) {
      setState(() => _walletColor = newColor);
    }
  }

  void _showWalletDecimalPrecisionSheet() {
    AppBottomSheet.show(
      context: context,
      builder: (_) => _DecimalPrecisionSheet(
        initialPrecision: _walletDecimalPrecision,
        onSave: (val) {
          setState(() {
            _walletDecimalPrecision = val;
          });
        },
      ),
    );
  }

  void _showWalletBalanceCalculatorSheet() {
    AmountCalculatorSheet.show(
      context,
      initialAmount: _walletBalance,
      initialCurrency: _walletCurrency,
      decimalPrecision: _walletDecimalPrecision,
      title: l10n.initialBalance,
      description: l10n.languageCode == 'id'
          ? 'Saldo awal untuk memulai pencatatan wallet'
          : 'Initial balance to start tracking wallet',
      onSave: (amount, currency) {
        setState(() {
          _walletBalance = amount;
          _walletCurrency = currency;
        });
      },
    );
  }

  String _formatPreviewAmount(double value) {
    return CurrencyFormatter.formatAmount(value, decimalPrecision: _walletDecimalPrecision);
  }

  String _getCountryForCurrency(String code) {
    switch (code) {
      case 'IDR': return 'Indonesia';
      case 'USD': return 'United States';
      case 'EUR': return 'Euro Member';
      case 'SGD': return 'Singapore';
      case 'MYR': return 'Malaysia';
      case 'GBP': return 'United Kingdom';
      case 'JPY': return 'Japan';
      case 'AUD': return 'Australia';
      default: return '';
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
        buttonAction = () => _navigateToStep(2);
        isButtonEnabled = true;
      }
    } else if (_currentStep == 2) {
      if (!_isPhoneVerified) {
        if (!_otpSent) {
          buttonText = l10n.sendOtpCode;
          buttonAction = _isSendingOtp ? null : _sendOtp;
          isButtonEnabled = true;
        } else {
          buttonText = l10n.verifyAndSave;
          buttonAction = (_isVerifying || _otpController.text.length != 6) ? null : _verifyOtp;
          isButtonEnabled = _otpController.text.length == 6;
        }
      } else {
        buttonText = l10n.continueButton;
        buttonAction = () => _navigateToStep(3);
        isButtonEnabled = true;
      }
    } else {
      // Step 3
      buttonText = l10n.saveAndFinishOnboarding;
      buttonAction = _isSaving ? null : _saveProfile;
      isButtonEnabled = _walletNameController.text.trim().isNotEmpty;
    }

    final iconShape = ref.watch(categoryIconShapeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: _currentStep == 2
            ? IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                onPressed: () => _navigateToStep(1),
              )
            : (_currentStep == 3
                ? IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    onPressed: () => _navigateToStep(2),
                  )
                : null),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top step progress indicator (statically placed at the top of the body)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.33,
                        end: _currentStep == 1 ? 0.33 : (_currentStep == 2 ? 0.66 : 1.0),
                      ),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: isDark ? Colors.white10 : AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _currentStep == 1 ? 'Step 1/3' : (_currentStep == 2 ? 'Step 2/3' : 'Step 3/3'),
                    style: AppTypography.textTheme.labelSmall?.copyWith(color: hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Horizontal Slide PageView
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ProfileSetupStep1(
                        fullName: _fullName,
                        username: _username,
                        bio: _bio,
                        birthdateDisplay: birthdateDisplay,
                        genderDisplay: genderDisplay,
                        selectedAvatarUrl: _selectedAvatarUrl,
                        selectedLocalFile: _selectedLocalFile,
                        selectedBorderAsset: _selectedBorderAsset,
                        fallback: fallback,
                        hintColor: hintColor,
                        onAvatarEditTap: _showAvatarEditSheet,
                        onFullNameTap: _showEditNameSheet,
                        onUsernameTap: _showEditUsernameSheet,
                        onBioTap: _showEditBioSheet,
                        onBirthdateTap: _pickDate,
                        onGenderTap: _showEditGenderSheet,
                        buildInfoTile: _buildInfoTile,
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ProfileSetupStep2(
                        phoneController: _phoneController,
                        otpController: _otpController,
                        otpSent: _otpSent,
                        isPhoneVerified: _isPhoneVerified,
                        secondsRemaining: _secondsRemaining,
                        isSendingOtp: _isSendingOtp,
                        isDark: isDark,
                        hintColor: hintColor,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        onSendOtp: _sendOtp,
                        onVerifyOtp: _verifyOtp,
                        onChangePhoneNumber: () => setState(() {
                          _otpSent = false;
                          _otpController.clear();
                        }),
                        formatTimer: _formatTimer,
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ProfileSetupStep3(
                        walletNameController: _walletNameController,
                        walletType: _walletType,
                        walletCurrency: _walletCurrency,
                        walletBalance: _walletBalance,
                        walletEmoji: _walletEmoji,
                        walletColor: _walletColor,
                        walletDecimalPrecision: _walletDecimalPrecision,
                        walletPresetColors: _walletPresetColors,
                        isDark: isDark,
                        hintColor: hintColor,
                        iconShape: iconShape,
                        onWalletEmojiTap: _showWalletEmojiPicker,
                        onWalletColorTap: _showWalletColorPicker,
                        onWalletColorSelected: (color) => setState(() => _walletColor = color),
                        onWalletTypeChanged: (val) {
                          if (val != null) {
                            setState(() => _walletType = val);
                          }
                        },
                        onWalletDecimalPrecisionTap: _showWalletDecimalPrecisionSheet,
                        onWalletBalanceTap: _showWalletBalanceCalculatorSheet,
                        formatPreviewAmount: _formatPreviewAmount,
                        getCountryForCurrency: _getCountryForCurrency,
                        onWalletCurrencyChanged: (code) => setState(() => _walletCurrency = code),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecimalPrecisionSheet extends StatefulWidget {
  const _DecimalPrecisionSheet({
    required this.initialPrecision,
    required this.onSave,
  });

  final int initialPrecision;
  final void Function(int precision) onSave;

  @override
  State<_DecimalPrecisionSheet> createState() => _DecimalPrecisionSheetState();
}

class _DecimalPrecisionSheetState extends State<_DecimalPrecisionSheet> {
  String? _typedStr;
  String? _pressedKey;

  String get _displayStr => _typedStr ?? widget.initialPrecision.toString();

  void _onKeyPress(String key) {
    setState(() {
      _pressedKey = key;
      if (key == '⌫') {
        if (_typedStr != null && _typedStr!.isNotEmpty) {
          final next = _typedStr!.substring(0, _typedStr!.length - 1);
          _typedStr = next.isEmpty ? null : next;
        }
      } else if (key == ',') {
        // Precision is integer only, ignore
      } else {
        if (_typedStr == null) {
          _typedStr = key == '0' ? '0' : key;
        } else {
          if (_typedStr == '0') {
            _typedStr = key;
          } else if (_typedStr!.length < 2) {
            _typedStr = _typedStr! + key;
          }
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 130), () {
      if (mounted) setState(() => _pressedKey = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.walletDecimalPrecision,
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.walletDecimalPrecisionSheetDesc,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              _displayStr,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  _buildKey('1'),
                  _buildKey('2'),
                  _buildKey('3'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildKey('4'),
                  _buildKey('5'),
                  _buildKey('6'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildKey('7'),
                  _buildKey('8'),
                  _buildKey('9'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: const SizedBox()),
                  _buildKey('0'),
                  _buildKey('⌫'),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final val = int.tryParse(_displayStr) ?? widget.initialPrecision;
                widget.onSave(val);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.saveButton,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPressed = _pressedKey == label;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isPressed
              ? AppColors.primary.withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _onKeyPress(label),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
