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
  String _selectedCurrency = 'IDR';

  final List<Map<String, String>> _currencies = [
    {'code': 'IDR', 'name': 'Indonesian Rupiah (IDR)', 'symbol': 'Rp'},
    {'code': 'USD', 'name': 'US Dollar (USD)', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro (EUR)', 'symbol': '€'},
    {'code': 'SGD', 'name': 'Singapore Dollar (SGD)', 'symbol': 'S\$'},
  ];

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
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            currency: _selectedCurrency,
          );
      await ref.read(preferencesServiceProvider).setProfileComplete(true);
      await ref
          .read(preferencesServiceProvider)
          .setCurrencyCode(_selectedCurrency);
      if (!mounted) return;
      context.go('/backup-settings');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, title: l10n.error, message: '${l10n.failedToSaveProfile}: $e', type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skip() async {
    await ref.read(preferencesServiceProvider).setProfileComplete(true);
    if (!mounted) return;
    context.go('/backup-settings');
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
                        if (v == null || v.isEmpty) return l10n.fullNameRequired;
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
                    Text(l10n.currency,
                        style: AppTypography.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.surfaceDark
                            : const Color(0xFFF8F7FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          borderRadius: BorderRadius.circular(16),
                          items: _currencies.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['code'],
                              child: Text('${c['symbol']} ${c['name']}'),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCurrency = v ?? 'IDR'),
                        ),
                      ),
                    ),
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
