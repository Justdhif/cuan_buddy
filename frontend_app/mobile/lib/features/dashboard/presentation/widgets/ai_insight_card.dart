import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';

class AiInsightCard extends ConsumerStatefulWidget {
  const AiInsightCard({super.key});

  @override
  ConsumerState<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends ConsumerState<AiInsightCard> {
  Timer? _timer;
  int _currentSentenceIndex = 0;

  @override
  void initState() {
    super.initState();
    _startSentenceTimer();
  }

  void _startSentenceTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted) {
        setState(() {
          _currentSentenceIndex++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<String> _getSentences(bool isId) {
    if (isId) {
      return [
        'Pengeluaran kamu bulan ini masih dalam batas aman! 👍',
        'Alokasikan sisa dana dingin ke Tabungan Impian kamu 🎯',
        'Tips Cuan: Rutin catat pengeluaran kecil agar arus kas rapi! 💡',
        'Keuangan sehat! Selalu periksa sisa anggaran bulanan kamu 👌',
        'Ingat prinsip 50/30/20 untuk alokasi gaji dan tabungan 📊',
        'Hindari belanja impulsif, evaluasi skala prioritas kebutuhan 🛒',
        'Disiplin finansial hari ini adalah investasi masa depan kamu 🚀',
        'Pantau laporan transaksi harian untuk kontrol pengeluaran 📈',
      ];
    } else {
      return [
        'Your spending this month is well within safe limits! 👍',
        'Consider allocating extra funds to your Savings Goals 🎯',
        'Cuan Tip: Record small expenses daily to keep cashflow clear! 💡',
        'Financial health is looking great! Check your monthly budget 👌',
        'Remember the 50/30/20 rule for budgeting and savings 📊',
        'Avoid impulsive buys; prioritize your essential needs 🛒',
        'Financial discipline today is an investment for tomorrow 🚀',
        'Track daily transactions regularly for smart money moves 📈',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isId = l10n.languageCode == 'id';

    final sentences = _getSentences(isId);
    final sentenceIndex = _currentSentenceIndex % sentences.length;
    final currentSentence = sentences[sentenceIndex];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Mascot Illustration with Overlaid Chat Button
          SizedBox(
            width: 70,
            height: 76,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Direct AI Illustration (No background circle)
                Positioned(
                  top: 0,
                  child: Image.asset(
                    'assets/illustrations/ai-illustration.png',
                    width: 62,
                    height: 62,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.smart_toy_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                ),

                // Button overlaid on bottom of illustration
                Positioned(
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => context.push('/ai-chat'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isId ? 'Tanya AI' : 'Ask AI',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Right: Speech Bubble wrapping the entire AnimatedSwitcher
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.94, end: 1.0)
                          .animate(animation),
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  key: ValueKey<int>(sentenceIndex),
                  onTap: () => context.push('/ai-chat'),
                  child: CustomPaint(
                    painter: _SpeechBubblePainter(
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderColor: AppColors.primary.withValues(alpha: 0.35),
                      isDark: isDark,
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              currentSentence,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
}

class _SpeechBubblePainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final bool isDark;

  _SpeechBubblePainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = 18.0;
    final tailWidth = 10.0;
    final tailHeight = 12.0;
    final tailTop = ((size.height - tailHeight) / 2)
        .clamp(radius, size.height - radius - tailHeight);

    final path = Path();

    // Top edge starting after tail
    path.moveTo(tailWidth + radius, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(Offset(size.width, radius),
        radius: Radius.circular(radius));

    // Right edge
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(Offset(size.width - radius, size.height),
        radius: Radius.circular(radius));

    // Bottom edge
    path.lineTo(tailWidth + radius, size.height);
    path.arcToPoint(Offset(tailWidth, size.height - radius),
        radius: Radius.circular(radius));

    // Left edge up to bottom of tail
    path.lineTo(tailWidth, tailTop + tailHeight);

    // Speech Tail pointing left
    path.lineTo(0, tailTop + (tailHeight / 2));
    path.lineTo(tailWidth, tailTop);

    // Left edge up to top-left corner
    path.lineTo(tailWidth, radius);
    path.arcToPoint(Offset(tailWidth + radius, 0),
        radius: Radius.circular(radius));

    path.close();

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.25 : 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);

    // Fill
    final paintFill = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paintFill);

    // Border
    final paintBorder = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, paintBorder);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isDark != isDark;
  }
}
