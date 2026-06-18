import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _resetSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first 😊')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(
            email: _emailController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your email 📧'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, title: 'Info', message: e.toString(), type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _emailController.text.trim(),
            otp: _otpController.text.trim(),
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      setState(() => _resetSuccess = true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, title: 'Info', message: e.toString(), type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(Icons.arrow_back_ios_rounded),
              ),
              const SizedBox(height: 24),
              if (_resetSuccess)
                _buildSuccess(context)
              else ...[
                Text(
                  'Forgot Password? 🔐',
                  style: AppTypography.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _otpSent
                      ? 'Enter the OTP sent to your email'
                      : 'Enter your email to receive an OTP code',
                  style: AppTypography.textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'email@example.com',
                        keyboardType: TextInputType.emailAddress,
                        readOnly: _otpSent,
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Email is required' : null,
                      ),
                      if (!_otpSent) ...[
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Send OTP',
                          onPressed: _sendOtp,
                          isLoading: _isLoading,
                        ),
                      ],
                      if (_otpSent) ...[
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _otpController,
                          label: 'OTP Code',
                          hint: '6-digit OTP code',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.key_rounded, size: 20),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'OTP is required' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          hint: 'Minimum 8 characters',
                          isPassword: true,
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 20),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 8) return 'Password must be at least 8 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Reset Password',
                          onPressed: _resetPassword,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Resend OTP',
                          onPressed: _sendOtp,
                          type: AppButtonType.text,
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
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text('Password successfully changed!',
                style: AppTypography.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'You can now log in with your new password',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Log In Now',
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
