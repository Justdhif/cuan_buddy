import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/widgets/sticky_header_delegate.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../profile/data/services/backup_worker.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/services/widget_service.dart';
import '../../../../core/providers/widget_preferences_provider.dart';
import '../../../savings/presentation/providers/savings_provider.dart';
import '../widgets/ai_insight_card.dart';
import '../../transactions/presentation/widgets/ai_voice_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Initialise Socket.IO connection once profile loads, then warm-up
    // the notifications provider so its socket listener is registered
    // immediately after the connection is established.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = await ref.read(profileProvider.future);
      final userId = profile['userId'] as String? ?? profile['id'] as String?;
      if (userId != null && userId.isNotEmpty) {
        ref.read(socketServiceProvider).connect(userId);
        // Warm-up the notifications provider *after* connect() so that its
        // onConnected callback fires with the correct timing.
        ref.read(notificationsNotifierProvider);
        // Check for auto backup on launch
        ref.read(backupWorkerProvider).checkAndRunAutoBackup();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final healthAsync = ref.watch(financialHealthProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final profileAsync = ref.watch(profileProvider);
    final analyticsState = ref.watch(analyticsNotifierProvider);

    ref.listen<AsyncValue<Map<String, dynamic>>>(analyticsSummaryProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final data = next.value!;
        final balance = (data['balance'] as num? ?? 0).toDouble();
        final income = (data['totalIncome'] as num? ?? 0).toDouble();
        final expense = (data['totalExpense'] as num? ?? 0).toDouble();
        final currency = profileAsync.value?['currency'] as String? ?? AppConstants.defaultCurrency;
        
        // Push data to Android Homescreen Widget
        WidgetService.updateWidgetData(balance: balance, income: income, expense: expense, currency: currency);
      }
    });

    ref.listen<SavingsState>(savingsNotifierProvider, (previous, next) {
      final selectedGoalId = ref.read(selectedSavingsWidgetIdProvider);
      if (selectedGoalId != null) {
        try {
          final goal = next.goals.firstWhere((g) => g['id'] == selectedGoalId);
          final rawT = goal['targetAmount'];
          final rawS = goal['savedAmount'];
          final target = rawT is num ? rawT.toDouble() : double.tryParse(rawT?.toString() ?? '0') ?? 0;
          final saved = rawS is num ? rawS.toDouble() : double.tryParse(rawS?.toString() ?? '0') ?? 0;
          final currency = profileAsync.value?['currency'] as String? ?? AppConstants.defaultCurrency;
          final emoji = goal['icon'] as String? ?? '🎯';
          final name = goal['name'] as String? ?? 'Savings Goal';

          WidgetService.updateSavingsWidgetData(
            emoji: emoji,
            name: name,
            savedAmount: saved,
            targetAmount: target,
            currency: currency,
          );
        } catch (e) {
          // Goal not found or error parsing
        }
      }
    });

    return Scaffold(
      floatingActionButton: AiVoiceButton(
        onTransactionAdded: () {
          ref.invalidate(analyticsSummaryProvider);
          ref.invalidate(financialHealthProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.read(analyticsNotifierProvider.notifier).fetchAllAnalytics();
        },
      ),
      body: GestureDetector(
        onTap: () {},
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                double offset = 0.0;
                if (_scrollController.hasClients) {
                  offset = _scrollController.offset;
                }
                // Prevent it from pulling down when overscrolling at the top
                if (offset < 0) offset = 0;
                return Positioned(
                  top: -offset,
                  left: 0,
                  right: 0,
                  child: child!,
                );
              },
              child: const _TimeSceneryBackground(),
            ),
            Positioned.fill(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(analyticsSummaryProvider);
                  ref.invalidate(financialHealthProvider);
                  ref.invalidate(recentTransactionsProvider);
                  ref.read(analyticsNotifierProvider.notifier).fetchAllAnalytics();
                },
                color: AppColors.primary,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _DashboardHeaderDelegate(
                        minHeight: 120, // Approximate header height
                        maxHeight: 120,
                        baseColor: Theme.of(context).scaffoldBackgroundColor,
                        builder: (context, shrinkOffset) {
                          return _buildHeader(context, ref, profileAsync, shrinkOffset);
                        },
                      ),
                    ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: summaryAsync.when(
                    skipLoadingOnReload: true,
                    data: (data) => _buildBalanceCard(data, profileAsync),
                    loading: () => const SkeletonCard(height: 220),
                    error: (_, __) => const SkeletonCard(height: 220),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: AiInsightCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: healthAsync.when(
                    skipLoadingOnReload: true,
                    data: (data) => _buildHealthWidget(data),
                    loading: () => const SkeletonCard(height: 80),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.recentActivities,
                          style: AppTypography.textTheme.titleMedium),
                      TextButton(
                        onPressed: () => context.go('/home/transactions'),
                        child: Text(l10n.seeAll),
                      ),
                    ],
                  ),
                ),
              ),
              transactionsAsync.when(
                skipLoadingOnReload: true,
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return SliverToBoxAdapter(
                      child: AppEmptyState(
                        emoji: '💸',
                        title: l10n.noTransactionsYetTitle,
                        subtitle: l10n.noTransactionsYetSubtitle,
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildTransactionTile(transactions[i], profileAsync),
                      childCount: transactions.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SkeletonList()),
                error: (_, __) => SliverToBoxAdapter(
                  child: AppErrorState(message: l10n.failedToLoadTransactionsError),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Analytics: Spending by Category ─────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.spendingByCategory,
                          style: AppTypography.textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              if (analyticsState.isLoading && analyticsState.spendingByCategory.isEmpty)
                const SliverToBoxAdapter(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SkeletonList(itemCount: 3),
                ))
              else if (analyticsState.spendingByCategory.isEmpty)
                SliverToBoxAdapter(
                  child: AppEmptyState(
                    emoji: '📊',
                    title: l10n.noSpendingData,
                    subtitle: l10n.addExpensesToSeeBreakdown,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                    child: _buildSpendingChart(
                      context,
                      analyticsState.spendingByCategory,
                      profileAsync,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Analytics: Monthly Trend ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(l10n.monthlyTrend,
                      style: AppTypography.textTheme.titleMedium),
                ),
              ),
              if (analyticsState.isLoading && analyticsState.monthlyTrend.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SkeletonCard(height: 220),
                  ),
                )
              else if (analyticsState.monthlyTrend.isEmpty)
                SliverToBoxAdapter(
                  child: AppEmptyState(
                    emoji: '📈',
                    title: l10n.noTrendData,
                    subtitle: l10n.startRecordingToSeeTrend,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildMonthlyTrendChart(
                      context,
                      analyticsState.monthlyTrend,
                      profileAsync,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>> profileAsync,
    double shrinkOffset,
  ) {
    final profile = profileAsync.value ?? {};
    final name = profile['fullName'] as String? ?? 'You';
    final firstName = name.split(' ').first;
    
    final notificationsState = ref.watch(notificationsNotifierProvider);
    final unreadCount = notificationsState.notifications
        .where((n) => !(n['isRead'] as bool? ?? false))
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/icon/app_icon.png',
            width: 36,
            height: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cuan Buddy',
              style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => context.push('/ai-chat'),
                icon: const Text('🤖', style: TextStyle(fontSize: 20)),
                tooltip: l10n.aiAdvisor,
              ),
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, dynamic> data, AsyncValue<Map<String, dynamic>> profileAsync) {
    final balance = (data['balance'] as num? ?? 0).toDouble();
    final income = (data['totalIncome'] as num? ?? 0).toDouble();
    final expense = (data['totalExpense'] as num? ?? 0).toDouble();
    final currencyCode = profileAsync.value?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(
        locale: 'en_US',
        symbol: currencySymbol,
        decimalDigits: 0);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalBalance,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _miniStat(l10n.income, fmt.format(income))),
              const SizedBox(width: 12),
              Expanded(
                  child: _miniStat(l10n.expense, fmt.format(expense))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildHealthWidget(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'healthy';
    final message = data['message'] as String?;
    final healthState = switch (status) {
      'warning' => FinancialHealthState.sweating,
      'critical' || 'danger' => FinancialHealthState.panic,
      _ => FinancialHealthState.happy,
    };
    return FinancialHealthWidget(healthState: healthState, message: message);
  }

  Widget _buildTransactionTile(dynamic transaction, AsyncValue<Map<String, dynamic>> profileAsync) {
    final tx = transaction as Map<String, dynamic>;
    final isIncome = tx['type'] == 'income';
    final amountRaw = tx['amount'];
    final amount = amountRaw is num 
        ? amountRaw.toDouble() 
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;
    final txCurrency = tx['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencyCode = profileAsync.value?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(txCurrency);
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
        l10n.transaction;
    final rawDate = tx['date'] as String?;
    final date = rawDate != null
        ? DateFormat('d MMM', 'en_US').format(DateTime.parse(rawDate))
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${fmt.format(amount)}',
                  style: TextStyle(
                    color: isIncome ? AppColors.successDark : AppColors.dangerDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
                        data: (converted) {
                          final userFmt = NumberFormat.currency(
                              locale: 'en_US',
                              symbol: AppConstants.getCurrencySymbol(currencyCode),
                              decimalDigits: 0);
                          return Text(
                            '≈ ${isIncome ? '+' : '-'}${userFmt.format(converted)}',
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          width: 12, height: 12, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        ),
                        error: (_, __) => const SizedBox.shrink(),
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

  Widget _buildSpendingChart(
    BuildContext context,
    List<dynamic> categories,
    AsyncValue<Map<String, dynamic>> profileAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyCode =
        profileAsync.value?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

    final total = categories.fold<double>(
        0, (sum, c) => sum + ((c['amount'] as num?)?.toDouble() ?? 0));

    // Build pie sections
    final sections = categories.asMap().entries.map((entry) {
      final i = entry.key;
      final cat = entry.value as Map<String, dynamic>;
      final amount = (cat['amount'] as num?)?.toDouble() ?? 0;
      final pct = total > 0 ? (amount / total * 100) : 0;
      final color = AppColors.chartColors[i % AppColors.chartColors.length];
      return PieChartSectionData(
        color: color,
        value: amount,
        title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 70,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie chart
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 48,
                sectionsSpace: 3,
                pieTouchData: PieTouchData(enabled: false),
              ),
            ),
          ),
          // Center hole label
          const SizedBox(height: 20),
          // Legend
          ...categories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value as Map<String, dynamic>;
            final name = cat['category'] as String? ?? l10n.other;
            final emoji =
                cat['emojiIcon'] as String? ?? cat['emoji'] as String? ?? '📦';
            final amount = (cat['amount'] as num?)?.toDouble() ?? 0;
            final pct = total > 0 ? (amount / total * 100) : 0;
            final color =
                AppColors.chartColors[i % AppColors.chartColors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fmt.format(amount),
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(
    BuildContext context,
    List<dynamic> monthlyTrend,
    AsyncValue<Map<String, dynamic>> profileAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyCode =
        profileAsync.value?['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

    final data = monthlyTrend.length > 6
        ? monthlyTrend.sublist(monthlyTrend.length - 6)
        : monthlyTrend;

    double maxVal = 0;
    for (final row in data) {
      final inc = (row['income'] as num?)?.toDouble() ?? 0;
      final exp = (row['expense'] as num?)?.toDouble() ?? 0;
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    final yMax = maxVal == 0 ? 100.0 : maxVal * 1.25;

    final barGroups = data.asMap().entries.map((entry) {
      final i = entry.key;
      final row = entry.value as Map<String, dynamic>;
      final income = (row['income'] as num?)?.toDouble() ?? 0;
      final expense = (row['expense'] as num?)?.toDouble() ?? 0;
      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: income,
            color: AppColors.success,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: expense,
            color: AppColors.danger,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    String shortMonth(String ym) {
      final parts = ym.split('-');
      if (parts.length < 2) return ym;
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMM').format(dt);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _trendLegendDot(AppColors.success, l10n.incomeType),
              const SizedBox(width: 16),
              _trendLegendDot(AppColors.danger, l10n.expenseType),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: yMax,
                minY: 0,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final row = data[group.x] as Map<String, dynamic>;
                      final label = rodIndex == 0 ? l10n.incomeType : l10n.expenseType;
                      final val = rodIndex == 0
                          ? (row['income'] as num?)?.toDouble() ?? 0
                          : (row['expense'] as num?)?.toDouble() ?? 0;
                      return BarTooltipItem(
                        '$label\n${fmt.format(val)}',
                        TextStyle(
                          color: rodIndex == 0
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: yMax / 4,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == yMax) {
                          return const SizedBox.shrink();
                        }
                        final label = value >= 1000000
                            ? '${(value / 1000000).toStringAsFixed(1)}M'
                            : value >= 1000
                                ? '${(value / 1000).toStringAsFixed(0)}K'
                                : value.toStringAsFixed(0);
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final month =
                            (data[idx] as Map<String, dynamic>)['month']
                                as String? ??
                                '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            shortMonth(month),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget Function(BuildContext, double) builder;
  final double minHeight;
  final double maxHeight;
  final Color baseColor;

  _DashboardHeaderDelegate({
    required this.builder,
    required this.minHeight,
    required this.maxHeight,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Opacity increases as we scroll up to 50 pixels
    final double opacity = (shrinkOffset / 50).clamp(0.0, 1.0);
    return Container(
      color: baseColor.withValues(alpha: opacity),
      child: builder(context, shrinkOffset),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _DashboardHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        baseColor != oldDelegate.baseColor;
  }
}

class _TimeSceneryBackground extends StatelessWidget {
  const _TimeSceneryBackground();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    
    List<Color> gradientColors;
    String emoji;
    
    if (hour >= 6 && hour < 12) {
      // Morning
      gradientColors = [const Color(0xFF87CEEB).withValues(alpha: 0.6), const Color(0xFFFFE4B5).withValues(alpha: 0.2)];
      emoji = '🌅';
    } else if (hour >= 12 && hour < 15) {
      // Afternoon
      gradientColors = [const Color(0xFF00BFFF).withValues(alpha: 0.6), const Color(0xFF87CEEB).withValues(alpha: 0.2)];
      emoji = '☀️';
    } else if (hour >= 15 && hour < 19) {
      // Evening
      gradientColors = [const Color(0xFFFF7E5F).withValues(alpha: 0.6), const Color(0xFFFEB47B).withValues(alpha: 0.2)];
      emoji = '🌇';
    } else {
      // Night
      gradientColors = [const Color(0xFF2C3E50).withValues(alpha: 0.8), const Color(0xFF000000).withValues(alpha: 0.4)];
      emoji = '🌙';
    }

    return Container(
      height: 350,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 40,
            top: 60,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 100),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
