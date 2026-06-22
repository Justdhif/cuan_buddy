import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/services/backup_worker.dart';

class SingleTableImportSheet extends ConsumerWidget {
  final String tableName;

  const SingleTableImportSheet({super.key, required this.tableName});

  Widget _buildChip({
    required BuildContext context,
    required bool isDark,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worker = ref.read(backupWorkerProvider);

    String specificTemplateName = 'Template (.xlsx)';
    if (tableName == 'transactions') {
      specificTemplateName = 'Transactions Template (.xlsx)';
    } else if (tableName == 'budgets') {
      specificTemplateName = 'Budgets Template (.xlsx)';
    } else if (tableName == 'savings_goals') {
      specificTemplateName = 'Savings Template (.xlsx)';
    }

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Drag handle ────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Icon ───────────────────────────────────────────────────
          Container(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restore_page_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title & Subtitle ───────────────────────────────────────
          Text(
            l10n.importData,
            style: AppTypography.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.restoreInstructions,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 28),

          // ── Divider ────────────────────────────────────────────────
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
          const SizedBox(height: 20),

          // ── Download Templates ─────────────────────────────────────
          Text(l10n.downloadTemplates,
              style: AppTypography.textTheme.titleSmall?.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              )),
          const SizedBox(height: 12),
          Center(
            child: _buildChip(
              context: context,
              isDark: isDark,
              label: specificTemplateName,
              onPressed: () {
                Navigator.pop(context);
                worker.downloadTemplate(tableName);
              },
            ),
          ),
          const SizedBox(height: 28),

          // ── Upload & Restore Button ────────────────────────────────
          AppButton(
            label: l10n.uploadAndRestore,
            onPressed: () {
                Navigator.pop(context);
                worker.runRestoreProcess();
            },
          ),
        ],
      ),
    );
  }
}
