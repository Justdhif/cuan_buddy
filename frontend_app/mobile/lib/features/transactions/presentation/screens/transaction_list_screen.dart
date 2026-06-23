import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/services/currency_service.dart';
import '../providers/transaction_provider.dart';
import '../../../savings/presentation/widgets/allocate_savings_sheet.dart';
import '../widgets/ai_voice_button.dart';
import '../widgets/transaction_calendar.dart';
import '../../../profile/presentation/widgets/single_table_import_sheet.dart';
import '../../../profile/data/services/backup_worker.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final viewportHeight = MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 80;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: GestureDetector(
          onTap: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
          child: Text(l10n.transactions),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddSheet(context),
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.addTransaction,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'export') {
                ref.read(backupWorkerProvider).runBackupProcess(tables: ['transactions']);
              } else if (value == 'import') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const SingleTableImportSheet(tableName: 'transactions'),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.file_download_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.exportData),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.file_upload_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.importData),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allTransactionsProvider);
          ref.invalidate(calendarSummaryProvider);
          ref.invalidate(monthlySummaryProvider);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          controller: _scrollController,
          slivers: [
            const SliverToBoxAdapter(
              child: TransactionCalendar(),
            ),
            const SliverToBoxAdapter(
              child: _FilterRow(),
            ),
            if (transactionsAsync.isLoading && !transactionsAsync.hasValue)
              const SliverToBoxAdapter(child: SkeletonList(itemCount: 8))
            else if (transactionsAsync.hasError)
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewportHeight),
                  child: AppErrorState(
                    message: transactionsAsync.error.toString(),
                  ),
                ),
              )
            else if (transactionsAsync.hasValue && transactionsAsync.value!.isEmpty)
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewportHeight),
                  child: AppEmptyState(
                    emoji: '💸',
                    title: l10n.noTransactionsYetTitle,
                    subtitle: l10n.noTransactionsYetSubtitle,
                  ),
                ),
              )
            else if (transactionsAsync.hasValue) ...[
              Builder(
                builder: (context) {
                  final transactions = transactionsAsync.value!;
                  double totalIncome = 0;
                  double totalExpense = 0;
                  
                  for (var tx in transactions) {
                    final isIncome = tx['type'] == 'income';
                    final amountRaw = tx['amount'];
                    final amount = amountRaw is num ? amountRaw.toDouble() : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;
                    if (isIncome) {
                      totalIncome += amount;
                    } else {
                      totalExpense += amount;
                    }
                  }
                  
                  final balance = totalIncome - totalExpense;

                  return SliverPadding(
                    padding: const EdgeInsets.only(top: 0, bottom: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == transactions.length) {
                            return _BottomCashflowSummary(
                              balance: balance,
                              transactionsCount: transactions.length,
                            );
                          }
                          final item = transactions[index];
                          return _TransactionTile(transaction: item);
                        },
                        childCount: transactions.length + 1,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120), // Bottom padding for FAB
              ),
            ],
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => showAllocateSavingsSheet(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white,
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AiVoiceButton(
            onTransactionAdded: () {
              ref.invalidate(allTransactionsProvider);
            },
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    context.push('/transactions/form', extra: {'initialType': 'expense'});
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Filter
        Consumer(
          builder: (context, ref, _) {
            final categoriesAsync = ref.watch(categoriesProvider);
            final filterState = ref.watch(transactionFilterProvider);
            
            return SizedBox(
              height: 40,
              child: categoriesAsync.when(
                data: (categories) {
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildCategoryChip(
                        context: context,
                        isSelected: filterState.categoryId == null,
                        label: l10n.allCategories,
                        color: AppColors.primary,
                        onTap: () {
                          ref.read(transactionFilterProvider.notifier).setCategory(null);
                          ref.read(transactionFilterProvider.notifier).setType(null);
                        },
                      ),
                      ...categories.map((cat) {
                        final isSelected = filterState.categoryId == cat['id']?.toString();
                        final defaultTypeColor = cat['type'] == 'income' ? AppColors.success : (cat['type'] == 'expense' ? AppColors.danger : AppColors.primary);
                        final catColor = AppColors.colorFromHex(cat['colorCode'] as String?, fallback: defaultTypeColor);
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildCategoryChip(
                            context: context,
                            isSelected: isSelected,
                            label: '${cat['emojiIcon'] ?? cat['emoji'] ?? '📁'} ${cat['name'] ?? 'Unknown'}',
                            color: catColor,
                            onTap: () {
                               ref.read(transactionFilterProvider.notifier).setCategory(cat['id']?.toString());
                               ref.read(transactionFilterProvider.notifier).setType(null);
                            },
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const _CategoryFilterSkeleton(),
                error: (_, __) => const SizedBox(),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? AppColors.surfaceDark : AppColors.borderLight.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});
  final dynamic transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tx = transaction as Map<String, dynamic>;
    final isIncome = tx['type'] == 'income';
    final amountRaw = tx['amount'];
    final amount = amountRaw is num 
        ? amountRaw.toDouble() 
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;
    
    final txCurrency = tx['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final txCurrencySymbol = AppConstants.getCurrencySymbol(txCurrency);
    final fmt = NumberFormat.currency(
        locale: 'en_US',
        symbol: currencySymbol,
        decimalDigits: 0);
    final fmtOriginal = NumberFormat.currency(
        locale: 'en_US',
        symbol: txCurrencySymbol,
        decimalDigits: 0);
    final dynamic category = tx['category'];
    final emoji = (category is Map
            ? (category['emojiIcon'] as String? ?? category['emoji'] as String?)
            : null) ??
        (isIncome ? '💰' : '💸');
        
    final catName = category is Map ? category['name'] as String? : null;
    final title = tx['title'] as String? ?? tx['note'] as String? ?? catName ?? l10n.transaction;

    final defaultTypeColor = isIncome ? AppColors.success : AppColors.danger;
    final catColor = category is Map ? AppColors.colorFromHex(category['colorCode'] as String?, fallback: defaultTypeColor) : defaultTypeColor;

    return InkWell(
      onTap: () {
        context.push(
          '/transactions/form',
          extra: {
            'initialType': tx['type'] as String? ?? 'expense',
            'initialTransaction': tx,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: catColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      catName ?? l10n.transaction,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? "▲" : "▼"} ${txCurrency == currencyCode ? fmt.format(amount) : fmtOriginal.format(amount)}',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: isIncome ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (txCurrency != currencyCode)
                  Consumer(
                    builder: (context, ref, _) {
                      final convertedAsync = ref.watch(convertedAmountProvider(ConversionParams(
                        amount: amount,
                        from: txCurrency,
                        to: currencyCode,
                      )));
                      return convertedAsync.when(
                        data: (converted) => Text(
                          '≈ ${isIncome ? '+' : '-'}${fmt.format(converted)}',
                          style: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        loading: () => const SizedBox(
                          width: 20, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (_, __) => const SizedBox(),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _BottomCashflowSummary extends ConsumerWidget {
  const _BottomCashflowSummary({
    required this.balance,
    required this.transactionsCount,
  });

  final double balance;
  final int transactionsCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currencyCode = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.totalCashflow,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                fmt.format(balance),
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: balance >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.nTransactions(transactionsCount),
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CategoryFilterSkeleton extends StatelessWidget {
  const _CategoryFilterSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF4A5568) : const Color(0xFFF7FAFC),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => Container(
          width: 90,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
