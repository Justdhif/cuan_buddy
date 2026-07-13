import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/services/backup_worker.dart';
import '../providers/profile_provider.dart';

/// Bottom sheet for restore flow.
/// Designed to match BackupSheet with file selection, restore button, sync options, and file list.
class RestoreSheet extends ConsumerStatefulWidget {
  const RestoreSheet({
    super.key,
    required this.onRestore,
    required this.onDownloadTemplate,
  });

  final void Function(String filePath) onRestore;
  final void Function(String table) onDownloadTemplate;

  @override
  ConsumerState<RestoreSheet> createState() => _RestoreSheetState();
}

class _RestoreSheetState extends ConsumerState<RestoreSheet> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  String? _selectedFilePath;
  String? _selectedFileName;
  int? _selectedFileSize;
  bool _isRestoring = false;

  Future<void> _pickFile() async {
    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['sql'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
          _selectedFileSize = result.files.single.size;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context,
            title: l10n.info,
            message: e.toString(),
            type: SnackbarType.error);
      }
    }
  }

  void _clearSelectedFile() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
      _selectedFileSize = null;
    });
  }

  Future<void> _doRestore() async {
    if (_selectedFilePath == null) return;
    setState(() => _isRestoring = true);
    try {
      widget.onRestore(_selectedFilePath!);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _syncFile(BackupFile file) async {
    ref.read(backupFilesProvider.notifier).setDownloading(file.id, true);
    try {
      await ref.read(backupWorkerProvider).runSyncProcess(file.filename);
      if (mounted) {
        AppSnackbar.show(context,
            title: l10n.success,
            message: 'Database successfully synchronized.',
            type: SnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context,
            title: l10n.info,
            message: '$e',
            type: SnackbarType.error);
      }
    } finally {
      ref.read(backupFilesProvider.notifier).setDownloading(file.id, false);
    }
  }

  Future<void> _deleteFile(BackupFile file) async {
    ref.read(backupFilesProvider.notifier).setDeleting(file.id, true);
    // Brief delay to show animation
    await Future.delayed(const Duration(milliseconds: 400));
    ref.read(backupFilesProvider.notifier).removeFile(file.id);
  }

  String _fileLabel(BackupFile file) {
    final diff = DateTime.now().difference(file.createdAt);
    if (diff.inMinutes < 5) return l10n.backupJustNow;
    if (diff.inHours < 24) {
      return l10n.backupHoursAgo(diff.inHours);
    }
    if (diff.inDays < 30) {
      return l10n.backupDaysAgo(diff.inDays);
    }
    final months = l10n.shortMonths;
    return '${file.createdAt.day} ${months[file.createdAt.month - 1]}';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (bytes / 1024).truncate();
    if (i == 0) return "$bytes B";
    double num = bytes / (1024 * i);
    return "${num.toStringAsFixed(1)} ${suffixes[i]}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final files = ref.watch(backupFilesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              const SizedBox(height: 16),
              Text(
                l10n.restoreData,
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Upload a .sql file from your device to restore the database',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 24),

              // ── File Selection Card ─────────────────────────────────
              GestureDetector(
                onTap: _selectedFilePath != null ? null : _pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _selectedFilePath != null
                        ? AppColors.secondary.withValues(alpha: 0.07)
                        : (isDark ? AppColors.cardDark : AppColors.cardLight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedFilePath != null
                          ? AppColors.secondary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedFilePath != null
                              ? AppColors.secondary.withValues(alpha: 0.15)
                              : (isDark
                                  ? AppColors.borderDark.withValues(alpha: 0.4)
                                  : AppColors.borderLight.withValues(alpha: 0.6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _selectedFilePath != null
                              ? Icons.check_circle_outline_rounded
                              : Icons.folder_open_rounded,
                          color: _selectedFilePath != null
                              ? AppColors.secondary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileName ?? (l10n.languageCode == 'id' ? 'Pilih File Database' : 'Select Database File'),
                              style: AppTypography.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedFilePath != null
                                  ? _formatBytes(_selectedFileSize ?? 0)
                                  : (l10n.languageCode == 'id' ? 'Mendukung file database .sql' : 'Supports .sql database files'),
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                color: _selectedFilePath != null
                                    ? AppColors.secondary
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedFilePath != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: isDark ? Colors.white60 : Colors.black54,
                          onPressed: _clearSelectedFile,
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Restore Button ──────────────────────────────────────
              AppButton(
                label: _isRestoring ? (l10n.languageCode == 'id' ? 'Memulihkan...' : 'Restoring...') : l10n.restore,
                onPressed: _selectedFilePath == null || _isRestoring ? null : _doRestore,
                isLoading: _isRestoring,
                type: AppButtonType.secondary,
              ),
              const SizedBox(height: 32),

              // ── Backup File List Header ─────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Synchronize Backup Files',
                          style: AppTypography.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Select a local backup file to synchronize database (${files.length})',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
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
              const SizedBox(height: 12),

              // ── File List ───────────────────────────────────────────
              if (files.isEmpty)
                _EmptyBackupList(isDark: isDark, l10n: l10n)
              else
                ...files.asMap().entries.map(
                      (entry) => _BackupFileItem(
                        file: entry.value,
                        isFirst: entry.key == 0,
                        isDark: isDark,
                        label: _fileLabel(entry.value),
                        onSync: () => _syncFile(entry.value),
                        onDelete: () => _deleteFile(entry.value),
                      ),
                    ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ─── Backup File Item ─────────────────────────────────────────────────────────
class _BackupFileItem extends StatelessWidget {
  const _BackupFileItem({
    required this.file,
    required this.isFirst,
    required this.isDark,
    required this.label,
    required this.onSync,
    required this.onDelete,
  });

  final BackupFile file;
  final bool isFirst;
  final bool isDark;
  final String label;
  final VoidCallback onSync;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: file.isDeleting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFirst
                ? AppColors.primary.withValues(alpha: 0.4)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isFirst ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // ── File icon ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isFirst
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : (isDark
                        ? AppColors.borderDark.withValues(alpha: 0.5)
                        : AppColors.borderLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.insert_drive_file_outlined,
                color: isFirst
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // ── Label & filename ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isFirst
                          ? AppColors.primary
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file.filename,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── Sync button ───────────────────────────────────────
            _ActionBtn(
              isDark: isDark,
              isLoading: file.isDownloading, // reuse downloading animation
              icon: Icons.sync_rounded,
              color: AppColors.secondary,
              onTap: onSync,
            ),
            const SizedBox(width: 6),
            // ── Delete button ─────────────────────────────────────
            _ActionBtn(
              isDark: isDark,
              isLoading: file.isDeleting,
              icon: Icons.close_rounded,
              color: AppColors.danger,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small icon action button with loading state ──────────────────────────────
class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.isDark,
    required this.isLoading,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final bool isDark;
  final bool isLoading;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withValues(alpha: 0.18)
              : (widget.isDark
                  ? AppColors.borderDark.withValues(alpha: 0.5)
                  : AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: widget.isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.color,
                ),
              )
            : Icon(widget.icon, color: widget.color, size: 16),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyBackupList extends StatelessWidget {
  const _EmptyBackupList({required this.isDark, required this.l10n});
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 48,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.backupNoFiles,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
