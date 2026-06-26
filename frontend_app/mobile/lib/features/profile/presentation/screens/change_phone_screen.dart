import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../providers/profile_provider.dart';

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSendingOtp = true;
    });

    // Simulate OTP sending to WhatsApp
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isSendingOtp = false;
        _otpSent = true;
      });

      final phoneNumber = _phoneController.text.trim();
      AppSnackbar.show(
        context,
        title: AppLocalizations.of(context).languageCode == 'id' ? 'OTP Terkirim' : 'OTP Sent',
        message: AppLocalizations.of(context).languageCode == 'id'
            ? 'Kode OTP verifikasi telah dikirimkan ke WhatsApp nomor $phoneNumber'
            : 'OTP verification code has been sent to WhatsApp number $phoneNumber',
        type: SnackbarType.success,
      );
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text;
    if (code.length != 6) return;

    setState(() {
      _isVerifying = true;
    });

    // Simulate verification checking (code: 123456)
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      if (code == '123456') {
        try {
          final repo = ref.read(profileRepositoryProvider);
          await repo.updateProfile(phoneNumber: _phoneController.text.trim());
          ref.invalidate(profileProvider);

          if (mounted) {
            AppSnackbar.show(
              context,
              title: AppLocalizations.of(context).languageCode == 'id' ? 'Sukses' : 'Success',
              message: AppLocalizations.of(context).languageCode == 'id'
                  ? 'Nomor telepon Anda berhasil diperbarui!'
                  : 'Your phone number has been updated successfully!',
              type: SnackbarType.success,
            );
            Navigator.of(context).pop(); // Go back to account screen
          }
        } catch (e) {
          if (mounted) {
            AppSnackbar.show(
              context,
              title: AppLocalizations.of(context).languageCode == 'id' ? 'Gagal' : 'Failed',
              message: 'Error updating phone: $e',
              type: SnackbarType.error,
            );
          }
        }
      } else {
        AppSnackbar.show(
          context,
          title: AppLocalizations.of(context).languageCode == 'id' ? 'Kode Salah' : 'Invalid Code',
          message: AppLocalizations.of(context).languageCode == 'id'
              ? 'Kode OTP yang Anda masukkan salah. Gunakan kode "123456" untuk uji coba.'
              : 'The OTP code entered is incorrect. Use code "123456" for testing.',
          type: SnackbarType.error,
        );
      }

      setState(() {
        _isVerifying = false;
      });
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.languageCode == 'id' ? 'Ubah Nomor Telepon' : 'Change Phone Number',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.languageCode == 'id'
                    ? 'Masukkan nomor telepon WhatsApp terbaru Anda. Kami akan mengirimkan kode verifikasi OTP ke nomor ini.'
                    : 'Enter your latest WhatsApp phone number. We will send an OTP verification code to this number.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_otpSent,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: l10n.languageCode == 'id' ? 'Nomor Telepon WhatsApp' : 'WhatsApp Phone Number',
                  hintText: 'e.g. +6282113285557',
                  labelStyle: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
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
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.languageCode == 'id'
                        ? 'Nomor telepon wajib diisi'
                        : 'Phone number is required';
                  }
                  if (!value.startsWith('+') && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return l10n.languageCode == 'id'
                        ? 'Format nomor telepon tidak valid'
                        : 'Invalid phone number format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (!_otpSent) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSendingOtp ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSendingOtp
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.languageCode == 'id' ? 'Kirim Kode OTP' : 'Send OTP Code',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
              if (_otpSent) ...[
                const SizedBox(height: 24),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 24),
                Text(
                  l10n.languageCode == 'id'
                      ? 'Masukkan 6 Digit Kode OTP WhatsApp:'
                      : 'Enter 6 Digit WhatsApp OTP Code:',
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
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    l10n.languageCode == 'id'
                      ? 'Gunakan kode demo: "123456"'
                      : 'Use demo code: "123456"',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.languageCode == 'id' ? 'Verifikasi & Simpan' : 'Verify & Save',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _otpSent = false),
                    child: Text(
                      l10n.languageCode == 'id' ? 'Ganti nomor telepon' : 'Change phone number',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
