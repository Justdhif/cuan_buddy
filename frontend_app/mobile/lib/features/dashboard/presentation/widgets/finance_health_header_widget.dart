import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../providers/dashboard_provider.dart';
import 'daily_burn_rate_sheet.dart';


class FinanceHealthHeaderWidget extends ConsumerStatefulWidget {
  const FinanceHealthHeaderWidget({super.key});

  @override
  ConsumerState<FinanceHealthHeaderWidget> createState() =>
      _FinanceHealthHeaderWidgetState();
}

class _FinanceHealthHeaderWidgetState
    extends ConsumerState<FinanceHealthHeaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _activeIndexAnimation;
  double _currentActiveIndex = 6.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateToActiveIndex(double targetIndex) {
    _activeIndexAnimation = Tween<double>(
      begin: _currentActiveIndex,
      end: targetIndex,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.fastOutSlowIn,
    ));

    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        _currentActiveIndex = targetIndex;
      }
    });
  }

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
    final isEn = l10n.languageCode == 'en';
    final msg = message.trim();

    if (msg.isNotEmpty) {
      if (isEn) {
        if (msg.contains('Belum ada data transaksi')) {
          return 'No transaction data for this month.';
        }
        if (msg.contains('Keuangan sangat sehat')) {
          return 'Your finances are looking great!';
        }
        if (msg.contains('Kondisi keuangan stabil')) {
          return 'Financial condition is stable. Keep saving.';
        }
        if (msg.contains('Rasio pengeluaran tinggi')) {
          return 'High expense ratio or budget exceeded.';
        }
      } else {
        if (msg.contains('Your finances are looking great')) {
          return 'Keuangan sangat sehat! Tabungan teralokasi dengan baik.';
        }
        if (msg.contains('No transaction data')) {
          return 'Belum ada data transaksi pada bulan ini.';
        }
        if (msg.contains('exceeded your budget')) {
          return 'Pengeluaranmu melebihi anggaran kategori.';
        }
        if (msg.contains('spending more than you earn')) {
          return 'Pengeluaranmu lebih besar daripada pemasukan.';
        }
        if (msg.contains('savings rate is low')) {
          return 'Rasio tabunganmu rendah. Coba tingkatkan tabungan!';
        }
      }
      return msg;
    }

    final st = status.toLowerCase();
    if (st == 'critical' || st == 'danger' || score < 50) {
      return isEn
          ? 'High expenses or low savings rate detected.'
          : 'Pengeluaran tinggi atau rasio tabungan rendah.';
    } else if (st == 'warning' || (score >= 50 && score < 80)) {
      return isEn
          ? 'Your financial health needs attention.'
          : 'Kondisi keuanganmu butuh perhatian.';
    } else {
      return l10n.financialHealthGoodSubtitle;
    }
  }


  Future<void> _showHealthDetailSheet(
    BuildContext context, {
    required int score,
    required String status,
    required String message,
    required AppLocalizations l10n,
  }) {
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBottomSheet.show(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.languageCode == 'id'
                        ? 'Detail Kesehatan Keuangan'
                        : 'Financial Health Detail',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
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
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
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
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(financialHealthProvider);
    final l10n = AppLocalizations.of(context);

    return healthAsync.when(
      data: (healthData) {
        final score = (healthData['score'] as num? ?? 82).toInt();
        final status = healthData['status'] as String? ?? 'healthy';
        final message = healthData['message'] as String? ?? '';

        final rawHistory = healthData['scoreHistory'] as List?;
        final List<Map<String, dynamic>> historyItems = [];

        if (rawHistory != null && rawHistory.isNotEmpty) {
          for (var item in rawHistory) {
            if (item is Map) {
              historyItems.add({
                'score': (item['score'] as num? ?? 50).toInt(),
                'date': item['date']?.toString() ?? '',
                'status': item['status']?.toString() ?? 'healthy',
                'message': item['message']?.toString() ?? '',
              });
            } else if (item is num) {
              historyItems.add({
                'score': item.toInt(),
                'date': '',
                'status': 'healthy',
                'message': '',
              });
            }
          }
        }

        // Adjust historyItems array to exactly 7 points with the current score at position 7 (index 6)
        if (historyItems.length < 7) {
          while (historyItems.length < 6) {
            historyItems.insert(0, {
              'score': 50,
              'date': '',
              'status': 'healthy',
              'message': '',
            });
          }
          historyItems.add({
            'score': score,
            'date': '',
            'status': status,
            'message': message,
          });
        } else if (historyItems.length > 7) {
          historyItems.removeRange(0, historyItems.length - 7);
          historyItems[6] = {
            'score': score,
            'date': '',
            'status': status,
            'message': message,
          };
        } else {
          historyItems[6] = {
            'score': score,
            'date': '',
            'status': status,
            'message': message,
          };
        }

        final List<int> scores =
            historyItems.map((e) => e['score'] as int).toList();

        final currentMonthIndex = (scores.length - 1).toDouble();
        if (_activeIndexAnimation == null) {
          _currentActiveIndex = currentMonthIndex;
          _activeIndexAnimation = AlwaysStoppedAnimation(_currentActiveIndex);
        }

        // Exact matching title, subtitle, and color for header amount
        final statusColor = _getColorForScore(score, status);
        final statusText = _getStatusTitle(score, status, l10n);
        final statusSubtitle = _getStatusSubtitle(score, status, message, l10n);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _showHealthDetailSheet(
                  context,
                  score: score,
                  status: status,
                  message: message,
                  l10n: l10n,
                );
              },
              child: Row(
                children: [
                  _buildGaugeRing(score, statusColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          statusSubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final width = constraints.maxWidth;
                    final stepX = width / (scores.length - 1);
                    final tapX = details.localPosition.dx;
                    int tappedIndex =
                        (tapX / stepX).round().clamp(0, scores.length - 1);

                    _animateToActiveIndex(tappedIndex.toDouble());

                    final item = historyItems[tappedIndex];
                    String monthStr = item['date']?.toString() ?? '';
                    if (monthStr.isEmpty) {
                      final now = DateTime.now();
                      final monthOffset = (scores.length - 1) - tappedIndex;
                      final targetDate = DateTime(now.year, now.month - monthOffset, 1);
                      monthStr =
                          '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';
                    }

                    DailyBurnRateSheet.show(
                      context,
                      monthYear: monthStr,
                      score: item['score'] as int?,
                      status: item['status'] as String?,
                      message: item['message'] as String?,
                    ).then((_) {

                      if (mounted) {
                        _animateToActiveIndex(currentMonthIndex);
                      }
                    });
                  },

                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _DynamicScoreSparklinePainter(
                            scores: scores,
                            activeIndex: _activeIndexAnimation?.value ?? currentMonthIndex,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => _buildFinanceHealthHeaderSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFinanceHealthHeaderSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.12),
      highlightColor: Colors.white.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeRing(int score, Color statusColor) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(54, 54),
            painter: _GaugePainter(
              progress: (score.clamp(0, 100)) / 100.0,
              color: statusColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
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

class _DynamicScoreSparklinePainter extends CustomPainter {
  final List<int> scores;
  final double activeIndex;

  _DynamicScoreSparklinePainter({
    required this.scores,
    required this.activeIndex,
  });

  Color _getColorForScore(int score) {
    if (score >= 80) {
      return const Color(0xFF34D399); // Green
    } else if (score >= 50) {
      return const Color(0xFFFBBF24); // Yellow/Amber
    } else {
      return const Color(0xFFF87171); // Red
    }
  }

  Offset _computeCubicPoint(
      Offset p0, Offset c1, Offset c2, Offset p1, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    final x =
        uuu * p0.dx + 3 * uu * t * c1.dx + 3 * u * tt * c2.dx + ttt * p1.dx;
    final y =
        uuu * p0.dy + 3 * uu * t * c1.dy + 3 * u * tt * c2.dy + ttt * p1.dy;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final List<Offset> points = [];
    final double stepX = scores.length > 1
        ? size.width / (scores.length - 1)
        : size.width;

    final double halfHeight = size.height * 0.5;
    final double maxAmplitude = halfHeight * 0.84;

    for (int i = 0; i < scores.length; i++) {
      final score = scores[i].clamp(0, 100);
      final deltaScore = score - 50;
      final y = halfHeight - (deltaScore / 50.0) * maxAmplitude;
      final x = (i * stepX).clamp(0.0, size.width);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 1) {
      path.lineTo(size.width, points[0].dy);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }
    }

    final List<Color> colors = [];
    final List<double> stops = [];

    for (int i = 0; i < scores.length; i++) {
      colors.add(_getColorForScore(scores[i]));
      final stop = scores.length > 1 ? (i / (scores.length - 1)) : 0.0;
      stops.add(stop.clamp(0.0, 1.0));
    }

    final shader = ui.Gradient.linear(
      Offset(0, 0),
      Offset(size.width, 0),
      colors,
      stops,
    );

    final linePaint = Paint()
      ..shader = shader
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shadowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, 0),
        colors.map((c) => c.withValues(alpha: 0.35)).toList(),
        stops,
      )
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, linePaint);

    // Compute exact position and color along the cubic spline curve for activeIndex
    final clampedActive =
        activeIndex.clamp(0.0, (points.length - 1).toDouble());
    final floorIdx = clampedActive.floor().clamp(0, points.length - 1);
    final ceilIdx = clampedActive.ceil().clamp(0, points.length - 1);
    final t = clampedActive - floorIdx;

    Offset activePt;
    Color activeColor;

    if (floorIdx == ceilIdx || points.length == 1) {
      activePt = points[floorIdx];
      activeColor = _getColorForScore(scores[floorIdx]);
    } else {
      final p0 = points[floorIdx];
      final p1 = points[ceilIdx];
      final c1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final c2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      activePt = _computeCubicPoint(p0, c1, c2, p1, t);
      final colorFloor = _getColorForScore(scores[floorIdx]);
      final colorCeil = _getColorForScore(scores[ceilIdx]);
      activeColor = Color.lerp(colorFloor, colorCeil, t) ?? colorFloor;
    }

    // Draw vertical guideline for active point
    final verticalGuidePaint = Paint()
      ..color = activeColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double startY = activePt.dy + 8;
    final double endY = size.height;
    double y = startY;
    while (y < endY) {
      canvas.drawLine(
        Offset(activePt.dx, y),
        Offset(activePt.dx, (y + 4).clamp(startY, endY)),
        verticalGuidePaint,
      );
      y += 7;
    }

    // Draw node dots at each point
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final nodeColor = _getColorForScore(scores[i]);

      final glowPaint = Paint()
        ..color = nodeColor.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 4.5, glowPaint);

      final outerDot = Paint()
        ..color = Colors.white.withValues(alpha: 0.80)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 3.0, outerDot);

      final innerDot = Paint()
        ..color = nodeColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 1.8, innerDot);
    }

    // Draw active traveling dot over the spline curve!
    final ambientGlow = Paint()
      ..color = activeColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(activePt, 11.5, ambientGlow);

    final pulseRing = Paint()
      ..color = activeColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(activePt, 8.0, pulseRing);

    final outerWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(activePt, 5.5, outerWhite);

    final innerCore = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(activePt, 3.5, innerCore);
  }

  @override
  bool shouldRepaint(covariant _DynamicScoreSparklinePainter oldDelegate) {
    if (oldDelegate.activeIndex != activeIndex) return true;
    if (oldDelegate.scores.length != scores.length) return true;
    for (int i = 0; i < scores.length; i++) {
      if (oldDelegate.scores[i] != scores[i]) return true;
    }
    return false;
  }
}
