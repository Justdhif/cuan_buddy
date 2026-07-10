import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  final String email;
  const ForgotPasswordOtpScreen({super.key, required this.email});

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState
    extends ConsumerState<ForgotPasswordOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _resendTimer = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(email: widget.email);
      if (!mounted) return;
      AppSnackbar.show(
        context,
        title: l10n.success,
        message: l10n.otpSentToEmail,
        type: SnackbarType.success,
      );
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context,
          title: l10n.info, message: e.toString(), type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onVerify() {
    final l10n = AppLocalizations.of(context);
    if (_otpController.text.length < 6) {
      AppSnackbar.show(
        context,
        title: l10n.info,
        message: l10n.otpRequired,
        type: SnackbarType.warning,
      );
      return;
    }
    context.push(
        '/forgot-password/reset?email=${Uri.encodeComponent(widget.email)}&otp=${_otpController.text}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: AppTypography.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primary, width: 2),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.enterOtpSentToEmail,
                style: AppTypography.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.otpSentToEmail}: ${widget.email}',
                style: AppTypography.textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 32),
              Center(
                child: Pinput(
                  controller: _otpController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  onCompleted: (pin) => _onVerify(),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Verify OTP',
                onPressed: _onVerify,
              ),
              const SizedBox(height: 24),
              Center(
                child: _resendTimer > 0
                    ? Text(
                        'Resend OTP in $_resendTimer s',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      )
                    : AppButton(
                        label: l10n.resendOtp,
                        onPressed: _isLoading ? null : _resendOtp,
                        type: AppButtonType.text,
                        isLoading: _isLoading,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
