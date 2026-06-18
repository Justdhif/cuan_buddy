import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/transaction_calendar.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            onPressed: () => _showAddSheet(context),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Transaction',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const TransactionCalendar(),
          const _FilterRow(),
          Expanded(
            child: transactionsAsync.when(
              skipLoadingOnReload: true,
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const AppEmptyState(
                    emoji: '💸',
                    title: 'No transactions yet',
                    subtitle: 'Start recording your income & expenses!',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allTransactionsProvider);
                    ref.invalidate(calendarSummaryProvider);
                  },
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) =>
                        _TransactionTile(transaction: transactions[index]),
                  ),
                );
              },
              loading: () => const SkeletonList(itemCount: 8),
              error: (e, _) => AppErrorState(
                message: 'Failed to load transactions 😅',
                onRetry: () => ref.invalidate(allTransactionsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddTransactionSheet(initialType: 'expense'),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(transactionFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.borderLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildTypeTab(context, ref, filterState.type, null, 'All Types', isDark),
                _buildTypeTab(context, ref, filterState.type, 'income', 'Income', isDark),
                _buildTypeTab(context, ref, filterState.type, 'expense', 'Expense', isDark),
              ],
            ),
          ),
        ),
        
        // Category List
        categoriesAsync.when(
          data: (categories) {
            final filtered = categories.where((c) {
              final catType = c['type'] as String?;
              return catType == filterState.type || filterState.type == null || catType == null;
            }).toList();

            return SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = filterState.categoryId == null;
                    return _buildCategoryChip(
                      context: context,
                      ref: ref,
                      id: null,
                      name: 'All Categories',
                      emoji: '📁',
                      isSelected: isSelected,
                      isDark: isDark,
                      typeColor: AppColors.primary,
                    );
                  }
                  
                  final cat = filtered[index - 1];
                  final catId = cat['id'] as String?;
                  final catName = cat['name'] as String? ?? '';
                  final catEmoji = cat['emojiIcon'] as String? ?? cat['emoji'] as String? ?? '📁';
                  final isSelected = filterState.categoryId == catId;
                  
                  final catType = cat['type'] as String?;
                  final typeColor = catType == 'income' ? AppColors.success : (catType == 'expense' ? AppColors.danger : AppColors.primary);

                  return _buildCategoryChip(
                    context: context,
                    ref: ref,
                    id: catId,
                    name: catName,
                    emoji: catEmoji,
                    isSelected: isSelected,
                    isDark: isDark,
                    typeColor: typeColor,
                  );
                },
              ),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCategorySkeletonLoader(isDark),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Failed to load categories', style: TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTypeTab(BuildContext context, WidgetRef ref, String? currentType, String? targetType, String label, bool isDark) {
    final isSelected = currentType == targetType;
    Color activeColor = AppColors.primary;
    if (targetType == 'income') activeColor = AppColors.success;
    if (targetType == 'expense') activeColor = AppColors.danger;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(transactionFilterProvider.notifier).setType(targetType);
          ref.read(transactionFilterProvider.notifier).setCategory(null);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.titleSmall?.copyWith(
              color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required WidgetRef ref,
    required String? id,
    required String name,
    required String emoji,
    required bool isSelected,
    required bool isDark,
    required Color typeColor,
  }) {
    return GestureDetector(
      onTap: () => ref.read(transactionFilterProvider.notifier).setCategory(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? typeColor.withValues(alpha: 0.15) : (isDark ? AppColors.surfaceDark : const Color(0xFFF3F0FF)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? typeColor : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              name,
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: isSelected ? typeColor : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySkeletonLoader(bool isDark) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => _SkeletonChip(isDark: isDark),
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});
  final dynamic transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = transaction as Map<String, dynamic>;
    final isIncome = tx['type'] == 'income';
    final amountRaw = tx['amount'];
    final amount = amountRaw is num 
        ? amountRaw.toDouble() 
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;
    
    final currencyCode = ref.watch(profileProvider).value?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(
        locale: 'en_US',
        symbol: currencySymbol,
        decimalDigits: 0);
    final dynamic category = tx['category'];
    final emoji = (category is Map
            ? (category['emojiIcon'] as String? ?? category['emoji'] as String?)
            : null) ??
        (isIncome ? '💰' : '💸');
    final title = tx['description'] as String? ??
        (category is Map ? category['name'] as String? : null) ??
        'Transaction';
    final rawDate = tx['date'] as String?;
    final date = rawDate != null
        ? DateFormat('d MMM yyyy', 'en_US').format(DateTime.parse(rawDate))
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: AppCard(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (isIncome ? AppColors.success : AppColors.danger)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(date,
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${fmt.format(amount)}',
                  style: TextStyle(
                    color: isIncome ? AppColors.successDark : AppColors.dangerDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondaryLight),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => AddTransactionSheet(
                            initialType: tx['type'] as String? ?? 'expense',
                            initialTransaction: tx,
                          ),
                        );
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Transaction'),
                            content: const Text('Are you sure you want to delete this transaction?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            final dio = ref.read(dioClientProvider).dio;
                            await dio.delete('/transactions/${tx['id']}');
                            ref.invalidate(allTransactionsProvider);
                            ref.invalidate(calendarSummaryProvider);
                          } catch (e) {
                            if (context.mounted) {
                              AppSnackbar.show(context, title: 'Error', message: 'Failed to delete: $e', type: SnackbarType.error);
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonChip extends StatefulWidget {
  const _SkeletonChip({required this.isDark});
  final bool isDark;

  @override
  State<_SkeletonChip> createState() => _SkeletonChipState();
}

class _SkeletonChipState extends State<_SkeletonChip> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 100,
          height: 52,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
