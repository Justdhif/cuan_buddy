import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marquee/marquee.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../ai/presentation/providers/ai_provider.dart';

class AiBudgetInsightCard extends ConsumerWidget {
  const AiBudgetInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(aiBudgetRecommendationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return insightsAsync.when(
      data: (insight) => _buildMarquee(context, insight, isDark),
      loading: () => _buildLoadingState(isDark),
      error: (err, stack) => _buildMarquee(context, '✨ AI Budget: Unable to connect to server.', isDark),
    );
  }

  Widget _buildMarquee(BuildContext context, String insight, bool isDark) {
    // Clean text: Marquee requires a single line, so replace newlines with bullets
    final cleanInsight = insight.replaceAll(RegExp(r'\n+'), '   •   ');
    
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [AppColors.primary.withValues(alpha: 0.15), AppColors.secondary.withValues(alpha: 0.05)]
              : [AppColors.primary.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('✨', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Center(
              child: Marquee(
                text: cleanInsight,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 40.0,
                velocity: 30.0,
                pauseAfterRound: const Duration(seconds: 2),
                startPadding: 10.0,
                accelerationDuration: const Duration(seconds: 1),
                accelerationCurve: Curves.linear,
                decelerationDuration: const Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('✨', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          const Expanded(
            child: Center(
              child: SkeletonCard(height: 16),
            ),
          ),
        ],
      ),
    );
  }
}
