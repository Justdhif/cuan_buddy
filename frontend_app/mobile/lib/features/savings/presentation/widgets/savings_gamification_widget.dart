import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SavingsGamificationWidget extends StatefulWidget {
  final double percentage; // 0.0 to 1.0

  const SavingsGamificationWidget({super.key, required this.percentage});

  @override
  State<SavingsGamificationWidget> createState() => _SavingsGamificationWidgetState();
}

class _SavingsGamificationWidgetState extends State<SavingsGamificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = Tween<double>(begin: 0, end: widget.percentage).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(SavingsGamificationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(begin: _animation.value, end: widget.percentage).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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

  String _getMotivationMsg(double pct) {
    if (pct >= 1.0) return 'Target tercapai! Panen besar! 🎉';
    if (pct >= 0.75) return 'Sedikit lagi! Pohonmu sudah sangat besar! 🌳';
    if (pct >= 0.50) return 'Setengah jalan! Terus sirami tabunganmu! 🪴';
    if (pct >= 0.25) return 'Daunnya mulai tumbuh! Pertahankan! 🌿';
    return 'Bibit mulai ditanam. Yuk rutin menabung! 🌱';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The Track and Emoji
            SizedBox(
              height: 50,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Background Track
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Filled Track
                  FractionallySizedBox(
                    widthFactor: val.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withValues(alpha: 0.5), AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                  ),
                  // Emoji Tracker
                  Align(
                    alignment: Alignment(
                      // Alignment goes from -1.0 to 1.0
                      -1.0 + (val.clamp(0.0, 1.0) * 2.0),
                      0,
                    ),
                    child: Transform.scale(
                      scale: 1.0 + (val * 0.2), // slightly grows as it nears the end
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: Text(
                          _getEmoji(val),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Motivation Text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _getMotivationMsg(widget.percentage), // Use widget.percentage to not flicker during animation
                key: ValueKey<String>(_getMotivationMsg(widget.percentage)),
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}
