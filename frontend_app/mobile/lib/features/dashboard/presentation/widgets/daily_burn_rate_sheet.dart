import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../providers/dashboard_provider.dart';

class DailyBurnRateSheet extends ConsumerStatefulWidget {
  final String monthYear;
  final int? score;
  final String? status;
  final String? message;

  const DailyBurnRateSheet({
    super.key,
    required this.monthYear,
    this.score,
    this.status,
    this.message,
  });

  static Future<void> show(
    BuildContext context, {
    required String monthYear,
    int? score,
    String? status,
    String? message,
  }) {
    return AppBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (context) => DailyBurnRateSheet(
        monthYear: monthYear,
        score: score,
        status: status,
        message: message,
      ),
    );
  }

  @override
  ConsumerState<DailyBurnRateSheet> createState() => _DailyBurnRateSheetState();
}

class _DailyBurnRateSheetState extends ConsumerState<DailyBurnRateSheet> {
  int? _selectedDayIndex;

  Color _getColorForScore(int score, String status) {
    final st = status.toLowerCase();
    if (st == 'critical' || st == 'danger' || score < 50) {
      return const Color(0xFFF87171); // Red
    } else if (st == 'warning' || (score >= 50 && score < 80)) {
      return const Color(0xFFFBBF24); // Yellow/Amber
    } else {
      return const Color(0xFF34D399); // Green
    }
  }

  String _getStatusTitle(int score, String status, AppLocalizations l10n) {
    final st = status.toLowerCase();
    if (st == 'critical' || st == 'danger' || score < 50) {
      return 'Critical!';
    } else if (st == 'warning' || (score >= 50 && score < 80)) {
      return 'Warning!';
    } else {
      return l10n.financialHealthGood;
    }
  }

