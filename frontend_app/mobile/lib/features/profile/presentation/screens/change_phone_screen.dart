import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/providers/core_providers.dart';
import '../providers/profile_provider.dart';
import '../../../../core/widgets/form_pop_scope.dart';

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  String _selectedCountryCode = '+62';
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _isVerifying = false;

  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _fullPhoneNumber {
    var number = _phoneController.text.trim();
    if (number.startsWith('0')) {
      number = number.substring(1);
    }
    return '';
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 300;
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

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    final phone = _fullPhoneNumber;

    setState(() {
      _isSendingOtp = true;
    });

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
        setState(() {
          _isSendingOtp = false;
        });
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: 'Failed to send OTP: ',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text;
    if (code.length != 6) return;

    final l10n = AppLocalizations.of(context);
    final phone = _fullPhoneNumber;

    setState(() {
      _isVerifying = true;
    });

    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/profiles/phone/verify-otp', data: {'phone': phone, 'code': code});

      ref.invalidate(profileProvider);

      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.otpSuccessTitle,
          message: l10n.otpSuccessMessage,
          type: SnackbarType.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.otpFailedTitle,
          message: 'Failed to verify OTP: ',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final isDirty = !_isVerifying &&
        !_isSendingOtp &&
        (_phoneController.text.isNotEmpty || _otpController.text.isNotEmpty);

    return FormPopScope(
      hasUnsavedChanges: isDirty,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            l10n.changePhoneNumberTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
        ),
        bottomNavigationBar: GestureDetector(
          onTap: _otpSent
              ? (_isVerifying ? null : _verifyOtp)
              : (_isSendingOtp ? null : _sendOtp),
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
                child: (_otpSent ? _isVerifying : _isSendingOtp)
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _otpSent ? Icons.check_circle_outline_rounded : Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _otpSent ? l10n.verifyAndSave : l10n.sendOtpCode,
                              style: AppTypography.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.changePhoneNumberSubtitle,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCountryCode,
                        items: const [
                          DropdownMenuItem(value: '+62', child: Text('+62 (ID)')),
                          DropdownMenuItem(value: '+1', child: Text('+1 (US)')),
                          DropdownMenuItem(value: '+60', child: Text('+60 (MY)')),
                          DropdownMenuItem(value: '+65', child: Text('+65 (SG)')),
                          DropdownMenuItem(value: '+61', child: Text('+61 (AU)')),
                          DropdownMenuItem(value: '+44', child: Text('+44 (GB)')),
                          DropdownMenuItem(value: '+81', child: Text('+81 (JP)')),
                          DropdownMenuItem(value: '+82', child: Text('+82 (KR)')),
                          DropdownMenuItem(value: '+86', child: Text('+86 (CN)')),
                        ],
                        onChanged: _otpSent
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCountryCode = value;
                                  });
                                }
                              },
                        decoration: InputDecoration(
                          labelText: 'Kode',
                          labelStyle: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.defaultPrimary, width: 2),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDark ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight.withValues(alpha: 0.5)),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !_otpSent,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.whatsappPhoneNumber,
                          hintText: '82113285557',
                          labelStyle: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.defaultPrimary, width: 2),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDark ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight.withValues(alpha: 0.5)),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.defaultPrimary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.phoneNumberRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 24),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 24),
                  Text(
                    l10n.enterOtpTitle,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          ? 'Kirim ulang kode dalam ${_formatTimer(_secondsRemaining)}'
                          : 'Tidak menerima kode?',
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
                        child: const Text(
                          'Kirim Ulang',
                          style: TextStyle(
                            color: AppColors.defaultPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _otpSent = false),
                      child: Text(
                        l10n.changePhoneNumberLink,
                        style: const TextStyle(color: AppColors.defaultPrimary, fontWeight: FontWeight.w600),
                      ),
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
