import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../data/services/backup_worker.dart';
import '../widgets/backup_sheet.dart';
import '../widgets/restore_sheet.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.backupRestore,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Backup ──────────────────────────────────────────────────
          _buildTile(
            context: context,
            icon: Icons.cloud_upload_outlined,
            title: l10n.backupNow,
            subtitle: l10n.backupHubBackupDesc,
            onTap: () => AppBottomSheet.show(
              context: context,
              isScrollControlled: true,
              builder: (_) => const BackupSheet(),
            ),
          ),
          // ── Restore ─────────────────────────────────────────────────
          _buildTile(
            context: context,
            icon: Icons.history_outlined,
            title: l10n.restore,
            subtitle: l10n.backupHubRestoreDesc,
            onTap: () => AppBottomSheet.show(
              context: context,
              isScrollControlled: true,
              builder: (_) => RestoreSheet(
                onRestore: (filePath) {
                  Navigator.pop(context);
                  ref.read(backupWorkerProvider).runRestoreProcess(filePath: filePath);
                },
                onDownloadTemplate: (table) {
                  Navigator.pop(context);
                  ref.read(backupWorkerProvider).downloadTemplate(table);
                },
              ),
            ),
          ),
          // ── Export (Coming Soon) ─────────────────────────────────────
          _buildTile(
            context: context,
            icon: Icons.upload_file_outlined,
            title: l10n.exportData,
            subtitle: l10n.backupHubExportDesc,
            isComingSoon: true,
            onTap: () {},
          ),
          // ── Import (Coming Soon) ─────────────────────────────────────
          _buildTile(
            context: context,
            icon: Icons.download_outlined,
            title: l10n.importData,
            subtitle: l10n.backupHubImportDesc,
            isComingSoon: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: isComingSoon ? null : onTap,
      child: Opacity(
        opacity: isComingSoon ? 0.55 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDark ? Colors.white60 : Colors.black54,
                size: 24,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (isComingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Soon',
                              style: AppTypography.textTheme.labelSmall
                                  ?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
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
