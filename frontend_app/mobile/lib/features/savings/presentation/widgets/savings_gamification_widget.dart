import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';

class SavingsGamificationWidget extends StatefulWidget {
  final double percentage; // 0.0 to 1.0

  const SavingsGamificationWidget({super.key, required this.percentage});

  @override
  State<SavingsGamificationWidget> createState() =>
      _SavingsGamificationWidgetState();
}

class _SavingsGamificationWidgetState extends State<SavingsGamificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = Tween<double>(begin: 0, end: widget.percentage).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(SavingsGamificationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
              begin: _animation.value, end: widget.percentage)
          .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getEmoji(double pct) {
    if (pct >= 1.0) return '🍎';
    if (pct >= 0.75) return '🌳';
    if (pct >= 0.50) return '🪴';
    if (pct >= 0.25) return '🌿';
    return '🌱';
  }

  String _getMessageForPercentage(double pct, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final emoji = _getEmoji(pct);
    if (pct >= 1.0) return l10n.gamificationLevel5(emoji);
    if (pct >= 0.75) return l10n.gamificationLevel4(emoji);
    if (pct >= 0.50) return l10n.gamificationLevel3(emoji);
    if (pct >= 0.25) return l10n.gamificationLevel2(emoji);
    return l10n.gamificationLevel1(emoji);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        final percentageInt = (val * 100).clamp(0, 100).toInt();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tree Illustration with Fill Effect
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Icon(
                    Icons.park_rounded,
                    color: AppColors.borderLight.withValues(alpha: 0.5),
                    size: 64,
                  ),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: val.clamp(0.0, 1.0),
                      child: const Icon(
                        Icons.park_rounded,
                        color: AppColors.success,
                        size: 64,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Percentage and Motivation Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$percentageInt%',
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _getMessageForPercentage(widget.percentage, context),
                      key: ValueKey<String>(
                          _getMessageForPercentage(widget.percentage, context)),
                      style: AppTypography.textTheme.labelMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
