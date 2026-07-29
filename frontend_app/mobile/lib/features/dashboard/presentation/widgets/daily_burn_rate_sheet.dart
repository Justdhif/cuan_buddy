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

  const DailyBurnRateSheet({
    super.key,
    required this.monthYear,
  });

  static Future<void> show(BuildContext context, {required String monthYear}) {
    return AppBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (context) => DailyBurnRateSheet(monthYear: monthYear),
    );
  }

  @override
  ConsumerState<DailyBurnRateSheet> createState() => _DailyBurnRateSheetState();
}

class _DailyBurnRateSheetState extends ConsumerState<DailyBurnRateSheet> {
  int? _selectedDayIndex;

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
                      l10n.languageCode == 'id'
                          ? 'Analisis Cash Flow & Burn Rate'
                          : 'Cash Flow & Burn Rate',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Periode: ${widget.monthYear}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
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
                  'Gagal memuat data: ${err.toString()}',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily Safe Spend Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFF6366F1),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.languageCode == 'id'
                          ? 'Batas Pengeluaran Harian Aman'
                          : 'Safe Daily Spending Limit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$safeLimitFormatted / hari',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF4338CA),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sisa $remainingDays hari • Total Terpakai: $totalExpenseFormatted (Budget: $totalBudgetFormatted)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Line Chart Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.languageCode == 'id'
                  ? 'Tren Pengeluaran Harian Kumulatif'
                  : 'Cumulative Daily Spending Line',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            if (_selectedDayIndex != null && _selectedDayIndex! < days.length)
              Text(
                'Tgl ${days[_selectedDayIndex!]['day']}: ${days[_selectedDayIndex!]['cumulativeExpenseFormatted']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
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
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          child: days.isEmpty
              ? const Center(child: Text('Tidak ada data transaksi'))
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
            Container(width: 12, height: 3, color: const Color(0xFF6366F1)),
            const SizedBox(width: 6),
            Text('Actual Cumulative',
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(width: 16),
            Container(width: 12, height: 3, color: Colors.amber),
            const SizedBox(width: 6),
            Text('Ideal Budget Pace',
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
          ],
        ),
        const SizedBox(height: 24),

        // Peak Spending Heatmap Section
        Text(
          l10n.languageCode == 'id'
              ? 'Heatmap Hari Tersering Belanja (Peak Days)'
              : 'Peak Spending Days Heatmap',
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
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: peakSpendingDays.map((item) {
                    final dayName = item['dayName']?.toString().substring(0, 3) ?? '';
                    final percentage = (item['percentage'] as num? ?? 0).toInt();
                    final isPeak = percentage > 20;

                    return Column(
                      children: [
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPeak
                                ? const Color(0xFFEF4444)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 28,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: (percentage / 100).clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isPeak
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
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
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            weekendVsWeekday['insight'].toString(),
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.3,
                              color: isDark ? Colors.white70 : Colors.black87,
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
      ..color = const Color(0xFF6366F1)
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
        ..color = const Color(0xFF6366F1)
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
