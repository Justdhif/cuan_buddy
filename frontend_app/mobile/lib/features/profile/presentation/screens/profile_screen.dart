import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSavingCurrency = false;

  Future<void> _showCurrencyPicker(
    BuildContext context,
    String currentCurrency,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CurrencyPickerSheet(currentCurrency: currentCurrency),
    );

    if (selected != null && selected != currentCurrency) {
      if (!context.mounted) return;
      setState(() => _isSavingCurrency = true);
      try {
        await ref
            .read(profileRepositoryProvider)
            .updateProfile(currency: selected);
        await ref.read(preferencesServiceProvider).setCurrencyCode(selected);
        ref.invalidate(profileProvider);
        if (context.mounted) {
          AppSnackbar.show(
            context,
            title: l10n.success,
            message: l10n.currencyUpdatedTo(selected),
            type: SnackbarType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            title: l10n.failed,
            message: l10n.failedToUpdateCurrency,
            type: SnackbarType.error,
          );
        }
      } finally {
        if (mounted) setState(() => _isSavingCurrency = false);
      }
    }
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final currentCode = ref.read(languageProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _LanguagePickerSheet(
        currentCode: currentCode,
        l10n: l10n,
        onSelect: (code) async {
          Navigator.pop(ctx);
          await ref.read(languageProvider.notifier).setLanguage(code);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthStateUnauthenticated) {
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.profile),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (profile) => _buildProfileContent(context, ref, profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AppErrorState(
          message: l10n.failedToLoadProfile,
          onRetry: () => ref.invalidate(profileProvider),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
      BuildContext context, WidgetRef ref, Map<String, dynamic> profile) {
    final l10n = AppLocalizations.of(context);
    final name = profile['fullName'] as String? ?? l10n.you;
    final email = profile['email'] as String? ?? '';
    final avatar = profile['avatar'] as String?;
    final currency = profile['currency'] as String? ?? 'IDR';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentLangCode = ref.watch(languageProvider);

    // Backend now stores PNG URL directly.
    final validAvatar = avatar;

    // Find currency symbol
    final currencyInfo = AppConstants.supportedCurrencies.firstWhere(
      (c) => c['code'] == currency,
      orElse: () => {'code': currency, 'name': currency, 'symbol': currency},
    );

    // Language display name
    final langDisplayName = currentLangCode == 'id' ? 'Indonesia' : 'English';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        children: [
          // ─── Avatar ─────────────────────────────────────────────────
          Hero(
            tag: 'avatar',
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: validAvatar != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: validAvatar,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(strokeWidth: 3),
                        errorWidget: (context, url, error) => Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 40,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 40,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(name,
              style: AppTypography.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(email,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              )),
          const SizedBox(height: 32),

          // ─── Preferences ────────────────────────────────────────────
          _buildSection(
            context,
            title: l10n.preferences,
            children: [
              _buildListTile(
                context,
                icon: Icons.dark_mode_outlined,
                title: l10n.darkMode,
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (v) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                          v ? ThemeMode.dark : ThemeMode.light,
                        );
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              _buildListTile(
                context,
                icon: Icons.language_outlined,
                title: l10n.language,
                trailing: Text(langDisplayName,
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    )),
                onTap: () => _showLanguagePicker(context),
              ),
              _buildListTile(
                context,
                icon: Icons.attach_money_rounded,
                title: l10n.currency,
                trailing: _isSavingCurrency
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${currencyInfo['symbol']} ${currencyInfo['code']}',
                            style: TextStyle(
                                color: isDarkMode
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ],
                      ),
                onTap: _isSavingCurrency
                    ? null
                    : () => _showCurrencyPicker(context, currency),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Account ────────────────────────────────────────────────
          _buildSection(
            context,
            title: l10n.account,
            children: [
              _buildListTile(
                context,
                icon: Icons.category_outlined,
                title: l10n.manageCategories,
                onTap: () => context.push('/home/manage-categories'),
              ),
              _buildListTile(
                context,
                icon: Icons.backup_outlined,
                title: l10n.backupRestore,
                onTap: () => context.push('/profile/backup'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l10n.editProfile,
            onPressed: () => context.push('/profile/edit', extra: profile),
            type: AppButtonType.outlined,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.logOut,
            onPressed: () => _logout(context, ref),
            type: AppButtonType.outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTypography.textTheme.titleSmall
                ?.copyWith(color: AppColors.primary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark
                : AppColors.borderLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight;
    final arrowColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: AppTypography.textTheme.bodyLarge),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: arrowColor),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logOutTitle),
        content: Text(l10n.logOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

// ─── Language Picker Sheet ────────────────────────────────────────────────────
class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({
    required this.currentCode,
    required this.l10n,
    required this.onSelect,
  });

  final String currentCode;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelect;

  static const _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'native': 'English'},
    {'code': 'id', 'name': 'Indonesia', 'flag': '🇮🇩', 'native': 'Bahasa Indonesia'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              l10n.selectLanguage,
              style: AppTypography.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            ..._languages.map((lang) {
              final isSelected = lang['code'] == currentCode;
              return GestureDetector(
                onTap: () => onSelect(lang['code']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark
                            ? AppColors.surfaceDark
                            : AppColors.borderLight.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang['name']!,
                              style: AppTypography.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                            Text(
                              lang['native']!,
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Currency Picker Sheet ────────────────────────────────────────────────────
class _CurrencyPickerSheet extends StatelessWidget {
  const _CurrencyPickerSheet({required this.currentCurrency});
  final String currentCurrency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.selectCurrency,
              style: AppTypography.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
              itemCount: AppConstants.supportedCurrencies.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final currency = AppConstants.supportedCurrencies[index];
                final isSelected = currency['code'] == currentCurrency;
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.borderLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        currency['symbol']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    currency['code']!,
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  subtitle: Text(
                    currency['name']!,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, currency['code']),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
