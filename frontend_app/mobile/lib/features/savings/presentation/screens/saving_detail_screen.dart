import 'dart:ui' show lerpDouble, TextDirection;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:marquee/marquee.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/savings_provider.dart';
import '../../../shared/widgets/transaction_card.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';

// ── Provider: transactions filtered by savingsGoalId ─────────────────────────
final savingsGoalTransactionsProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, goalId) async {
  final dio = ref.watch(dioClientProvider).dio;
  final response = await dio.get(
    '/transactions',
    queryParameters: {'savingsGoalId': goalId, 'limit': 200},
  );
  final data = response.data;
  if (data is List) return data;
  if (data is Map && data['data'] is List) return data['data'] as List;
  return [];
});

class SavingDetailScreen extends ConsumerStatefulWidget {
  const SavingDetailScreen({super.key, required this.goal});
  final Map<String, dynamic> goal;

  @override
  ConsumerState<SavingDetailScreen> createState() => _SavingDetailScreenState();
}

class _SavingDetailScreenState extends ConsumerState<SavingDetailScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // ── Goal helpers ─────────────────────────────────────────────────────────────
  Map<String, dynamic> get _goal {
    // keep local copy in case parent updates
    return _latestGoal ?? widget.goal;
  }

  Map<String, dynamic>? _latestGoal;

  String get _name => _goal['name'] as String? ?? l10n.unnamedGoal;
  String get _emoji => _goal['emojiIcon'] as String? ?? '🎯';
  String get _colorHex => _goal['colorCode'] as String? ?? '#6C63FF';
  Color get _goalColor => AppColors.colorFromHex(_colorHex, fallback: AppColors.primary);
  String get _goalId => _goal['id'] as String? ?? '';
  String get _status => _goal['status'] as String? ?? 'in_progress';

  double get _targetAmount {
    final raw = _goal['targetAmount'];
    return raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '0') ?? 0;
  }

  double get _currentAmount {
    final raw = _goal['currentAmount'];
    return raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '0') ?? 0;
  }

  double get _percentage => _targetAmount > 0 ? (_currentAmount / _targetAmount).clamp(0.0, 1.0) : 0;
  bool get _isCompleted => _status == 'completed' || _percentage >= 1.0;

  Color get _progressColor {
    if (_percentage >= 1.0) return AppColors.success;
    if (_percentage >= 0.7) return AppColors.primary;
    if (_percentage >= 0.4) return const Color(0xFFF59E0B);
    return AppColors.danger;
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (mounted) {
        setState(() => _scrollOffset = _scrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  void _onEdit() {
    context.push('/savings/form', extra: {'goal': _goal}).then((_) async {
      if (mounted) {
        try {
          final dio = ref.read(dioClientProvider).dio;
          final response = await dio.get('/goals/$_goalId');
          if (response.data != null && mounted) {
            setState(() {
              _latestGoal = response.data as Map<String, dynamic>;
            });
          }
        } catch (_) {}
        // Also refresh the global provider list
        ref.read(savingsNotifierProvider.notifier).fetchGoals();
      }
    });
  }

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteGoal),
        content: Text(l10n.deleteGoalConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await ref.read(savingsNotifierProvider.notifier).deleteGoal(_goalId);
        if (mounted) {
          AppSnackbar.show(
            context,
            title: l10n.success,
            message: l10n.deleteGoal,
            type: SnackbarType.success,
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(
            context,
            title: l10n.error,
            message: e.toString(),
            type: SnackbarType.error,
          );
        }
      }
    }
  }

  void _onAddTransaction() {
    context.push('/transactions/form', extra: {
      'initialType': 'income',
      'initialSavingsGoalId': _goalId,
      'lockedSavingsGoal': true,
    }).then((_) {
      // Invalidate transactions and savings to refresh after adding
      ref.invalidate(savingsGoalTransactionsProvider(_goalId));
      ref.read(savingsNotifierProvider.notifier).fetchGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyCode =
        ref.watch(profileProvider).valueOrNull?['currency'] as String? ??
            AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(currencyCode);
    final goalCurrency = _goal['currency'] as String? ?? AppConstants.defaultCurrency;
    final goalCurrencySymbol = AppConstants.getCurrencySymbol(goalCurrency);

    final fmt = NumberFormat.currency(locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);
    final fmtGoal = NumberFormat.currency(locale: 'en_US', symbol: goalCurrencySymbol, decimalDigits: 0);

    final useFmt = goalCurrency == currencyCode;

    final statusBarH = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ── Hero Banner ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeroBanner(context, isDark, useFmt ? fmt : fmtGoal),
              ),

              // ── Info Cards Row ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildInfoCards(context, isDark, useFmt ? fmt : fmtGoal),
                ),
              ),

              // ── Progress Card ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: AppTypography.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            Text(
                              '${fmt.format(_currentAmount)} / ${fmt.format(_targetAmount)}',
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: _percentage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _progressColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: _percentage > 0.15
                                      ? Text(
                                          '${(_percentage * 100).toInt()}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              if (_percentage <= 0.15)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      '${(_percentage * 100).toInt()}%',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_goal['link'] != null && _goal['link'].toString().trim().isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () async {
                          final urlStr = _goal['link'].toString().trim();
                          final uri = Uri.tryParse(urlStr);
                          if (uri != null) {
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  AppSnackbar.show(context,
                                      title: 'Error',
                                      message: 'Could not launch URL',
                                      type: SnackbarType.error);
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackbar.show(context,
                                    title: 'Error',
                                    message: 'Failed to launch link: $e',
                                    type: SnackbarType.error);
                              }
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Target Pembelian',
                                      style: AppTypography.textTheme.labelSmall?.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _goal['link'].toString().trim(),
                                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // ── Transactions Section Header ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _goalColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.transactionHistory,
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Transactions List ─────────────────────────────────────────────
          _buildTransactionSliver(context, isDark, currencyCode, currencySymbol),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // ── Pinned AppBar Background (fades in on scroll) ────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Builder(builder: (context) {
              final t = (_scrollOffset / 60).clamp(0.0, 1.0);
              return Opacity(
                opacity: t,
                child: Container(
                  height: statusBarH + kToolbarHeight,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                ),
              );
            }),
          ),

          // ── Top Bar Buttons ────────────────────────────────────────────────
          Positioned(
            top: statusBarH,
            left: 0,
            right: 0,
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    onPressed: _onEdit,
                    tooltip: l10n.editGoal,
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                    ),
                    onPressed: _onDelete,
                    tooltip: l10n.deleteGoal,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // ── Floating animated title ────────────────────────────────────────
          _buildFloatingTitle(context, isDark, statusBarH),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: _onAddTransaction,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _goalColor,
                Color.lerp(_goalColor, AppColors.primary, 0.4) ?? AppColors.primary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _goalColor.withValues(alpha: 0.4),
                blurRadius: 12,
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
    );
  }

  // ── Hero Banner ─────────────────────────────────────────────────────────────
  Widget _buildHeroBanner(BuildContext context, bool isDark, NumberFormat fmt) {
    final targetDateStr = _goal['targetDate'] as String?;
    String? targetDateFormatted;
    if (targetDateStr != null) {
      try {
        targetDateFormatted = DateFormat('dd MMM yyyy').format(DateTime.parse(targetDateStr).toLocal());
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  _goalColor.withValues(alpha: 0.25),
                  AppColors.surfaceDark,
                ]
              : [
                  _goalColor.withValues(alpha: 0.18),
                  _goalColor.withValues(alpha: 0.04),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: _goalColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _goalColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Savings Icon ─────────────────────────────────────
                      _buildSavingsIcon(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Opacity(
                              opacity: 0.0, // Drawn by floating title
                              child: Text(
                                _name,
                                style: AppTypography.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (_isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.success.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded,
                                            color: AppColors.success, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.completedBadge,
                                          style: AppTypography.textTheme.labelSmall?.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_goal['isPin'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.push_pin_rounded,
                                            color: AppColors.primary, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Pinned',
                                          style: AppTypography.textTheme.labelSmall?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (targetDateFormatted != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 13,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Target: $targetDateFormatted',
                                    style: AppTypography.textTheme.labelSmall?.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ── Current Amount Big Display (marquee if overflow) ────
                  _buildMarqueeAmount(
                    text: fmt.format(_currentAmount),
                    style: AppTypography.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _goalColor,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '${l10n.totalSaved} · ${l10n.of_(fmt.format(_targetAmount))}',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
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

  Widget _buildSavingsIcon() {
    final iconShape = ref.watch(categoryIconShapeProvider);
    return Hero(
      tag: 'savings_icon_$_goalId',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 80,
          height: 80,
          decoration: ShapeDecoration(
            color: _goalColor,
            shape: iconShape.toShapeBorder(80),
            shadows: [
              BoxShadow(
                color: _goalColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(_emoji, style: const TextStyle(fontSize: 36)),
          ),
        ),
      ),
    );
  }

  // ── Info cards row ─────────────────────────────────────────────────────────
  Widget _buildInfoCards(BuildContext context, bool isDark, NumberFormat fmt) {
    final remaining = (_targetAmount - _currentAmount).clamp(0, double.infinity);

    final targetDateStr = _goal['targetDate'] as String?;
    String? dailySaveText;
    if (!_isCompleted && targetDateStr != null && _targetAmount > _currentAmount) {
      try {
        final targetDate = DateTime.parse(targetDateStr).toLocal();
        final now = DateTime.now();
        final diffDays = targetDate.difference(now).inDays;
        final perDayStr = l10n.perDayShort;
        if (diffDays > 0) {
          final dailyAmount = remaining / diffDays;
          dailySaveText = '${fmt.format(dailyAmount)}$perDayStr';
        }
      } catch (_) {}
    }

    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.savings_rounded,
            iconColor: AppColors.success,
            label: l10n.totalSaved,
            valueWidget: _buildMarqueeAmount(
              text: fmt.format(_currentAmount),
              style: AppTypography.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.track_changes_rounded,
            iconColor: AppColors.primary,
            label: l10n.remaining,
            valueWidget: _buildMarqueeAmount(
              text: fmt.format(remaining),
              style: AppTypography.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            isDark: isDark,
          ),
        ),
        if (dailySaveText != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _InfoCard(
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFFF59E0B),
              label: l10n.perDay,
              valueWidget: _buildMarqueeAmount(
                text: dailySaveText,
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }
  // ── Transactions Sliver ─────────────────────────────────────────────────────
  Widget _buildTransactionSliver(
    BuildContext context,
    bool isDark,
    String currencyCode,
    String currencySymbol,
  ) {
    if (_goalId.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              l10n.noTransactionsYet,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      );
    }

    return Consumer(builder: (context, ref, _) {
      final txAsync = ref.watch(savingsGoalTransactionsProvider(_goalId));
      return txAsync.when(
        loading: () => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: SkeletonList(),
          ),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                '${l10n.error}: $e',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          ),
        ),
        data: (transactions) {
          if (transactions.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _goalColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: _goalColor.withValues(alpha: 0.5),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noTransactionsYet,
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.startRecordingTransactions,
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Group by date
          final grouped = _groupByDate(transactions);
          final dateKeys = grouped.keys.toList();

          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final dateKey = dateKeys[index];
                  final dayTxs = grouped[dateKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4, left: 20, right: 20),
                        child: Text(
                          _formatDateHeader(context, dateKey),
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Transactions for this date
                      Column(
                        children: List.generate(dayTxs.length, (i) {
                          final tx = dayTxs[i] as Map<String, dynamic>;
                          return Column(
                            children: [
                              TransactionCard(
                                transaction: tx,
                                showTime: true,
                                hideSavingsGoal: true,
                              ),
                              if (i < dayTxs.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 84,
                                  endIndent: 20,
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                childCount: dateKeys.length,
              ),
            ),
          );
        },
      );
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Map<String, List<dynamic>> _groupByDate(List<dynamic> transactions) {
    final map = <String, List<dynamic>>{};
    for (final tx in transactions) {
      final raw = (tx as Map<String, dynamic>)['date'] as String?;
      String key = 'Unknown';
      if (raw != null) {
        try {
          final date = DateTime.parse(raw).toLocal();
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (_) {}
      }
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  String _formatDateHeader(BuildContext context, String dateKey) {
    final l10n = AppLocalizations.of(context);
    try {
      final date = DateTime.parse(dateKey);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final d = DateTime(date.year, date.month, date.day);
      if (d == today) return l10n.today.toUpperCase();
      if (d == yesterday) return l10n.yesterday.toUpperCase();
      return DateFormat('EEE, d MMM yyyy').format(date).toUpperCase();
    } catch (_) {
      return dateKey;
    }
  }

  Widget _buildMarqueeAmount({required String text, TextStyle? style}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: text, style: style);
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        tp.layout(maxWidth: double.infinity);

        if (tp.width > constraints.maxWidth) {
          return SizedBox(
            height: tp.height,
            child: Marquee(
              text: text,
              style: style,
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              blankSpace: 40.0,
              velocity: 30.0,
              pauseAfterRound: const Duration(seconds: 2),
              startPadding: 0.0,
              accelerationDuration: const Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          );
        } else {
          return Text(text, style: style);
        }
      },
    );
  }

  // ── Floating Title ──────────────────────────────────────────────────────────
  Widget _buildFloatingTitle(BuildContext context, bool isDark, double statusBarH) {
    const appBarH = kToolbarHeight;
    // Hero title Y: Top padding is 56 (inside SafeArea).
    // Plus statusBarH. The container has padding fromLTRB(20, 56, 20, 20).
    final heroTitleY = statusBarH + 56.0;
    
    // AppBar title Y: centered in AppBar
    final appBarTitleY = statusBarH + appBarH / 2.0 - 13.0; // approx center

    final travelDist = heroTitleY - appBarTitleY;
    final t = (_scrollOffset / travelDist.abs()).clamp(0.0, 1.0);
    var currentY = lerpDouble(heroTitleY, appBarTitleY, t)!;

    // Adjust for pull-to-refresh
    if (_scrollOffset < 0) {
      currentY -= _scrollOffset;
    }

    final heroSize = AppTypography.textTheme.headlineSmall?.fontSize ?? 24.0;
    final appBarSize = AppTypography.textTheme.titleLarge?.fontSize ?? 20.0;
    final currentSize = lerpDouble(heroSize, appBarSize, t)!;
    
    // X position interpolation
    // Hero X: left padding 20 + icon width 80 + SizedBox 16 = 116
    const heroTitleX = 116.0;
    // AppBar X: left padding 48 + 16 = 64
    const appBarTitleX = 64.0;
    final currentX = lerpDouble(heroTitleX, appBarTitleX, t)!;

    return Positioned(
      top: currentY,
      left: currentX,
      right: 120.0, // space for edit/delete buttons
      child: IgnorePointer(
        child: Text(
          _name,
          maxLines: t > 0.8 ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: currentSize,
            fontWeight: FontWeight.w800,
            fontFamily: AppTypography.textTheme.headlineSmall?.fontFamily,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}

// ── Info Card ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.valueWidget,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget valueWidget;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          valueWidget,
        ],
      ),
    );
  }
}

// ── Transaction Tile ─────────────────────────────────────────────────────────

// ── Arc Progress Painter ─────────────────────────────────────────────────────

