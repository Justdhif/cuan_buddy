import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/providers/widget_preferences_provider.dart';
import '../../../savings/presentation/providers/savings_provider.dart';
import '../../../../core/services/widget_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class WidgetSettingsScreen extends ConsumerWidget {
  const WidgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Available Widgets',
            style: AppTypography.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Long press your home screen to add these widgets.',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),

          // Balance Widget Tile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard Balance',
                          style: AppTypography.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Displays your total balance, income, and expense.',
                        style: AppTypography.textTheme.labelMedium?.copyWith(
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
          const SizedBox(height: 16),

          // Savings Widget Tile
          Consumer(
            builder: (context, ref, _) {
              final savingsState = ref.watch(savingsNotifierProvider);
              final selectedGoalId = ref.watch(selectedSavingsWidgetIdProvider);

              String? selectedGoalName;
              if (selectedGoalId != null) {
                try {
                  selectedGoalName = savingsState.goals
                      .firstWhere((g) => g['id'] == selectedGoalId)['name'];
                } catch (e) {
                  // Not found
                }
              }

              return GestureDetector(
                onTap: () => _showSavingsSelectionSheet(
                    context, ref, savingsState, selectedGoalId),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.savings_rounded,
                            color: AppColors.success),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Savings Goal',
                                style: AppTypography.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              selectedGoalName == null
                                  ? 'Tap to select a goal'
                                  : 'Active: $selectedGoalName',
                              style:
                                  AppTypography.textTheme.labelMedium?.copyWith(
                                color: selectedGoalName == null
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                                fontWeight: selectedGoalName == null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textHintLight),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSavingsSelectionSheet(BuildContext context, WidgetRef ref,
      SavingsState savingsState, String? currentId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Savings Goal',
                  style: AppTypography.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a goal to display on your home screen.',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: savingsState.goals.isEmpty
                      ? Center(
                          child: AppEmptyState(
                            emoji: '🎯',
                            title: 'No Savings Goals',
                            subtitle:
                                'You have no active savings goals to display.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: savingsState.goals.length,
                          itemBuilder: (context, index) {
                            final goal = savingsState.goals[index];
                            final isSelected = goal['id'] == currentId;

                            return ListTile(
                              leading: Text(goal['icon'] as String? ?? '🎯',
                                  style: const TextStyle(fontSize: 24)),
                              title: Text(goal['name'] as String? ?? 'Goal',
                                  style: AppTypography.textTheme.bodyLarge),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: AppColors.primary)
                                  : null,
                              onTap: () async {
                                await ref
                                    .read(selectedSavingsWidgetIdProvider
                                        .notifier)
                                    .setSelectedSavingsId(goal['id'] as String);

                                // Push immediately
                                final rawT = goal['targetAmount'];
                                final rawS = goal['savedAmount'];
                                final target = rawT is num
                                    ? rawT.toDouble()
                                    : double.tryParse(
                                            rawT?.toString() ?? '0') ??
                                        0;
                                final saved = rawS is num
                                    ? rawS.toDouble()
                                    : double.tryParse(
                                            rawS?.toString() ?? '0') ??
                                        0;
                                final profileAsync = ref.read(profileProvider);
                                final currency = profileAsync
                                        .valueOrNull?['currency'] as String? ??
                                    AppConstants.defaultCurrency;

                                await WidgetService.updateSavingsWidgetData(
                                  emoji: goal['icon'] as String? ?? '🎯',
                                  name: goal['name'] as String? ?? 'Goal',
                                  savedAmount: saved,
                                  targetAmount: target,
                                  currency: currency,
                                );

                                if (context.mounted) Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
                if (currentId != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.visibility_off_rounded,
                        color: AppColors.danger),
                    title: Text('Disable Savings Widget',
                        style: AppTypography.textTheme.bodyLarge
                            ?.copyWith(color: AppColors.danger)),
                    onTap: () async {
                      await ref
                          .read(selectedSavingsWidgetIdProvider.notifier)
                          .setSelectedSavingsId(null);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