  String _getStatusSubtitle(
      int score, String status, String message, AppLocalizations l10n) {
    if (message.trim().isNotEmpty) {
      return message;
    }
    final st = status.toLowerCase();
    if (st == 'critical' || st == 'danger' || score < 50) {
      return l10n.languageCode == 'id'
          ? 'Pengeluaran tinggi atau rasio tabungan rendah.'
          : 'High expenses or low savings rate detected.';
    } else if (st == 'warning' || (score >= 50 && score < 80)) {
      return l10n.languageCode == 'id'
          ? 'Kondisi keuanganmu butuh perhatian.'
          : 'Your financial health needs attention.';
    } else {
      return l10n.financialHealthGoodSubtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final burnRateAsync = ref.watch(dailyBurnRateFamilyProvider(widget.monthYear));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.financialDetailAndBurnRate,
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.languageCode == 'id' ? 'Periode' : 'Period'}: ${widget.monthYear}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            burnRateAsync.when(
              loading: () => _buildShimmerLoading(isDark),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Error: ${err.toString()}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (data) => _buildContent(context, data, isDark, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(BuildContext context, bool isDark, AppLocalizations l10n) {
    final score = widget.score ?? 80;
    final status = widget.status ?? 'healthy';
    final message = widget.message ?? '';

    final statusColor = _getColorForScore(score, status);
    final statusTitle = _getStatusTitle(score, status, l10n);
    final statusSubtitle = _getStatusSubtitle(score, status, message, l10n);

    IconData statusIcon;
    final st = status.toLowerCase();
    if (st == 'critical' || st == 'danger' || score < 50) {
      statusIcon = Icons.error_outline_rounded;
    } else if (st == 'warning' || (score >= 50 && score < 80)) {
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusIcon = Icons.sentiment_very_satisfied_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(60, 60),
                  painter: _GaugePainter(
                    progress: score.clamp(0, 100) / 100.0,
                    color: statusColor,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      statusTitle,
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  statusSubtitle,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> data,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final safeLimitFormatted =
        data['remainingSafeLimitFormatted']?.toString() ??
            data['dailySafeLimitFormatted']?.toString() ??
            'Rp 0';
    final totalExpenseFormatted = data['totalExpenseFormatted']?.toString() ?? 'Rp 0';
    final totalBudgetFormatted = data['totalBudgetFormatted']?.toString() ?? 'Rp 0';
    final remainingDays = data['remainingDays'] ?? data['totalDays'] ?? 30;

    final days = (data['days'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final peakSpendingDays = (data['peakSpendingDays'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final weekendVsWeekday =
        Map<String, dynamic>.from(data['weekendVsWeekday'] as Map? ?? {});

    final cardBgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Financial Health Score Card (if score provided)
        if (widget.score != null) _buildHealthCard(context, isDark, l10n),

        // 2. Daily Safe Spend Card (Standard Sheet Card Styling)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.safeDailySpendingLimit,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$safeLimitFormatted ${l10n.perDayShort}',
                      style: TextStyle(

                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.remainingDaysText(remainingDays as int)} • ${l10n.totalUsedText(totalExpenseFormatted, totalBudgetFormatted)}',
                      style: TextStyle(
                        fontSize: 11,
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
        const SizedBox(height: 20),

        // 3. Line Chart Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.cumulativeDailySpendingLine,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            if (_selectedDayIndex != null && _selectedDayIndex! < days.length)
              Text(
                '${l10n.languageCode == 'id' ? 'Tgl' : 'Day'} ${days[_selectedDayIndex!]['day']}: ${days[_selectedDayIndex!]['cumulativeExpenseFormatted']}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Line Chart Canvas
        Container(
          height: 180,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor),
          ),
          child: days.isEmpty
              ? Center(
                  child: Text(
                    l10n.noTransactionDataPeriod,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final stepX = constraints.maxWidth / (days.length - 1);
                        final tapped = (details.localPosition.dx / stepX)
                            .round()
                            .clamp(0, days.length - 1);
                        setState(() {
                          _selectedDayIndex = tapped;
                        });
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _BurnRateLineChartPainter(
                          days: days,
                          selectedIndex: _selectedDayIndex,
                          isDark: isDark,
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 12, height: 3, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              l10n.actualCumulativeLabel,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 16),
            Container(width: 12, height: 3, color: Colors.amber),
            const SizedBox(width: 6),
            Text(
              l10n.idealBudgetPaceLabel,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 4. Peak Spending Heatmap Section
        Text(
          l10n.peakSpendingDaysHeatmap,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),

        if (peakSpendingDays.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: peakSpendingDays.map((item) {
                    final rawName = item['dayName']?.toString() ?? '';
                    final percentage = (item['percentage'] as num? ?? 0).toInt();
                    final isPeak = percentage > 20;

                    // Localize day name substring if needed
                    String localizedDayName = rawName.length > 3 ? rawName.substring(0, 3) : rawName;
                    if (l10n.languageCode == 'en') {
                      const dayMap = {
                        'Senin': 'Mon',
                        'Selasa': 'Tue',
                        'Rabu': 'Wed',
                        'Kamis': 'Thu',
                        'Jumat': 'Fri',
                        'Sabtu': 'Sat',
                        'Minggu': 'Sun',
                      };
                      localizedDayName = dayMap[rawName] ?? localizedDayName;
                    }

                    return Column(
                      children: [
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPeak
                                ? const Color(0xFFEF4444)
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 28,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: (percentage / 100).clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isPeak
                                    ? const Color(0xFFEF4444)
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          localizedDayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                if (weekendVsWeekday['insight'] != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            weekendVsWeekday['insight'].toString(),
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.3,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.28318 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _BurnRateLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> days;
  final int? selectedIndex;
  final bool isDark;

  _BurnRateLineChartPainter({
    required this.days,
    required this.selectedIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (days.length < 2) return;

    double maxVal = 1.0;
    for (var d in days) {
      final cum = (d['cumulativeExpense'] as num? ?? 0).toDouble();
      final ideal = (d['idealCumulativeSpend'] as num? ?? 0).toDouble();
      if (cum > maxVal) maxVal = cum;
      if (ideal > maxVal) maxVal = ideal;
    }

    final stepX = size.width / (days.length - 1);

    // 1. Draw Ideal Budget Pace Line (Dashed)
    final idealPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Path idealPath = Path();
    for (int i = 0; i < days.length; i++) {
      final ideal = (days[i]['idealCumulativeSpend'] as num? ?? 0).toDouble();
      final x = i * stepX;
      final y = size.height - ((ideal / maxVal) * size.height);
      if (i == 0) {
        idealPath.moveTo(x, y);
      } else {
        idealPath.lineTo(x, y);
      }
    }
    canvas.drawPath(idealPath, idealPaint);

    // 2. Draw Actual Cumulative Expense Line
    final actualPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final Path actualPath = Path();
    final List<Offset> points = [];

    for (int i = 0; i < days.length; i++) {
      final cum = (days[i]['cumulativeExpense'] as num? ?? 0).toDouble();
      final x = i * stepX;
      final y = size.height - ((cum / maxVal) * size.height);
      points.add(Offset(x, y));

      if (i == 0) {
        actualPath.moveTo(x, y);
      } else {
        actualPath.lineTo(x, y);
      }
    }
    canvas.drawPath(actualPath, actualPaint);

    // 3. Highlight Selected Day Index
    if (selectedIndex != null && selectedIndex! < points.length) {
      final pt = points[selectedIndex!];
      final highlightPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final ringPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawLine(
        Offset(pt.dx, 0),
        Offset(pt.dx, size.height),
        Paint()
          ..color = (isDark ? Colors.white24 : Colors.black12)
          ..strokeWidth = 1,
      );

      canvas.drawCircle(pt, 6, highlightPaint);
      canvas.drawCircle(pt, 6, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurnRateLineChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.days != days ||
        oldDelegate.isDark != isDark;
  }
}
