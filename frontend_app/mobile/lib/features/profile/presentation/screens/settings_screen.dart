import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthStateUnauthenticated) {
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: Navigator.of(context).canPop() ? 0 : 20,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          l10n.languageCode == 'id' ? 'Pengaturan' : 'Settings',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          children: [

            _buildSettingsTile(
              context: context,
              icon: Icons.person_outline_rounded,
              title: l10n.languageCode == 'id' ? 'Profil Saya' : 'My Profile',
              subtitle: l10n.languageCode == 'id'
                  ? 'Lihat & edit informasi profil Anda'
                  : 'View & edit your profile information',
              onTap: () => context.push('/home/profile'),
            ),

            _buildSettingsTile(
              context: context,
              icon: Icons.key_outlined,
              title: l10n.accountMenu,
              subtitle: l10n.accountMenuDesc,
              onTap: () => context.push('/profile/account'),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.palette_outlined,
              title: l10n.appearanceMenu,
              subtitle: l10n.appearanceMenuDesc,
              onTap: () => context.push('/profile/theme-language'),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.storage_outlined,
              title: 'Manage Data',
              subtitle: 'Manage transaction categories and wallets',
              onTap: () => context.push('/profile/manage-data'),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.widgets_outlined,
              title: 'Widgets',
              subtitle: l10n.widgetsDesc,
              onTap: () => context.push('/profile/widgets'),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.backup_outlined,
              title: l10n.backupRestore,
              subtitle: l10n.backupRestoreDesc,
              onTap: () => context.push('/profile/backup'),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.info_outline_rounded,
              title: l10n.about,
              subtitle: l10n.aboutDesc,
              onTap: () => _showAboutAppSheet(context),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.feedback_outlined,
              title: l10n.feedback,
              subtitle: l10n.feedbackDesc,
              onTap: () => _showFeedbackSheet(context),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.logout_rounded,
              title: l10n.logOut,
              subtitle: l10n.logOutDesc,
              isDanger: true,
              onTap: () => _logout(context, ref),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDanger
                  ? AppColors.danger
                  : (isDark ? Colors.white60 : Colors.black54),
              size: 24,
            ),
            const SizedBox(width: 20),
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
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutAppSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Cuan Buddy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('v1.0.0', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi manajemen keuangan pribadi & bersama terpadu.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kirim Masukan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tuliskan masukan atau saran Anda...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terima kasih atas masukan Anda!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Kirim', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
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
}
