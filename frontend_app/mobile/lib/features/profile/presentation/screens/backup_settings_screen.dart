import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../data/services/backup_worker.dart';
import '../providers/profile_provider.dart';

class BackupSettingsScreen extends ConsumerStatefulWidget {
  /// If [isOnboarding] is true, shows Step 2/2 header and Skip button.
  const BackupSettingsScreen({super.key, this.isOnboarding = false});
  final bool isOnboarding;

  @override
  ConsumerState<BackupSettingsScreen> createState() =>
      _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  bool? _backupEnabled;
  String _interval = '7d';

  final List<String> _selectedTables = ['transactions', 'budgets', 'savings_goals'];

  void _toggleTable(String table) {
    setState(() {
      if (_selectedTables.contains(table)) {
        _selectedTables.remove(table);
      } else {
        _selectedTables.add(table);
      }
    });
  }
  
  void _showRestoreSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RestoreSheet(
        onRestore: () {
          Navigator.pop(context);
          ref.read(backupWorkerProvider).runRestoreProcess();
        },
        onDownloadTemplate: (table) {
          Navigator.pop(context);
          ref.read(backupWorkerProvider).downloadTemplate(table);
        }
      ),
    );
  }

  bool _isLoading = false;
  bool _initialised = false;

  final _intervals = const [
    {'value': '24h', 'label': 'Every Day', 'icon': '📅', 'desc': 'Daily automatic backup'},
    {'value': '7d', 'label': 'Every Week', 'icon': '📆', 'desc': 'Weekly automatic backup'},
    {'value': '1m', 'label': 'Every Month', 'icon': '🗓', 'desc': 'Monthly automatic backup'},
  ];

  void _initFromSettings(Map<String, dynamic> settings) {
    if (_initialised) return;
    _backupEnabled = settings['isEnabled'] as bool? ?? false;
    _interval = settings['interval'] as String? ?? '7d';
    _initialised = true;
  }

  Future<void> _saveSettings({bool navigateAway = false}) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(profileRepositoryProvider).updateBackupSettings(
            isEnabled: _backupEnabled ?? false,
            interval: _interval,
          );
      ref.invalidate(backupSettingsProvider);
      if (!mounted) return;
      if (navigateAway) {
        context.go('/home/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupSettingsSaved),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, title: l10n.info, message: '${l10n.failedToSaveSettings}: ${e.toString()}', type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(backupSettingsProvider);

    return Scaffold(
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              title: Text(l10n.backupRestore),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => context.pop(),
              ),
            ),
      body: settingsAsync.when(
        data: (settings) {
          _initFromSettings(settings);
          return _buildContent(context);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AppErrorState(
          message: l10n.failedToLoadBackupSettings,
          onRetry: () => ref.invalidate(backupSettingsProvider),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final enabled = _backupEnabled ?? false;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isOnboarding) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 1.0,
                        backgroundColor: AppColors.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.step2of2,
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        )),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('💾', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  l10n.backupSettings,
                  style: AppTypography.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.enableAutoBackup,
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 32),
              ],
  
              // ─── Enable Toggle Card ─────────────────────────────────
              _buildToggleTile(enabled),
  
              // ─── Frequency Options ──────────────────────────────────
              if (enabled) ...[
                const SizedBox(height: 24),
                Text(l10n.backupFrequency,
                    style: AppTypography.textTheme.titleSmall),
                const SizedBox(height: 12),
                ..._intervals.map(
                  (item) {
                    final String translatedLabel = switch (item['value']) {
                      '24h' => l10n.everyDay,
                      '7d' => l10n.everyWeek,
                      '1m' => l10n.everyMonth,
                      _ => item['label']!,
                    };
                    final String translatedDesc = switch (item['value']) {
                      '24h' => l10n.dailyBackupDesc,
                      '7d' => l10n.weeklyBackupDesc,
                      '1m' => l10n.monthlyBackupDesc,
                      _ => item['desc']!,
                    };
                    return _buildIntervalOption(
                      item['value']!,
                      translatedLabel,
                      item['icon']!,
                      translatedDesc,
                    );
                  },
                ),
              ],
  
              
              if (enabled) ...[
                const SizedBox(height: 24),
                Text(l10n.selectDataToBackup,
                    style: AppTypography.textTheme.titleSmall),
                const SizedBox(height: 12),
                _buildCheckbox(l10n.transactionsLabel, 'transactions'),
                _buildCheckbox(l10n.budgetsLabel, 'budgets'),
                _buildCheckbox(l10n.savingsGoalsLabel, 'savings_goals'),
              ],
  
              if (!widget.isOnboarding) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: l10n.backupNow,
                        onPressed: _selectedTables.isEmpty ? null : () {
                          ref.read(backupWorkerProvider).runBackupProcess(tables: _selectedTables);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.backupStarted)),
                          );
                        },
                        type: AppButtonType.outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: l10n.restore,
                        onPressed: _showRestoreSheet,
                        type: AppButtonType.outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
  
              // ─── Save / Finish Button ───────────────────────────────
              AppButton(
                label: widget.isOnboarding ? l10n.finishAndStart : l10n.saveChanges,
                onPressed: _isLoading
                    ? null
                    : () => _saveSettings(navigateAway: widget.isOnboarding),
                isLoading: _isLoading,
              ),
  
              if (widget.isOnboarding) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: l10n.skip,
                  onPressed: () => context.go('/home/dashboard'),
                  type: AppButtonType.text,
                ),
              ],
  
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile(bool enabled) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.borderDark.withValues(alpha: 0.4)
                      : AppColors.borderLight.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.backup_rounded,
              color: enabled
                  ? AppColors.primary
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.autoBackup,
                    style: AppTypography.textTheme.titleSmall),
                Text(
                  enabled
                      ? l10n.autoBackupActive
                      : l10n.backupYourDataAuto,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (v) => setState(() => _backupEnabled = v),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalOption(
    String value,
    String label,
    String icon,
    String desc,
  ) {
    final isSelected = _interval == value;
    return GestureDetector(
      onTap: () => setState(() => _interval = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.cardDark
                  : AppColors.cardLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    desc,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, String value) {
    final isSelected = _selectedTables.contains(value);
    return CheckboxListTile(
      title: Text(title, style: AppTypography.textTheme.bodyMedium),
      value: isSelected,
      onChanged: (v) => _toggleTable(value),
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _RestoreSheet extends StatelessWidget {
  const _RestoreSheet({required this.onRestore, required this.onDownloadTemplate});

  final VoidCallback onRestore;
  final Function(String) onDownloadTemplate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.restore_page_rounded,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.restoreData,
            style: AppTypography.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.restoreInstructions,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          Text(l10n.downloadTemplates, style: AppTypography.textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.download_rounded, size: 16),
                label: Text(l10n.transactionsLabel),
                onPressed: () => onDownloadTemplate('transactions'),
                backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              ActionChip(
                avatar: const Icon(Icons.download_rounded, size: 16),
                label: Text(l10n.budgetsLabel),
                onPressed: () => onDownloadTemplate('budgets'),
                backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              ActionChip(
                avatar: const Icon(Icons.download_rounded, size: 16),
                label: Text(l10n.savingsGoalsLabel),
                onPressed: () => onDownloadTemplate('savings_goals'),
                backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ],
          ),
          const SizedBox(height: 32),
          AppButton(
            label: l10n.uploadAndRestore,
            onPressed: onRestore,
          ),
        ],
      ),
    );
  }

}