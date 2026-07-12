import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/services/backup_worker.dart';
import '../providers/profile_provider.dart';

/// Bottom sheet shown when user taps "Backup" in the BackupRestoreScreen.
/// Contains:
///  - Auto-backup toggle (with animated frequency reveal)
///  - Save settings button
///  - List of backup files (stored in state, not directly on device)
///  - Per-item download (→ device) and delete buttons
///  - Manual backup button
class BackupSheet extends ConsumerStatefulWidget {
  const BackupSheet({super.key});

  @override
  ConsumerState<BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends ConsumerState<BackupSheet>
    with SingleTickerProviderStateMixin {
  AppLocalizations get l10n => AppLocalizations.of(context);

  bool? _backupEnabled;
  String _interval = '7d';
  bool _initialised = false;
  bool _isSaving = false;
  bool _isBackingUp = false;

  late final AnimationController _freqController;
  late final Animation<double> _freqAnim;

  static const _intervals = [
    {'value': '24h', 'icon': '📅'},
    {'value': '7d', 'icon': '📆'},
    {'value': '1m', 'icon': '🗓'},
  ];

  @override
  void initState() {
    super.initState();
    _freqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _freqAnim = CurvedAnimation(
      parent: _freqController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _freqController.dispose();
    super.dispose();
  }

  void _initFromSettings(Map<String, dynamic> settings) {
    if (_initialised) return;
    _backupEnabled = settings['isEnabled'] as bool? ?? false;
    _interval = settings['interval'] as String? ?? '7d';
    _initialised = true;
    if (_backupEnabled == true) _freqController.value = 1.0;
  }

  void _toggleBackup(bool value) {
    setState(() => _backupEnabled = value);
    value ? _freqController.forward() : _freqController.reverse();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(profileRepositoryProvider).updateBackupSettings(
            isEnabled: _backupEnabled ?? false,
            interval: _interval,
          );
      ref.invalidate(backupSettingsProvider);
      if (!mounted) return;
      AppSnackbar.show(context,
          title: l10n.success,
          message: l10n.backupSettingsSaved,
          type: SnackbarType.success);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context,
          title: l10n.info,
          message: '${l10n.failedToSaveSettings}: $e',
          type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _doManualBackup() async {
    setState(() => _isBackingUp = true);
    try {
      // Run backup in background
      ref.read(backupWorkerProvider).runBackupProcess();

      // Add entry to the state list
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
      final newFile = BackupFile(
        id: now.millisecondsSinceEpoch.toString(),
        label: 'justNow',
        filename: 'cuanbuddy_backup_$dateStr.zip',
        createdAt: now,
      );
      ref.read(backupFilesProvider.notifier).addBackup(newFile);

      if (mounted) {
        AppSnackbar.show(context,
            title: l10n.info,
            message: l10n.backupStarted,
            type: SnackbarType.info);
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _downloadFile(BackupFile file) async {
    ref.read(backupFilesProvider.notifier).setDownloading(file.id, true);
    try {
      await ref.read(backupWorkerProvider).runBackupProcess(tables: []);
      if (mounted) {
        AppSnackbar.show(context,
            title: l10n.success,
            message: l10n.backupDownloadedToDevice,
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

  String _intervalLabel(String value) => switch (value) {
        '24h' => l10n.everyDay,
        '7d' => l10n.everyWeek,
        '1m' => l10n.everyMonth,
        _ => value,
      };

  String _intervalDesc(String value) => switch (value) {
        '24h' => l10n.dailyBackupDesc,
        '7d' => l10n.weeklyBackupDesc,
        '1m' => l10n.monthlyBackupDesc,
        _ => value,
      };

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

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(backupSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return settingsAsync.when(
      data: (settings) {
        _initFromSettings(settings);
        return _buildSheet(isDark);
      },
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(l10n.failedToLoadBackupSettings,
              textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildSheet(bool isDark) {
    final files = ref.watch(backupFilesProvider);
    final enabled = _backupEnabled ?? false;

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
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.backup_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.backupNow,
                          style: AppTypography.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          l10n.backupSheetDesc,
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
              const SizedBox(height: 24),

              // ── Auto-Backup Toggle Card ─────────────────────────────
              _ToggleCard(
                enabled: enabled,
                isDark: isDark,
                l10n: l10n,
                onChanged: _toggleBackup,
              ),
              const SizedBox(height: 16),

              // ── Frequency Options (smooth animated reveal) ──────────
              SizeTransition(
                sizeFactor: _freqAnim,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _freqAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.backupFrequency,
                          style: AppTypography.textTheme.titleSmall),
                      const SizedBox(height: 10),
                      ..._intervals.map((item) => _IntervalOption(
                            value: item['value']!,
                            icon: item['icon']!,
                            label: _intervalLabel(item['value']!),
                            desc: _intervalDesc(item['value']!),
                            isSelected: _interval == item['value'],
                            isDark: isDark,
                            onTap: () =>
                                setState(() => _interval = item['value']!),
                          )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ── Save Settings ───────────────────────────────────────
              AppButton(
                label: l10n.saveChanges,
                onPressed: _isSaving ? null : _saveSettings,
                isLoading: _isSaving,
              ),
              const SizedBox(height: 28),

              // ── Backup File List Header ─────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.backupListTitle,
                          style: AppTypography.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${l10n.backupListSubtitle} (${files.length})',
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
                        onDownload: () => _downloadFile(entry.value),
                        onDelete: () => _deleteFile(entry.value),
                      ),
                    ),

              const SizedBox(height: 20),

              // ── Manual Backup Button ────────────────────────────────
              AppButton(
                label: _isBackingUp
                    ? l10n.backupInProgress
                    : l10n.backupManualNow,
                onPressed: _isBackingUp ? null : _doManualBackup,
                isLoading: _isBackingUp,
                icon: _isBackingUp
                    ? null
                    : const Icon(Icons.backup_rounded,
                        color: Colors.white, size: 18),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}


// ─── Toggle Card ──────────────────────────────────────────────────────────────
class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.enabled,
    required this.isDark,
    required this.l10n,
    required this.onChanged,
  });

  final bool enabled;
  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.primary.withValues(alpha: 0.07)
            : (isDark ? AppColors.cardDark : AppColors.cardLight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.4)
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : (isDark
                      ? AppColors.borderDark.withValues(alpha: 0.4)
                      : AppColors.borderLight.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.cloud_sync_rounded,
              color: enabled
                  ? AppColors.primary
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
                Text(l10n.autoBackup,
                    style: AppTypography.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    enabled ? l10n.autoBackupActive : l10n.backupYourDataAuto,
                    key: ValueKey(enabled),
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

// ─── Interval Option ──────────────────────────────────────────────────────────
class _IntervalOption extends StatelessWidget {
  const _IntervalOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.desc,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String value;
  final String icon;
  final String label;
  final String desc;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    desc,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
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
    required this.onDownload,
    required this.onDelete,
  });

  final BackupFile file;
  final bool isFirst;
  final bool isDark;
  final String label;
  final VoidCallback onDownload;
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
                    file.filename,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isFirst
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── Download to device button ─────────────────────────
            _ActionBtn(
              isDark: isDark,
              isLoading: file.isDownloading,
              icon: Icons.download_rounded,
              color: AppColors.primary,
              onTap: onDownload,
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
