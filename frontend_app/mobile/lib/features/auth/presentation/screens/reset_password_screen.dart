import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordScreen(
      {super.key, required this.email, required this.otp});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _resetSuccess = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      AppSnackbar.show(
        context,
        title: l10n.info,
        message: 'Passwords do not match',
        type: SnackbarType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: widget.email,
            otp: widget.otp,
            newPassword: _newPasswordController.text,
          );

      // If user was logged in (e.g., accessed from profile), log them out
      await ref.read(authNotifierProvider.notifier).logout();

      if (!mounted) return;
      setState(() => _resetSuccess = true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context,
          title: l10n.info, message: e.toString(), type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              if (!_resetSuccess)
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
              const SizedBox(height: 24),
              if (_resetSuccess)
                _buildSuccess(context, l10n)
              else ...[
                Text(
                  l10n.resetPassword,
                  style: AppTypography.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your new password below.',
                  style: AppTypography.textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _newPasswordController,
                        label: l10n.newPassword,
                        hint: l10n.passwordMinHint,
                        isPassword: true,
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded, size: 20),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.passwordRequired;
                          }
                          if (v.length < 8) return l10n.passwordMin8;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: l10n.passwordMinHint,
                        isPassword: true,
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded, size: 20),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.passwordRequired;
                          }
                          if (v != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: l10n.resetPassword,
                        onPressed: _resetPassword,
                        isLoading: _isLoading,
                      ),
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

  Widget _buildSuccess(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(l10n.passwordChangedSuccess,
                style: AppTypography.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(l10n.canNowLoginNewPassword,
                style: AppTypography.textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            AppButton(
              label: l10n.backToLogin,
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
