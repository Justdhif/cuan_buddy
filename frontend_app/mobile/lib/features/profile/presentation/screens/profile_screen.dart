import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/constants/app_constants.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _showCurrencyPicker(String currentCurrency) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CurrencyPickerSheet(
        currentCode: currentCurrency,
        l10n: l10n,
        onSelect: (code) async {
          Navigator.pop(ctx);
          try {
            await ref.read(profileRepositoryProvider).updateProfile(currency: code);
            ref.invalidate(profileProvider);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update currency: $e')),
              );
            }
          }
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
        titleSpacing: 24,
        title: GestureDetector(
          onTap: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
          child: Text(l10n.profile),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
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

    final username = profile['username'] as String?;
    final bio = profile['bio'] as String?;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        children: [
          // ─── Profile Header ───────────────────────────────────────────────
          Row(
            children: [
              Hero(
                tag: 'avatar',
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: validAvatar != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: validAvatar,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(strokeWidth: 3),
                            errorWidget: (context, url, error) => Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (username != null && username.isNotEmpty)
                      Text(
                        '@$username',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      name,
                      style: AppTypography.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bio Section
          Align(
            alignment: Alignment.centerLeft,
            child: (bio != null && bio.isNotEmpty)
                ? Text(
                    bio,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  )
                : Text(
                    l10n.noBioFallback,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                          : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.edit_outlined,
                  label: l10n.editProfile,
                  onTap: () => context.push('/profile/edit', extra: profile),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.lock_outline,
                  label: l10n.changePassword,
                  onTap: () => context.push('/change-password'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            icon: Icons.logout_rounded,
            label: l10n.logOut,
            isDanger: true,
            isHorizontal: true,
            onTap: () => _logout(context, ref),
          ),
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
                trailing: Row(
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
                onTap: () => _showCurrencyPicker(currency),
              ),
              _buildListTile(
                context,
                icon: Icons.widgets_outlined,
                title: 'Widget Settings',
                onTap: () => context.push('/profile/widgets'),
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
    bool isHorizontal = false,
  }) {
    final color = isDanger ? AppColors.danger : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: isHorizontal ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: isHorizontal
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTypography.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
  const _CurrencyPickerSheet({
    required this.currentCode,
    required this.l10n,
    required this.onSelect,
  });

  final String currentCode;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.currency,
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: AppConstants.supportedCurrencies.length,
                  separatorBuilder: (context, index) => Divider(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final curr = AppConstants.supportedCurrencies[index];
                    final isSelected = curr['code'] == currentCode;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                          shape: BoxShape.circle,
                        ),
                        child: Text(curr['symbol']!),
                      ),
                      title: Text(curr['name']!, style: AppTypography.textTheme.bodyLarge),
                      subtitle: Text(curr['code']!, style: AppTypography.textTheme.bodySmall),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      onTap: () => onSelect(curr['code']!),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
