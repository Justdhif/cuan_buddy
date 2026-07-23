import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../l10n/app_localizations.dart';

/// Shows a stylized confirmation dialog when the user tries to navigate away
/// from a form with unsaved changes.
Future<bool> showConfirmDiscardDialog(
  BuildContext context, {
  String? title,
  String? message,
  String? confirmText,
  String? cancelText,
}) async {
  final l10n = AppLocalizations.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? l10n.unsavedChangesTitle,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message ?? l10n.unsavedChangesMessage,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              cancelText ?? l10n.keepEditing,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmText ?? l10n.discardChanges,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

/// A wrapper around [PopScope] that intercept pops when [hasUnsavedChanges] is true
/// and asks for confirmation before discarding changes.
class FormPopScope extends StatelessWidget {
  const FormPopScope({
    super.key,
    required this.child,
    required this.hasUnsavedChanges,
    this.title,
    this.message,
    this.onPopInvoked,
  });

  final Widget child;
  final bool hasUnsavedChanges;
  final String? title;
  final String? message;
  final VoidCallback? onPopInvoked;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showConfirmDiscardDialog(
          context,
          title: title,
          message: message,
        );
        if (shouldPop && context.mounted) {
          if (onPopInvoked != null) {
            onPopInvoked!();
          } else {
            Navigator.of(context).pop(result);
          }
        }
      },
      child: child,
    );
  }
}
