import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/widgets/sticky_header_delegate.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/savings_provider.dart';
import '../widgets/add_savings_sheet.dart';
import '../widgets/top_up_sheet.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  String _statusFilter = 'All'; // 'All', 'In Progress', 'Completed'

  @override
  Widget build(BuildContext context) {
    final savingsState = ref.watch(savingsNotifierProvider);
    final currencyCode = ref.watch(profileProvider).value?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showAddSavingsSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(savingsNotifierProvider.notifier).fetchGoals(),
        color: AppColors.primary,
        child: _buildBody(context, savingsState, isDark, currencySymbol),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SavingsState state, bool isDark, String currencySymbol) {
    if (state.isLoading && state.goals.isEmpty) {
      return const SkeletonList();
    }
    if (state.error != null && state.goals.isEmpty) {
      return AppErrorState(message: state.error!);
    }

    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    // Calculate Summary
    double totalSaved = 0;
    double totalTarget = 0;
    int completedGoals = 0;

    for (final g in state.goals) {
      final rawT = g['targetAmount'];
      final t = rawT is num ? rawT.toDouble() : double.tryParse(rawT?.toString() ?? '0') ?? 0;
      final rawC = g['currentAmount'];
      final c = rawC is num ? rawC.toDouble() : double.tryParse(rawC?.toString() ?? '0') ?? 0;
      totalTarget += t;
      totalSaved += c;
      if (g['status'] == 'completed' || (t > 0 && c >= t)) {
        completedGoals++;
      }
    }

    // Filter goals
    final filteredGoals = state.goals.where((g) {
      if (_statusFilter == 'All') return true;
      final rawT = g['targetAmount'];
      final t = rawT is num ? rawT.toDouble() : double.tryParse(rawT?.toString() ?? '0') ?? 0;
      final rawC = g['currentAmount'];
      final c = rawC is num ? rawC.toDouble() : double.tryParse(rawC?.toString() ?? '0') ?? 0;
      final isCompleted = g['status'] == 'completed' || (t > 0 && c >= t);
      
      if (_statusFilter == 'Completed') return isCompleted;
      if (_statusFilter == 'In Progress') return !isCompleted;
      return true;
    }).toList();

    return CustomScrollView(
      slivers: [
        // Summary Header
        if (state.goals.isNotEmpty)
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyHeaderDelegate(
              minHeight: 180, // Approximate height for savings card
              maxHeight: 180,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF6B58E6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Saved',
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fmt.format(totalSaved),
                          style: AppTypography.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem(
                              'Goals',
                              state.goals.length.toString(),
                            ),
                            Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                            _buildSummaryItem(
                              'Completed',
                              completedGoals.toString(),
                            ),
                            Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                            _buildSummaryItem(
                              'Remaining',
                              fmt.format(totalTarget > totalSaved ? totalTarget - totalSaved : 0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Status Filter
        if (state.goals.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.borderLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: ['All', 'In Progress', 'Completed'].map((status) {
                    final isSelected = _statusFilter == status;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _statusFilter = status),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: AppTypography.textTheme.titleSmall?.copyWith(
                              color: isSelected 
                                  ? Colors.white 
                                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

        // Goals List
        if (state.goals.isEmpty)
          const SliverFillRemaining(
            child: AppEmptyState(
              emoji: '🎯',
              title: 'No Savings Goals',
              subtitle: 'Tap the + icon to set aside money for your dreams.',
            ),
          )
        else if (filteredGoals.isEmpty)
          SliverFillRemaining(
            child: AppEmptyState(
              emoji: '🔍',
              title: 'No $_statusFilter Goals',
              subtitle: 'Try changing the filter.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final goal = filteredGoals[index];
                  return _buildGoalCard(context, goal, currencySymbol);
                },
                childCount: filteredGoals.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, Map<String, dynamic> goal, String currencySymbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final name = goal['name'] as String? ?? 'Unnamed Goal';
    final rawT = goal['targetAmount'];
    final targetAmount = rawT is num ? rawT.toDouble() : double.tryParse(rawT?.toString() ?? '0') ?? 0;
    final rawC = goal['currentAmount'];
    final currentAmount = rawC is num ? rawC.toDouble() : double.tryParse(rawC?.toString() ?? '0') ?? 0;
    final targetDateStr = goal['targetDate'] as String?;
    
    final percentage = targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;
    final safePercentage = percentage.clamp(0.0, 1.0);
    final isCompleted = goal['status'] == 'completed' || safePercentage >= 1.0;

    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    // Countdown Logic
    String? countdownText;
    Color? countdownColor;
    if (!isCompleted && targetDateStr != null) {
      try {
        final targetDate = DateTime.parse(targetDateStr).toLocal();
        final now = DateTime.now();
        final diff = targetDate.difference(now).inDays;
        
        if (diff < 0) {
          countdownText = '${diff.abs()} days overdue';
          countdownColor = AppColors.danger;
        } else if (diff == 0) {
          countdownText = 'Due today!';
          countdownColor = AppColors.warning;
        } else {
          countdownText = '$diff days left';
          countdownColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted 
              ? AppColors.success.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (countdownText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (countdownColor ?? AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    countdownText,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: countdownColor ?? AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fmt.format(currentAmount),
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'of ${fmt.format(targetAmount)}',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: safePercentage,
              backgroundColor: isDark 
                  ? AppColors.borderDark 
                  : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.success : AppColors.primary
              ),
              minHeight: 8,
            ),
          ),
          
          // Action Button
          if (!isCompleted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showTopUpSheet(context, goal),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Update Funds'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
