import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/providers/core_providers.dart';
import '../../presentation/providers/profile_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;


  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
      await ref.read(preferencesServiceProvider).setProfileComplete(true);
      if (!mounted) return;
      context.go('/wallet-setup');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context,
          title: l10n.error,
          message: '${l10n.failedToSaveProfile}: $e',
          type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skip() async {
    await ref.read(preferencesServiceProvider).setProfileComplete(true);
    if (!mounted) return;
    context.go('/wallet-setup');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: AppColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.step1of2,
                      style: AppTypography.textTheme.labelSmall
                          ?.copyWith(color: AppColors.textSecondaryLight)),
                ],
              ),
              const SizedBox(height: 32),
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                l10n.completeYourProfile,
                style: AppTypography.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.profileSetupSubtitle,
                style: AppTypography.textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _fullNameController,
                      label: l10n.fullName,
                      hint: l10n.fullNameHint,
                      keyboardType: TextInputType.name,
                      prefixIcon:
                          const Icon(Icons.person_outline_rounded, size: 20),
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
                      controller: _phoneController,
                      label: l10n.phoneNumberField,
                      hint: '+62 812 3456 7890',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 40),
                    AppButton(
                      label: l10n.continueButton,
                      onPressed: _saveProfile,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: l10n.skip,
                      onPressed: _skip,
                      type: AppButtonType.text,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
