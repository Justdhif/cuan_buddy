import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';

class ProfileSetupStep2 extends StatelessWidget {
  const ProfileSetupStep2({
    super.key,
    required this.phoneController,
    required this.otpController,
    required this.otpSent,
    required this.isPhoneVerified,
    required this.secondsRemaining,
    required this.isSendingOtp,
    required this.isDark,
    required this.hintColor,
    required this.defaultPinTheme,
    required this.focusedPinTheme,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onChangePhoneNumber,
    required this.formatTimer,
  });

  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool otpSent;
  final bool isPhoneVerified;
  final int secondsRemaining;
  final bool isSendingOtp;
  final bool isDark;
  final Color hintColor;
  final PinTheme defaultPinTheme;
  final PinTheme focusedPinTheme;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onChangePhoneNumber;
  final String Function(int) formatTimer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Subtitle for Step 2
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.whatsappVerificationTitle,
                style: AppTypography.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.whatsappVerificationSubtitle,
                style: AppTypography.textTheme.bodyLarge?.copyWith(color: hintColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

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
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                enabled: !otpSent && !isPhoneVerified,
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
                  suffixIcon: isPhoneVerified
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      : null,
                ),
              ),

              // Inline OTP Pinput Area
              if (otpSent && !isPhoneVerified) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.enterOtpTitle,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Pinput(
                    controller: otpController,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    onCompleted: (_) => onVerifyOtp(),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(
                        secondsRemaining > 0
                            ? l10n.resendCodeIn(formatTimer(secondsRemaining))
                            : l10n.didNotReceiveCode,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (secondsRemaining == 0) ...[
                            TextButton(
                              onPressed: isSendingOtp ? null : onSendOtp,
                              child: Text(
                                l10n.resendAction,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          TextButton(
                            onPressed: onChangePhoneNumber,
                            child: Text(
                              l10n.changePhoneNumberLink,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
