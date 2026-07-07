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
import '../../../../core/providers/core_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../profile/data/services/backup_worker.dart';
import '../../../../core/services/widget_service.dart';
import '../widgets/ai_insight_card.dart';
import '../../../shared/widgets/transaction_card.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../shared/widgets/budget_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  late ScrollController _scrollController;
  late PageController _budgetPageController;
  int _currentBudgetPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _budgetPageController = PageController(viewportFraction: 0.93);
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
    _budgetPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final healthAsync = ref.watch(financialHealthProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final profileAsync = ref.watch(profileProvider);
    final analyticsState = ref.watch(analyticsNotifierProvider);
    final budgetsState = ref.watch(budgetsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<Map<String, dynamic>>>(analyticsSummaryProvider,
        (previous, next) {
      if (next.hasValue && next.value != null) {
        final data = next.value!;
        final balance = (data['balance'] as num? ?? 0).toDouble();
        final income = (data['totalIncome'] as num? ?? 0).toDouble();
        final expense = (data['totalExpense'] as num? ?? 0).toDouble();
        final currency = profileAsync.valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;

        // Push data to Android Homescreen Widget
        WidgetService.updateWidgetData(
            balance: balance,
            income: income,
            expense: expense,
            currency: currency);
      }
    });


    return Scaffold(
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
                  ref
                      .read(analyticsNotifierProvider.notifier)
                      .fetchAllAnalytics();
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
                          return _buildHeader(
                              context, ref, profileAsync, shrinkOffset);
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: summaryAsync.when(
                          skipLoadingOnReload: true,
                          data: (data) => _buildBalanceCard(data, profileAsync, healthAsync),
                          loading: () => const SkeletonCard(height: 220),
                          error: (_, __) => const SkeletonCard(height: 220),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: const AiInsightCard(),
                      ),
                    ),
                    // ── Budgets Section ───────────────────────────────────────
                    if (budgetsState.isInitialLoad)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: SkeletonCard(height: 220),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            height: 240,
                            child: PageView.builder(
                              controller: _budgetPageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentBudgetPage = index;
                                });
                              },
                              physics: const BouncingScrollPhysics(),
                              itemCount: budgetsState.budgets.isEmpty ? 1 : budgetsState.budgets.length + 1,
                              itemBuilder: (context, index) {
                                Widget card;
                                if (index == budgetsState.budgets.length) {
                                  card = _buildAddBudgetCard(context, isDark);
                                } else {
                                  final currencyCode = profileAsync.valueOrNull?['currency'] as String? ?? AppConstants.defaultCurrency;
                                  final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
                                  card = BudgetCard(
                                    budget: budgetsState.budgets[index],
                                    isDark: isDark,
                                    currencySymbol: currencySymbol,
                                  );
                                }
                                return Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: card,
                                  ),
                                );
                              },
                            ),
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
                            (ctx, i) => TransactionCard(transaction: transactions[i]),

                            childCount: transactions.length,
                          ),
                        );
                      },
                      loading: () =>
                          const SliverToBoxAdapter(child: SkeletonList()),
                      error: (_, __) => SliverToBoxAdapter(
                        child: AppErrorState(
                            message: l10n.failedToLoadTransactionsError),
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
                    if (analyticsState.isLoading &&
                        analyticsState.monthlyTrend.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: SkeletonCard(height: 220),
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
      floatingActionButton: GestureDetector(
        onTap: () => context.push('/ai-chat'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 32,
          ),
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
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
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
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/home/profile'),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 28,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _buildAddBudgetCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/budgets/form'),
      child: Container(
        height: 204,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.setBudget,
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    Map<String, dynamic> data,
    AsyncValue<Map<String, dynamic>> profileAsync,
    AsyncValue<Map<String, dynamic>> healthAsync,
  ) {
    final balance = (data['balance'] as num? ?? 0).toDouble();
    final income = (data['totalIncome'] as num? ?? 0).toDouble();
    final expense = (data['totalExpense'] as num? ?? 0).toDouble();
    final currencyCode = profileAsync.valueOrNull?['currency'] as String? ??
        AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
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
                ],
              ),
              healthAsync.when(
                skipLoadingOnReload: true,
                data: (healthData) {
                  final status = healthData['status'] as String? ?? 'healthy';
                  final score = healthData['score'] as int? ?? 100;
                  
                  Color statusColor;
                  IconData statusIcon;
                  
                  switch (status) {
                    case 'warning':
                      statusColor = AppColors.warning;
                      statusIcon = Icons.warning_amber_rounded;
                      break;
                    case 'critical':
                    case 'danger':
                      statusColor = AppColors.danger;
                      statusIcon = Icons.error_outline_rounded;
                      break;
                    default:
                      statusColor = AppColors.success;
                      statusIcon = Icons.health_and_safety_outlined;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          '$score/100',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          healthAsync.when(
            skipLoadingOnReload: true,
            data: (healthData) {
              final message = healthData['message'] as String?;
              if (message == null || message.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.insights_rounded, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _miniStat(l10n.income, fmt.format(income))),
              const SizedBox(width: 12),
              Expanded(child: _miniStat(l10n.expense, fmt.format(expense))),
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





  Widget _buildMonthlyTrendChart(
    BuildContext context,
    List<dynamic> monthlyTrend,
    AsyncValue<Map<String, dynamic>> profileAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyCode = profileAsync.valueOrNull?['currency'] as String? ??
        AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

    List<dynamic> data = [];
    if (monthlyTrend.isEmpty) {
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i);
        data.add({
          'month': '${d.year}-${d.month.toString().padLeft(2, '0')}',
          'income': 0,
          'expense': 0
        });
      }
    } else {
      data = monthlyTrend.length > 6
          ? monthlyTrend.sublist(monthlyTrend.length - 6)
          : monthlyTrend;
    }

    double maxVal = 0;
    for (final row in data) {
      final inc = (row['income'] as num?)?.toDouble() ?? 0;
      final exp = (row['expense'] as num?)?.toDouble() ?? 0;
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    final yMax = maxVal == 0 ? 100.0 : maxVal * 1.25;

    final incomeSpots = data.asMap().entries.map((entry) {
      final val = (entry.value['income'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), val);
    }).toList();

    final expenseSpots = data.asMap().entries.map((entry) {
      final val = (entry.value['expense'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), val);
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
            child: LineChart(
              LineChartData(
                maxY: yMax,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.success.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: AppColors.danger,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.danger.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: yMax / 4,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final val = spot.y;
                        final isIncome = spot.barIndex == 0;
                        final label = isIncome ? l10n.incomeType : l10n.expenseType;
                        final color = isIncome ? AppColors.success : AppColors.danger;
                        return LineTooltipItem(
                          '$label\n${fmt.format(val)}',
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final month = (data[idx] as Map<String, dynamic>)['month'] as String? ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            shortMonth(month),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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

    if (hour >= 6 && hour < 12) {
      // Morning
      gradientColors = [
        const Color(0xFF87CEEB).withValues(alpha: 0.6),
        const Color(0xFFFFE4B5).withValues(alpha: 0.2)
      ];
    } else if (hour >= 12 && hour < 15) {
      // Afternoon
      gradientColors = [
        const Color(0xFF00BFFF).withValues(alpha: 0.6),
        const Color(0xFF87CEEB).withValues(alpha: 0.2)
      ];
    } else if (hour >= 15 && hour < 19) {
      // Evening
      gradientColors = [
        const Color(0xFFFF7E5F).withValues(alpha: 0.6),
        const Color(0xFFFEB47B).withValues(alpha: 0.2)
      ];
    } else {
      // Night
      gradientColors = [
        const Color(0xFF2C3E50).withValues(alpha: 0.8),
        const Color(0xFF000000).withValues(alpha: 0.4)
      ];
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
                    Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0.0),
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
