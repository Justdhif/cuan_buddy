import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
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
            await ref
                .read(profileRepositoryProvider)
                .updateProfile(currency: code);
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
        titleSpacing: Navigator.of(context).canPop() ? 0 : 24,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: GestureDetector(
          onTap: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
          child: Text(
            l10n.languageCode == 'id' ? 'Profil' : 'Profile',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
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

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDanger
        ? AppColors.danger
        : (isDark ? Colors.white : Colors.black87);
    final subtitleColor = isDanger
        ? AppColors.danger.withValues(alpha: 0.8)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDanger
                  ? AppColors.danger
                  : (isDark ? Colors.white60 : Colors.black54),
              size: 24,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    final validAvatar = avatar;
    final username = profile['username'] as String?;
    final bio = profile['bio'] as String?;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 120),
      child: Column(
        children: [
          // Profile Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () => context.push('/profile/edit', extra: profile),
              behavior: HitTestBehavior.opaque,
              child: Row(
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
            ),
          ),
          const SizedBox(height: 16),
          // Bio Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () => context.push('/profile/edit', extra: profile),
              behavior: HitTestBehavior.opaque,
              child: Align(
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
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 8),

          // Settings List Tiles
          _buildSettingsTile(
            context: context,
            icon: Icons.key_outlined,
            title: l10n.languageCode == 'id' ? 'Akun' : 'Account',
            subtitle: l10n.languageCode == 'id'
                ? 'Notifikasi keamanan, ganti nomor'
                : 'Security notification, change number',
            onTap: () => context.push('/profile/account'),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.palette_outlined,
            title: l10n.languageCode == 'id' ? 'Tampilan' : 'Appearance',
            subtitle: l10n.languageCode == 'id'
                ? 'Tema, bahasa aplikasi'
                : 'Theme, app language',
            onTap: () => context.push('/profile/theme-language'),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.attach_money_rounded,
            title: l10n.currency,
            subtitle: currency,
            onTap: () => _showCurrencyPicker(currency),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.category_outlined,
            title: l10n.manageCategories,
            subtitle: l10n.languageCode == 'id'
                ? 'Kelola kategori transaksi'
                : 'Manage transaction categories',
            onTap: () => context.push('/manage-categories'),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.widgets_outlined,
            title: 'Widgets',
            subtitle: l10n.languageCode == 'id'
                ? 'Atur widget layar depan'
                : 'Configure home screen widgets',
            onTap: () => context.push('/profile/widgets'),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.backup_outlined,
            title: l10n.backupRestore,
            subtitle: l10n.languageCode == 'id'
                ? 'Cadangkan dan pulihkan data Anda'
                : 'Backup and restore your data',
            onTap: () => context.push('/profile/backup'),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.info_outline_rounded,
            title: l10n.about,
            subtitle: l10n.languageCode == 'id'
                ? 'Informasi tentang aplikasi'
                : 'Information about the app',
            onTap: () => _showAboutAppSheet(context),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.feedback_outlined,
            title: l10n.feedback,
            subtitle: l10n.languageCode == 'id'
                ? 'Kirim saran atau laporkan masalah'
                : 'Send suggestions or report bugs',
            onTap: () => _showFeedbackSheet(context),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.logout_rounded,
            title: l10n.logOut,
            subtitle: l10n.languageCode == 'id'
                ? 'Keluar dari akun Anda saat ini'
                : 'Log out of your current account',
            isDanger: true,
            onTap: () => _logout(context, ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
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




  Future<void> _showAboutAppSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> launchURL(String urlString) async {
      final Uri url = Uri.parse(urlString);
      try {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not launch $urlString')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error launching link: $e')),
          );
        }
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AboutAppSheet(
        isDark: isDark,
        l10n: l10n,
        onLinkTap: launchURL,
      ),
    );
  }

  Future<void> _showFeedbackSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const _FeedbackSheet(),
      ),
    );
  }
}

// ─── About App Sheet ──────────────────────────────────────────────────────────
class _AboutAppSheet extends StatelessWidget {
  const _AboutAppSheet({
    required this.isDark,
    required this.l10n,
    required this.onLinkTap,
  });

  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<String> onLinkTap;

  @override
  Widget build(BuildContext context) {
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'CuanBuddy',
              style: AppTypography.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0 (Beta)',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.languageCode == 'id'
                  ? 'CuanBuddy adalah asisten finansial pintar Anda untuk mencatat transaksi, mengelola anggaran, dan memantau kesehatan finansial dengan bantuan teknologi AI.'
                  : 'CuanBuddy is your smart financial assistant to track transactions, manage budgets, and monitor financial health with AI support.',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.languageCode == 'id' ? 'Hubungi kami di:' : 'Connect with us:',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFFE1306C), size: 30),
                  onPressed: () => onLinkTap('https://instagram.com/justdhif'),
                  tooltip: 'Instagram',
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => onLinkTap('https://x.com/justdhif'),
                  tooltip: 'X (Twitter)',
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 28),
                  onPressed: () => onLinkTap('https://wa.me/628123456789'),
                  tooltip: 'WhatsApp',
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.close,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feedback Sheet ───────────────────────────────────────────────────────────
class _FeedbackSheet extends ConsumerStatefulWidget {
  const _FeedbackSheet();

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(profileRepositoryProvider)
          .submitFeedback(_messageController.text);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).feedbackSentSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send feedback: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.feedback,
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.feedbackInstruction,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.feedbackMessageHint,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.borderLight.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.feedbackEmptyError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.sendFeedback,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
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
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
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
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.backgroundLight,
                          shape: BoxShape.circle,
                        ),
                        child: Text(curr['symbol']!),
                      ),
                      title: Text(curr['name']!,
                          style: AppTypography.textTheme.bodyLarge),
                      subtitle: Text(curr['code']!,
                          style: AppTypography.textTheme.bodySmall),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
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
