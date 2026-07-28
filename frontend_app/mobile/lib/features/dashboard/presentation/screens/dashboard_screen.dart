import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
import '../../../../core/services/notification_service.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../transactions/presentation/widgets/ai_voice_sheet.dart';
import '../../../transactions/presentation/widgets/ai_scan_sheet.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  late ScrollController _scrollController;
  late PageController _budgetPageController;
  bool _showBalance = true;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _budgetPageController = PageController(viewportFraction: 0.93);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = await ref.read(profileProvider.future);
      final userId = profile['userId'] as String? ?? profile['id'] as String?;
      if (userId != null && userId.isNotEmpty) {
        ref.read(socketServiceProvider).connect(userId);
        ref.read(notificationsNotifierProvider);

        try {
          final fcmToken = await NotificationService().getFcmToken();
          if (fcmToken != null) {
            await ref
                .read(dioClientProvider)
                .dio
                .patch('/profiles/fcm-token', data: {'token': fcmToken});
            debugPrint('FCM Token uploaded successfully.');
          }
        } catch (e) {
          debugPrint('Failed to upload FCM token to backend: $e');
        }

        try {
          final lang = ref.read(languageProvider);
          await ref
              .read(dioClientProvider)
              .dio
              .patch('/profiles/me', data: {'language': lang});
          debugPrint('Language setting synchronized to backend: $lang');
        } catch (_) {}

        ref.read(backupWorkerProvider).checkAndRunAutoBackup();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isScrolled = _scrollController.offset > 15;
      if (isScrolled != _isScrolled) {
        setState(() {
          _isScrolled = isScrolled;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _budgetPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final profileAsync = ref.watch(profileProvider);
    final analyticsState = ref.watch(analyticsNotifierProvider);
    final budgetsState = ref.watch(budgetsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsState = ref.watch(notificationsNotifierProvider);
    final unreadCount = notificationsState.notifications
        .where((n) => !(n['isRead'] as bool? ?? false))
        .length;

    ref.listen<AsyncValue<Map<String, dynamic>>>(analyticsSummaryProvider,
        (previous, next) {
      if (next.hasValue && next.value != null) {
        final data = next.value!;
        final balance = (data['balance'] as num? ?? 0).toDouble();
        final income = (data['totalIncome'] as num? ?? 0).toDouble();
        final expense = (data['totalExpense'] as num? ?? 0).toDouble();
        final currency = profileAsync.valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;

        WidgetService.updateWidgetData(
            balance: balance,
            income: income,
            expense: expense,
            currency: currency);
      }
    });

    // Warna background gelap dipakai bareng di header (bottom radius) & Scaffold
    final bodyBgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bodyBgColor, // <-- TAMBAHAN
      body: GestureDetector(
        onTap: () {},
        child: Stack(
          children: [
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
                    SliverToBoxAdapter(
                      child: _buildTopHeaderAndBalance(
                        context,
                        ref,
                        summaryAsync,
                        profileAsync,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildQuickActionsRow(context, isDark),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: AiInsightCard(),
                      ),
                    ),
                    // ── 3. Recent Transactions Section ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.languageCode == 'id'
                                  ? 'Transaksi Terbaru'
                                  : 'Recent Transactions',
                              style: AppTypography.textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: () => context.push('/home/transactions'),
                              child: Text(l10n.seeAll),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildAiTransactionButtons(context, isDark),
                    ),
                    transactionsAsync.when(
                      skipLoadingOnReload: true,
                      data: (transactions) {
                        if (transactions.isEmpty) {
                          return SliverToBoxAdapter(
                            child: AppEmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: l10n.noTransactionsYetTitle,
                              subtitle: l10n.noTransactionsYetSubtitle,
                            ),
                          );
                        }
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) =>
                                TransactionCard(transaction: transactions[i]),
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

                    // ── 4. Budgets Section ───────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text(
                          l10n.languageCode == 'id'
                              ? 'Anggaran Terbaru'
                              : 'Recent Budget',
                          style: AppTypography.textTheme.titleMedium,
                        ),
                      ),
                    ),
                    if (budgetsState.isInitialLoad)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: SkeletonCard(height: 165),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 165,
                          child: PageView.builder(
                            controller: _budgetPageController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: budgetsState.budgets.isEmpty
                                ? 1
                                : budgetsState.budgets.length + 1,
                            itemBuilder: (context, index) {
                              Widget card;
                              if (index == budgetsState.budgets.length) {
                                card = _buildAddBudgetCard(context, isDark);
                              } else {
                                final currencyCode = profileAsync
                                        .valueOrNull?['currency'] as String? ??
                                    AppConstants.defaultCurrency;
                                final currencySymbol =
                                    AppConstants.getCurrencySymbol(
                                        currencyCode);
                                card = BudgetCard(
                                  budget: budgetsState.budgets[index],
                                  isDark: isDark,
                                  currencySymbol: currencySymbol,
                                );
                              }
                              return Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: card,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── 5. Analytics: Monthly Trend ─────────────────────────────
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildFixedTopHeader(context, ref, unreadCount, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final isId = l10n.languageCode == 'id';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              context: context,
              icon: Icons.add_rounded,
              label: isId ? 'Tambah' : 'Add',
              color: AppColors.primary,
              isDark: isDark,
              onTap: () => context.push('/transactions/form?type=expense'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionButton(
              context: context,
              icon: Icons.pie_chart_rounded,
              label: l10n.budgets,
              color: Colors.purple,
              isDark: isDark,
              onTap: () => context.push('/home/budgets'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionButton(
              context: context,
              icon: Icons.savings_rounded,
              label: l10n.savingsGoals,
              color: Colors.orange,
              isDark: isDark,
              onTap: () => context.push('/home/savings'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionButton(
              context: context,
              icon: Icons.account_balance_wallet_rounded,
              label: isId ? 'Dompet' : 'Wallets',
              color: const Color(0xFF0D9488),
              isDark: isDark,
              onTap: () => context.push('/manage-wallets'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiTransactionButtons(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final isId = l10n.languageCode == 'id';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildRedesignedAiButton(
              context: context,
              title: isId ? 'Voice AI' : 'Voice AI',
              subtitle: isId ? 'Input Bicara' : 'Voice Input',
              badgeText: 'AI Voice',
              icon: Icons.mic_rounded,
              gradientColors: isDark
                  ? [const Color(0xFF4F46E5), const Color(0xFF7C3AED)]
                  : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              shadowColor:
                  const Color(0xFF6366F1).withValues(alpha: isDark ? 0.35 : 0.25),
              isDark: isDark,
              onTap: () async {
                final result = await showAiVoiceSheet(context);
                if (result == true) {
                  ref.invalidate(analyticsSummaryProvider);
                  ref.invalidate(recentTransactionsProvider);
                  ref.invalidate(allTransactionsProvider);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildRedesignedAiButton(
              context: context,
              title: isId ? 'Scan Struk' : 'Scan Receipt',
              subtitle: isId ? 'Ekstrak Struk' : 'Auto Extract',
              badgeText: 'AI Scan',
              icon: Icons.document_scanner_rounded,
              gradientColors: isDark
                  ? [const Color(0xFF059669), const Color(0xFF0D9488)]
                  : [const Color(0xFF10B981), const Color(0xFF14B8A6)],
              shadowColor:
                  const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25),
              isDark: isDark,
              onTap: () async {
                final result = await showAiScanSheet(context);
                if (result == true) {
                  ref.invalidate(analyticsSummaryProvider);
                  ref.invalidate(recentTransactionsProvider);
                  ref.invalidate(allTransactionsProvider);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedesignedAiButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -12,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 10,
                              color: Colors.amberAccent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedTopHeader(
    BuildContext context,
    WidgetRef ref,
    int unreadCount,
    bool isDark,
  ) {
    final appBgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        20,
        12,
      ),
      decoration: BoxDecoration(
        color: _isScrolled ? appBgColor : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: _isScrolled
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06))
                : Colors.transparent,
            width: 1,
          ),
        ),
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/icon/app_icon.png',
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 10),
          Text(
            'Cuan Buddy',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: _isScrolled
                  ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                  : Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/home/profile'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _isScrolled
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05))
                    : Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: _isScrolled
                    ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _isScrolled
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05))
                    : Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 20,
                    color: _isScrolled
                        ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                        : Colors.white,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeaderAndBalance(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>> summaryAsync,
    AsyncValue<Map<String, dynamic>> profileAsync,
  ) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider);
    final HSLColor hsl = HSLColor.fromColor(accentColor);
    final Color darkerAccent =
        hsl.withLightness((hsl.lightness * 0.22).clamp(0.0, 1.0)).toColor();
    final Color lighterAccent =
        hsl.withLightness((hsl.lightness * 0.40).clamp(0.0, 1.0)).toColor();

    final data = summaryAsync.valueOrNull ?? {};
    final balance = (data['balance'] as num? ?? 0).toDouble();
    final expense = (data['totalExpense'] as num? ?? 0).toDouble();
    final currencyCode = profileAsync.valueOrNull?['currency'] as String? ??
        AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);

    final displayBalance = _showBalance
        ? CurrencyFormatter.formatAmount(balance, symbol: currencySymbol)
        : '••••••••';

    final displayExpense =
        CurrencyFormatter.formatAmount(expense, symbol: currencySymbol);
    final currentMonthName =
        DateFormat('MMMM', l10n.languageCode).format(DateTime.now());
    final expenseLabel = l10n.languageCode == 'id'
        ? '$displayExpense pengeluaran di $currentMonthName'
        : '$displayExpense spent in $currentMonthName';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          // <-- TAMBAHAN
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  lighterAccent,
                  darkerAccent,
                ]
              : [
                  accentColor,
                  lighterAccent,
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HeaderPatternPainter(accentColor: accentColor),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 64,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summaryAsync.isLoading && !summaryAsync.hasValue)
                  const SkeletonCard(height: 60)
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        displayBalance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showBalance = !_showBalance;
                          });
                        },
                        child: Icon(
                          _showBalance
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.push('/home/transactions'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          expenseLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const FinanceHealthHeaderWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBudgetCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/budgets/form'),
      child: Container(
        height: 160,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5),
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
              child: Icon(
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

  Widget _buildMonthlyTrendChart(
    BuildContext context,
    List<dynamic> monthlyTrend,
    AsyncValue<Map<String, dynamic>> profileAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyCode = profileAsync.valueOrNull?['currency'] as String? ??
        AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);

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
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
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
                        final label =
                            isIncome ? l10n.incomeType : l10n.expenseType;
                        final color =
                            isIncome ? AppColors.success : AppColors.danger;
                        return LineTooltipItem(
                          '$label\n${CurrencyFormatter.formatAmount(val, symbol: currencySymbol)}',
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final month = (data[idx]
                                as Map<String, dynamic>)['month'] as String? ??
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

// ─── Saldo Header Background Custom Pattern Painter ───────────────────────────
class _HeaderPatternPainter extends CustomPainter {
  final Color accentColor;

  _HeaderPatternPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ambient Glow Orbs (Soft Lighting & Visual Depth)
    final orbPaint1 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.85, size.height * 0.20),
        size.width * 0.65,
        [
          accentColor.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        [0.0, 0.45, 1.0],
      )
      ..style = PaintingStyle.fill;

    final orbPaint2 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.15, size.height * 0.85),
        size.width * 0.50,
        [
          Colors.white.withValues(alpha: 0.12),
          accentColor.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        [0.0, 0.50, 1.0],
      )
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, orbPaint1);
    canvas.drawRect(Offset.zero & size, orbPaint2);

    // 2. Modern Fintech Micro Dot Matrix
    const double spacing = 22.0;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final accentDotPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    for (double x = 12; x < size.width; x += spacing) {
      for (double y = 12; y < size.height; y += spacing) {
        if ((x / spacing).floor() % 3 == 0 && (y / spacing).floor() % 3 == 0) {
          canvas.drawCircle(Offset(x, y), 1.6, accentDotPaint);
        } else {
          canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
        }
      }
    }

    // 3. Financial Upward Growth Waves (Smooth Bezier Curves)
    final wavePath1 = Path();
    wavePath1.moveTo(-20, size.height * 0.75);
    wavePath1.cubicTo(
      size.width * 0.25,
      size.height * 0.95,
      size.width * 0.45,
      size.height * 0.35,
      size.width * 0.75,
      size.height * 0.45,
    );
    wavePath1.cubicTo(
      size.width * 0.90,
      size.height * 0.50,
      size.width * 0.95,
      size.height * 0.15,
      size.width + 20,
      size.height * 0.10,
    );

    final wavePaint1 = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height),
        Offset(size.width, 0),
        [
          Colors.white.withValues(alpha: 0.05),
          accentColor.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.50),
        ],
        [0.0, 0.6, 1.0],
      )
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(wavePath1, wavePaint1);

    // Secondary Financial Wave Curve
    final wavePath2 = Path();
    wavePath2.moveTo(-20, size.height * 0.55);
    wavePath2.cubicTo(
      size.width * 0.30,
      size.height * 0.30,
      size.width * 0.60,
      size.height * 0.85,
      size.width + 20,
      size.height * 0.30,
    );

    final wavePaint2 = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [
          accentColor.withValues(alpha: 0.30),
          Colors.white.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      )
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawPath(wavePath2, wavePaint2);

    // Soft Glowing Gradient Wave Fill Layer
    final fillPath = Path.from(wavePath1);
    fillPath.lineTo(size.width + 20, size.height + 20);
    fillPath.lineTo(-20, size.height + 20);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.3),
        Offset(0, size.height),
        [
          accentColor.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 4. Financial Geometric Diamond Accents
    _drawDiamond(canvas, Offset(size.width * 0.88, size.height * 0.22), 12,
        accentColor.withValues(alpha: 0.30), isFilled: false);
    _drawDiamond(canvas, Offset(size.width * 0.88, size.height * 0.22), 5,
        Colors.white.withValues(alpha: 0.50), isFilled: true);

    _drawDiamond(canvas, Offset(size.width * 0.72, size.height * 0.78), 9,
        Colors.white.withValues(alpha: 0.20), isFilled: false);
    _drawDiamond(canvas, Offset(size.width * 0.12, size.height * 0.35), 7,
        accentColor.withValues(alpha: 0.25), isFilled: false);

    // 5. Tech Concentric Precision Ring Halos (Corner Accent)
    final ringCenter = Offset(size.width * 0.92, size.height * 0.18);
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final ringAccentPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.20)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(ringCenter, 28, ringPaint);
    canvas.drawCircle(ringCenter, 56, ringAccentPaint);
    canvas.drawCircle(ringCenter, 84, ringPaint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Color color,
      {required bool isFilled}) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.75, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.75, center.dy)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeaderPatternPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}
