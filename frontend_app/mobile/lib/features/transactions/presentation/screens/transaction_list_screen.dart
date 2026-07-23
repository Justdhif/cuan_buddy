import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/ai_voice_sheet.dart';
import '../widgets/ai_scan_sheet.dart';
import '../widgets/transaction_calendar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../shared/widgets/transaction_card.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Speed-dial FAB state
  bool _fabOpen = false;
  late AnimationController _fabController;
  late Animation<double> _fade1, _fade2, _fade3;
  late Animation<Offset> _slide1, _slide2, _slide3;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    // Staggered intervals: btn1 first (closest to main), btn2 middle, btn3 last (topmost)
    _fade1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _fade2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.2, 0.7, curve: Curves.easeOut)),
    );
    _fade3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
    _slide1 =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _slide2 =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.2, 0.7, curve: Curves.easeOut)),
    );
    _slide3 =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
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
      body: Stack(
        children: [
          RefreshIndicator(
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
                // ── Hero content — scrolls naturally with the page ─────────────
                SliverToBoxAdapter(
                  child: _TransactionHeroHeader(isDark: isDark),
                ),
            const SliverToBoxAdapter(
              child: TransactionCalendar(),
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
                    icon: Icons.receipt_long_outlined,
                    title: l10n.noTransactionsYetTitle,
                    subtitle: l10n.noTransactionsYetSubtitle,
                    action: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.push('/transactions/form', extra: {'initialType': 'expense'});
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        l10n.addTransaction,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              )
            else if (transactionsAsync.hasValue) ...[
              Consumer(
                builder: (context, ref, child) {
                  final transactions = transactionsAsync.value!;
                  final balanceAsync = ref.watch(transactionListBalanceProvider);

                  return SliverPadding(
                    padding: const EdgeInsets.only(top: 0, bottom: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == transactions.length) {
                            return balanceAsync.when(
                              data: (balance) => _BottomCashflowSummary(
                                balance: balance,
                                transactionsCount: transactions.length,
                              ),
                              loading: () => const SizedBox(
                                height: 80,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (_, __) => const SizedBox(),
                            );
                          }
                          final item = transactions[index];
                          return TransactionCard(transaction: item);
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
          // ── Pinned AppBar Background (appears on scroll) ─────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Builder(builder: (context) {
              final t = (_scrollOffset / 60).clamp(0.0, 1.0);
              return Opacity(
                opacity: t,
                child: Container(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  color: bgColor,
                ),
              );
            }),
          ),
          // ── Floating animated title (moves from hero to AppBar) ──────────────
          _buildFloatingTitle(context, l10n, isDark, bgColor),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Staggered sub-buttons (always in tree for smooth exit animation) ──
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sub 3 - Scan Receipt (topmost, animates third)
              _buildSubFab(
                icon: Icons.document_scanner_rounded,
                onTap: () async {
                  _toggleFab();
                  final result = await showAiScanSheet(context);
                  if (result == true) {
                    ref.invalidate(allTransactionsProvider);
                  }
                },
                fadeAnim: _fade3,
                slideAnim: _slide3,
              ),
              const SizedBox(height: 12),
              // Sub 2 – Mic (middle, animates second)
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

  /// Floating title that physically moves from hero position to AppBar as user scrolls.
  Widget _buildFloatingTitle(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    Color bgColor,
  ) {
    final statusBarH = MediaQuery.of(context).padding.top;
    const appBarH = kToolbarHeight;
    // Hero title Y: statusBar + 12 padding + 8 SizedBox + ~14 half-text
    final heroTitleY = statusBarH + 12.0 + 8.0 + 14.0;
    // AppBar title Y: vertically centered in AppBar
    final appBarTitleY = statusBarH + appBarH / 2.0 - 13.0;
    final travelDist = heroTitleY - appBarTitleY;

    // t: 0 = title at hero, 1 = title at AppBar
    final t = (_scrollOffset / travelDist.abs()).clamp(0.0, 1.0);
    var currentY = lerpDouble(heroTitleY, appBarTitleY, t)!;

    // Adjust for overscroll (pull to refresh)
    // When _scrollOffset is negative, the slivers move down. We must move the floating title down by the same amount.
    if (_scrollOffset < 0) {
      currentY -= _scrollOffset; 
    }

    // Font size: headlineMedium -> titleLarge
    final heroSize = AppTypography.textTheme.headlineMedium?.fontSize ?? 28.0;
    final appBarSize = AppTypography.textTheme.titleLarge?.fontSize ?? 22.0;
    final currentSize = lerpDouble(heroSize, appBarSize, t)!;

    return Positioned(
      top: currentY,
      left: 24.0,
      right: 120.0,
      child: GestureDetector(
        onTap: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
        child: Text(
          l10n.transactions,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: currentSize,
            fontWeight: FontWeight.bold,
            fontFamily: AppTypography.textTheme.headlineMedium?.fontFamily,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}

// ── Hero Header Widget ────────────────────────────────────────────────────────
class _TransactionHeroHeader extends StatelessWidget {
  const _TransactionHeroHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
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
                // Invisible placeholder — floating title handles rendering
                Opacity(
                  opacity: 0,
                  child: Text(
                    l10n.transactions,
                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
            width: 88,
            height: 88,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Center main – wallet
                Positioned(
                  left: 20,
                  top: 20,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 26),
                  ),
                ),
                // Top-right – income arrow up
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: AppColors.success, size: 16),
                  ),
                ),
                // Bottom-left – expense arrow down
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_downward_rounded, color: AppColors.danger, size: 15),
                  ),
                ),
                // Top-left – receipt
                Positioned(
                  left: 2,
                  top: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_rounded, color: Colors.blue, size: 13),
                  ),
                ),
                // Bottom-right – sync/exchange
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.currency_exchange_rounded, color: Colors.amber, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyCode =
        ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: AppCard(
        child: Column(
          children: [
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
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.nTransactions(transactionsCount),
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


