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
import '../widgets/ai_voice_sheet.dart';
import '../widgets/transaction_calendar.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _headerCollapsed = false;
  double _scrollOffset = 0.0;

  // Speed-dial FAB state
  bool _fabOpen = false;
  late AnimationController _fabController;
  late Animation<double> _fade1, _fade2;
  late Animation<Offset> _slide1, _slide2;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    // Staggered intervals: btn1 first (closest to main), btn2 last (topmost)
    _fade1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _fade2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _slide1 =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slide2 =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final collapsed = offset > 80;
      setState(() {
        _scrollOffset = offset;
        _headerCollapsed = collapsed;
      });
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _fabOpen = !_fabOpen;
      if (_fabOpen) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  Widget _buildSubFab({
    required IconData icon,
    required VoidCallback onTap,
    required Animation<double> fadeAnim,
    required Animation<Offset> slideAnim,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: IgnorePointer(
          ignoring: !_fabOpen,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final viewportHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        80;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allTransactionsProvider);
          ref.invalidate(calendarSummaryProvider);
          ref.invalidate(monthlySummaryProvider);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          controller: _scrollController,
          slivers: [
            // ── Hero SliverAppBar ──────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              expandedHeight: 120,
              backgroundColor: bgColor,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              titleSpacing: 24,
              // Collapsed app bar title (shows when scrolled)
              title: AnimatedOpacity(
                opacity: _headerCollapsed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Hero(
                  tag: 'tx-title',
                  flightShuttleBuilder: (_, animation, __, fromContext, toContext) {
                    return DefaultTextStyle(
                      style: AppTypography.textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      child: AnimatedBuilder(
                        animation: animation,
                        builder: (_, __) {
                          return Opacity(
                            opacity: animation.value,
                            child: const Text('Transactions'),
                          );
                        },
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () => _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                    child: Text(
                      l10n.transactions,
                      style: AppTypography.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Expanded hero header
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.none,
                background: _TransactionHeroHeader(isDark: isDark, scrollOffset: _scrollOffset),
              ),
            ),
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
            else if (transactionsAsync.hasValue &&
                transactionsAsync.value!.isEmpty)
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
                    final amount = amountRaw is num
                        ? amountRaw.toDouble()
                        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Staggered sub-buttons (always in tree for smooth exit animation) ──
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sub 2 – Mic (top, animates second)
              _buildSubFab(
                icon: Icons.mic_rounded,
                onTap: () async {
                  _toggleFab();
                  final result = await showAiVoiceSheet(context);
                  if (result == true) {
                    ref.invalidate(allTransactionsProvider);
                  }
                },
                fadeAnim: _fade2,
                slideAnim: _slide2,
              ),
              const SizedBox(height: 12),
              // Sub 1 – Manual (bottom, animates first)
              _buildSubFab(
                icon: Icons.receipt_long_rounded,
                onTap: () {
                  _toggleFab();
                  context.push('/transactions/form',
                      extra: {'initialType': 'expense'});
                },
                fadeAnim: _fade1,
                slideAnim: _slide1,
              ),
              const SizedBox(height: 16),
            ],
          ),
          // ── Main + FAB (rotates 45° → × when open) ──
          GestureDetector(
            onTap: _toggleFab,
            child: AnimatedBuilder(
              animation: _fabController,
              builder: (ctx, child) => Transform.rotate(
                angle: _fabController.value * 0.785398, // 45 degrees
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Header Widget ────────────────────────────────────────────────────────
class _TransactionHeroHeader extends StatelessWidget {
  const _TransactionHeroHeader({required this.isDark, required this.scrollOffset});
  final bool isDark;
  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: title + description
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Hero(
                  tag: 'tx-title',
                  child: Text(
                    l10n.transactions,
                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.transactionsSubtitle,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Right: illustration image from assets
          SizedBox(
            width: 100,
            height: 100,
            child: Image.asset(
              'assets/images/transaction_hero.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      ),
    );
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
                          ref
                              .read(transactionFilterProvider.notifier)
                              .setCategory(null);
                          ref
                              .read(transactionFilterProvider.notifier)
                              .setType(null);
                        },
                      ),
                      ...categories.map((cat) {
                        final isSelected =
                            filterState.categoryId == cat['id']?.toString();
                        final defaultTypeColor = cat['type'] == 'income'
                            ? AppColors.success
                            : (cat['type'] == 'expense'
                                ? AppColors.danger
                                : AppColors.primary);
                        final catColor = AppColors.colorFromHex(
                            cat['colorCode'] as String?,
                            fallback: defaultTypeColor);
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildCategoryChip(
                            context: context,
                            isSelected: isSelected,
                            label:
                                '${cat['emojiIcon'] ?? cat['emoji'] ?? '📁'} ${cat['name'] ?? 'Unknown'}',
                            color: catColor,
                            onTap: () {
                              ref
                                  .read(transactionFilterProvider.notifier)
                                  .setCategory(cat['id']?.toString());
                              ref
                                  .read(transactionFilterProvider.notifier)
                                  .setType(null);
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
          color: isSelected
              ? color
              : (isDark
                  ? AppColors.surfaceDark
                  : AppColors.borderLight.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
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

    final txCurrency =
        tx['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencyCode =
        ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final txCurrencySymbol = AppConstants.getCurrencySymbol(txCurrency);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);
    final fmtOriginal = NumberFormat.currency(
        locale: 'en_US', symbol: txCurrencySymbol, decimalDigits: 0);
    final dynamic category = tx['category'];
    final dynamic savingsGoal = tx['savingsGoal'];
    final emoji = (category is Map
            ? (category['emojiIcon'] as String? ?? category['emoji'] as String?)
            : null) ??
        (isIncome ? '💰' : '💸');

    final catName = category is Map ? category['name'] as String? : null;
    final title = tx['title'] as String? ??
        tx['note'] as String? ??
        catName ??
        l10n.transaction;

    final defaultTypeColor = isIncome ? AppColors.success : AppColors.danger;
    final catColor = category is Map
        ? AppColors.colorFromHex(category['colorCode'] as String?,
            fallback: defaultTypeColor)
        : defaultTypeColor;

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
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondaryLight
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          catName ?? l10n.transaction,
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      if (savingsGoal != null && savingsGoal is Map)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🎨 ${savingsGoal['name']}',
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
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
                      final convertedAsync =
                          ref.watch(convertedAmountProvider(ConversionParams(
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
                            width: 20,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2)),
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
    final currencyCode =
        ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

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
      highlightColor:
          isDark ? const Color(0xFF4A5568) : const Color(0xFFF7FAFC),
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
