import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context);
    
    try {
      final repo = ref.read(authRepositoryProvider);
      final message = await repo.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      
      if (mounted) {
        AppSnackbar.show(
          context, 
          title: l10n.success, 
          message: message, 
          type: SnackbarType.success,
        );
        
        // Log out immediately upon success
        ref.read(authNotifierProvider.notifier).logout();
        // Go Router will naturally redirect to login because of auth state change
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context, 
          title: l10n.error, 
          message: e.toString(), 
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.changePassword),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
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
                l10n.changePasswordInfo,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),
              
              // ─── Old Password ─────────────────────────────────────────────
              AppTextField(
                controller: _oldPasswordController,
                label: l10n.oldPassword,
                hint: l10n.oldPasswordHint,
                isPassword: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return l10n.oldPasswordRequired;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // ─── Forgot Password Link ─────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(
                    l10n.forgotPassword,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // ─── New Password ─────────────────────────────────────────────
              AppTextField(
                controller: _newPasswordController,
                label: l10n.newPassword,
                hint: l10n.newPasswordHint,
                isPassword: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return l10n.passwordRequired;
                  if (val.length < 8) return l10n.passwordMin8;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // ─── Confirm New Password ─────────────────────────────────────
              AppTextField(
                controller: _confirmPasswordController,
                label: l10n.confirmPassword,
                hint: l10n.confirmNewPasswordHint,
                isPassword: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return l10n.confirmPasswordRequired;
                  if (val != _newPasswordController.text) return l10n.passwordsDoNotMatch;
                  return null;
                },
              ),
              const SizedBox(height: 40),
              
              // ─── Submit Button ────────────────────────────────────────────
              AppButton(
                label: l10n.changePassword,
                onPressed: _submit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
