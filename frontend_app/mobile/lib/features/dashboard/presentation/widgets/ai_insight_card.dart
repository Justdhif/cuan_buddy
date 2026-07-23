import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import '../providers/dashboard_provider.dart';

class AiInsightCard extends ConsumerWidget {
  const AiInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(financialHealthProvider);
    final insightsAsync = ref.watch(aiInsightsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Left Card: Finance Health Score ─────────────────────────────
          Expanded(
            child: _buildHealthCard(context, healthAsync, isDark, l10n),
          ),
          const SizedBox(width: 12),
          // ─── Right Card: AI Insight ──────────────────────────────────────
          Expanded(
            child: _buildAiCard(context, insightsAsync, isDark, l10n),
          ),
        ],
      ),
    );
  }

  // ─── Health Score Card ──────────────────────────────────────────────────────
  Widget _buildHealthCard(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> healthAsync,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return healthAsync.when(
      data: (healthData) {
        final score = (healthData['score'] as num? ?? 82).toInt();
        final status = healthData['status'] as String? ?? 'healthy';

        Color statusColor;
        String statusText;
        switch (status) {
          case 'warning':
            statusColor = AppColors.warning;
            statusText = 'Warning!';
            break;
          case 'critical':
          case 'danger':
            statusColor = AppColors.danger;
            statusText = 'Critical!';
            break;
          default:
            statusColor = AppColors.success;
            statusText = l10n.financialHealthGood;
        }

        return _buildGlassContainer(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.financeHealthScore,
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showHealthInfoBottomSheet(context, l10n),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Circular Gauge + Status Text
              Row(
                children: [
                  _buildGaugeRing(score, statusColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.financialHealthGoodSubtitle,
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 10,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Sparkline graph
              SizedBox(
                height: 24,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SparklinePainter(color: statusColor),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildHealthCardSkeleton(isDark),
      error: (_, __) => _buildGlassContainer(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.financeHealthScore,
                style: AppTypography.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(l10n.error, style: const TextStyle(color: AppColors.danger)),
          ],
        ),
      ),
    );
  }

  // ─── AI Insight Card ────────────────────────────────────────────────────────
  Widget _buildAiCard(
    BuildContext context,
    AsyncValue<String> insightsAsync,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (insightsAsync.isLoading && !insightsAsync.hasValue) {
      return _buildAiCardSkeleton(isDark);
    }

    final rawInsight = insightsAsync.valueOrNull ?? '';
    final shortInsight = _shortenInsightText(rawInsight, l10n);

    return _buildGlassContainer(
      isDark: isDark,
      onTap: () => context.push('/ai-chat'),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ─── Layer 2 (Middle Background Watermark): Large AI Illustration ─────
          Positioned(
            right: -10,
            bottom: -12,
            child: Opacity(
              opacity: isDark ? 0.32 : 0.42,
              child: _build3DRobotMascot(size: 130),
            ),
          ),

          // ─── Layer 3 (Front Layer): Content & Text Controls ───────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header without emoji
              Text(
                l10n.aiInsight,
                style: AppTypography.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              // Short Insight text
              Text(
                shortInsight,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 11,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Glass Action Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.askAiChatbot,
                        style: AppTypography.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 16,
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

  // ─── Glassmorphism Box Wrapper ──────────────────────────────────────────────
  Widget _buildGlassContainer({
    required Widget child,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    Widget box = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.6)
                  : AppColors.borderLight.withValues(alpha: 0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: box);
    }
    return box;
  }

  // ─── Circular Gauge Ring ────────────────────────────────────────────────────
  Widget _buildGaugeRing(int score, Color statusColor) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(58, 58),
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
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const Text(
                '/100',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 3D Glass Robot Mascot Asset ───────────────────────────────────────────
  Widget _build3DRobotMascot({double size = 80}) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/illustrations/ai-illustration.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.smart_toy_rounded,
            size: size * 0.8,
            color: AppColors.primary.withValues(alpha: 0.6),
          );
        },
      ),
    );
  }

  // ─── Shorten AI Insight Text ────────────────────────────────────────────────
  String _shortenInsightText(String rawText, AppLocalizations l10n) {
    if (rawText.isEmpty ||
        rawText.contains('Unable to connect') ||
        rawText.contains('failed')) {
      return l10n.aiInsightBannerSubtitle;
    }
    final cleaned = rawText
        .replaceAll(RegExp(r'[\*\#\_•\n]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final sentences = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.isNotEmpty) {
      final firstSentence = sentences.first;
      if (firstSentence.length > 85) {
        return '${firstSentence.substring(0, 82)}...';
      }
      return firstSentence;
    }
    return cleaned.length > 85 ? '${cleaned.substring(0, 82)}...' : cleaned;
  }

  // ─── Bottom Sheet for Score Info ────────────────────────────────────────────
  void _showHealthInfoBottomSheet(
      BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety_outlined,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  l10n.financeHealthScore,
                  style: AppTypography.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.languageCode == 'id'
                  ? 'Skor Kesehatan Keuangan dihitung secara otomatis berdasarkan rasio tabungan bulanan, pengeluaran vs pemasukan, dan kepatuhan anggaran kamu.'
                  : 'Finance Health Score is calculated automatically based on your monthly savings ratio, expense vs income ratio, and budget adherence.',
              style: AppTypography.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCardSkeleton(bool isDark) {
    return _buildGlassContainer(
      isDark: isDark,
      child: Shimmer.fromColors(
        baseColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0),
        highlightColor: isDark
            ? Colors.white.withValues(alpha: 0.2)
            : const Color(0xFFF8FAFC),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 60,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiCardSkeleton(bool isDark) {
    return _buildGlassContainer(
      isDark: isDark,
      child: Shimmer.fromColors(
        baseColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0),
        highlightColor: isDark
            ? Colors.white.withValues(alpha: 0.2)
            : const Color(0xFFF8FAFC),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 75,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 70,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom Gauge Arc Painter ─────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.25 * 3.14159,
      1.5 * 3.14159,
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.25 * 3.14159,
      1.5 * 3.14159 * progress.clamp(0.05, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ─── Custom Sparkline Painter ────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.35, size.height * 0.4),
      Offset(size.width * 0.5, size.height * 0.6),
      Offset(size.width * 0.7, size.height * 0.5),
      Offset(size.width * 0.85, size.height * 0.55),
      Offset(size.width - 2, size.height * 0.2),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(points.last, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
