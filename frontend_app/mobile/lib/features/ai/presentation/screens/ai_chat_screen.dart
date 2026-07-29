import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/ai_provider.dart';

class AiBackgroundPatternPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;

  AiBackgroundPatternPainter({
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ambient Glow Orbs
    final glowPaint1 = Paint()
      ..color = primaryColor.withAlpha(isDark ? 25 : 35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 140, glowPaint1);

    final glowPaint2 = Paint()
      ..color = const Color(0xFF8B5CF6).withAlpha(isDark ? 20 : 25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.65), 160, glowPaint2);

    // 2. Dot Matrix Pattern Grid
    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : primaryColor).withAlpha(isDark ? 12 : 18)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    // 3. Subtle Tech / Finance Accent Lines
    final linePaint = Paint()
      ..color = (isDark ? Colors.white : primaryColor).withAlpha(isDark ? 8 : 12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double i = -size.height; i < size.width + size.height; i += 120) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AiBackgroundPatternPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.primaryColor != primaryColor;
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback? onTick;
  final VoidCallback? onFinished;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.onTick,
    this.onFinished,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  int _displayLength = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _displayLength = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    if (widget.text.isEmpty) {
      widget.onFinished?.call();
      return;
    }

    final int totalLength = widget.text.length;
    final int step = totalLength > 400 ? 2 : 1;
    final int intervalMs = totalLength > 400 ? 10 : 14;

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_displayLength < totalLength) {
        setState(() {
          _displayLength = (_displayLength + step).clamp(0, totalLength);
        });
        widget.onTick?.call();
      } else {
        timer.cancel();
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final substring = widget.text.substring(0, _displayLength);
    return Text(
      substring,
      style: widget.style,
    );
  }
}

class BouncingDotsIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const BouncingDotsIndicator({
    super.key,
    this.color = const Color(0xFF60A5FA),
    this.size = 8.0,
  });

  @override
  State<BouncingDotsIndicator> createState() => _BouncingDotsIndicatorState();
}

class _BouncingDotsIndicatorState extends State<BouncingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay) % 1.0;
            final offsetY = value >= 0 && value <= 0.5
                ? -6.0 * (1 - (value * 2 - 0.5).abs() * 2)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, offsetY.clamp(-6.0, 0.0)),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class EmptyQuestionItem {
  final IconData icon;
  final Color iconBgLight;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String prompt;

  const EmptyQuestionItem({
    required this.icon,
    required this.iconBgLight,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.prompt,
  });
}

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _newlyArrivedMessageId;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _cleanText(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll('***', '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll(RegExp(r'^#+\s+', multiLine: true), '')
        .trim();
  }

  List<EmptyQuestionItem> _getEmptyQuestionItems(bool isEnglish) {
    if (isEnglish) {
      return const [
        EmptyQuestionItem(
          icon: Icons.bar_chart_rounded,
          iconBgLight: Color(0xFFF3E8FF),
          iconColor: Color(0xFF8B5CF6),
          title: 'How is my financial status this month?',
          subtitle: 'Summary of income, expenses & balance',
          prompt: 'How is my financial status this month?',
        ),
        EmptyQuestionItem(
          icon: Icons.pie_chart_rounded,
          iconBgLight: Color(0xFFCCFBF1),
          iconColor: Color(0xFF14B8A6),
          title: 'Which category ate up most of my money?',
          subtitle: 'See your top spending categories',
          prompt: 'Which category ate up most of my money this month?',
        ),
        EmptyQuestionItem(
          icon: Icons.track_changes_rounded,
          iconBgLight: Color(0xFFFFE4E6),
          iconColor: Color(0xFFF43F5E),
          title: 'Am I on track with my budget this month?',
          subtitle: 'Analysis of budget vs actual spending',
          prompt: 'Am I on track with my budget this month?',
        ),
        EmptyQuestionItem(
          icon: Icons.savings_rounded,
          iconBgLight: Color(0xFFFEF3C7),
          iconColor: Color(0xFFF59E0B),
          title: 'What tips can help me save more money?',
          subtitle: 'Personalized advice based on your habits',
          prompt: 'What tips can help me save more money?',
        ),
        EmptyQuestionItem(
          icon: Icons.calendar_month_rounded,
          iconBgLight: Color(0xFFDBEAFE),
          iconColor: Color(0xFF3B82F6),
          title: 'What is my financial projection till month-end?',
          subtitle: 'Balance prediction based on transactions',
          prompt: 'What is my financial projection till month-end?',
        ),
        EmptyQuestionItem(
          icon: Icons.auto_awesome_rounded,
          iconBgLight: Color(0xFFE0E7FF),
          iconColor: Color(0xFF6366F1),
          title: 'Give me personalized financial advice',
          subtitle: 'General advice for your financial health',
          prompt: 'Give me personalized financial advice',
        ),
      ];
    } else {
      return const [
        EmptyQuestionItem(
          icon: Icons.bar_chart_rounded,
          iconBgLight: Color(0xFFF3E8FF),
          iconColor: Color(0xFF8B5CF6),
          title: 'Bagaimana kondisi keuanganku bulan ini?',
          subtitle: 'Rangkuman pemasukan, pengeluaran & saldo',
          prompt: 'Bagaimana kondisi keuanganku bulan ini?',
        ),
        EmptyQuestionItem(
          icon: Icons.pie_chart_rounded,
          iconBgLight: Color(0xFFCCFBF1),
          iconColor: Color(0xFF14B8A6),
          title: 'Kategori apa yang paling banyak menghabiskan uangku?',
          subtitle: 'Lihat kategori pengeluaran terbesar',
          prompt: 'Kategori apa yang paling banyak menghabiskan uangku bulan ini?',
        ),
        EmptyQuestionItem(
          icon: Icons.track_changes_rounded,
          iconBgLight: Color(0xFFFFE4E6),
          iconColor: Color(0xFFF43F5E),
          title: 'Apakah aku sudah on track dengan budget bulan ini?',
          subtitle: 'Analisis budget vs realisasi pengeluaran',
          prompt: 'Apakah aku sudah on track dengan budget bulan ini?',
        ),
        EmptyQuestionItem(
          icon: Icons.savings_rounded,
          iconBgLight: Color(0xFFFEF3C7),
          iconColor: Color(0xFFF59E0B),
          title: 'Tips apa yang bisa membantuku menabung lebih banyak?',
          subtitle: 'Saran personal sesuai kebiasaanmu',
          prompt: 'Tips apa yang bisa membantuku menabung lebih banyak?',
        ),
        EmptyQuestionItem(
          icon: Icons.calendar_month_rounded,
          iconBgLight: Color(0xFFDBEAFE),
          iconColor: Color(0xFF3B82F6),
          title: 'Berapa proyeksi keuanganku sampai akhir bulan?',
          subtitle: 'Prediksi saldo berdasarkan transaksi',
          prompt: 'Berapa proyeksi keuanganku sampai akhir bulan?',
        ),
        EmptyQuestionItem(
          icon: Icons.auto_awesome_rounded,
          iconBgLight: Color(0xFFE0E7FF),
          iconColor: Color(0xFF6366F1),
          title: 'Beri saran finansial untukku',
          subtitle: 'Saran umum untuk kesehatan keuanganmu',
          prompt: 'Beri saran finansial untukku',
        ),
      ];
    }
  }

  void _scrollToBottomIfNearEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;

        if (maxScroll - currentScroll <= 160) {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  void _sendTemplate(String prompt) {
    ref.read(aiNotifierProvider.notifier).sendMessage(prompt);
  }

  void _handleStartNewChat(BuildContext context, bool isDark) {
    setState(() {
      _newlyArrivedMessageId = null;
    });
    final success = ref.read(aiNotifierProvider.notifier).startNewChat();
    if (!success) {
      _showLimitReachedDialog(context, isDark);
    }
  }

  void _showLimitReachedDialog(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final isEnglish = l10n.languageCode == 'en';
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final aiState = ref.watch(aiNotifierProvider);
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Text(
                      isEnglish ? 'Conversation Limit (10/10)' : 'Batas Percakapan (10/10)',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglish
                          ? 'You have reached the maximum limit of 10 saved conversations. Please delete an old conversation below to create a new one:'
                          : 'Anda telah mencapai batas maksimal 10 percakapan tersimpan. Silakan hapus salah satu percakapan di bawah untuk membuat yang baru:',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: aiState.conversations.length,
                        itemBuilder: (context, index) {
                          final conv = aiState.conversations[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Theme.of(context).scaffoldBackgroundColor
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                conv.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red, size: 20),
                                onPressed: () {
                                  ref
                                      .read(aiNotifierProvider.notifier)
                                      .deleteConversation(conv.id);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEnglish
                                          ? 'Conversation deleted. You can start a new chat now.'
                                          : 'Percakapan dihapus. Silakan buat percakapan baru.'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isEnglish ? 'Close' : 'Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showConversationsSheet(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final isEnglish = l10n.languageCode == 'en';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final aiState = ref.watch(aiNotifierProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.forum_outlined, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              isEnglish ? 'AI Conversation History' : 'Riwayat Percakapan AI',
                              style: AppTypography.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: aiState.conversations.length >= 10
                                ? Colors.red.withAlpha(20)
                                : AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${aiState.conversations.length}/10',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: aiState.conversations.length >= 10
                                  ? Colors.red
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleStartNewChat(context, isDark);
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: Text(isEnglish ? 'New Conversation' : 'Percakapan Baru'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (aiState.conversations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            isEnglish ? 'No saved conversations yet.' : 'Belum ada percakapan tersimpan.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: aiState.conversations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final conv = aiState.conversations[index];
                            final isSelected =
                                conv.id == aiState.currentConversationId;

                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withAlpha(20)
                                    : (isDark
                                        ? Theme.of(context).scaffoldBackgroundColor
                                        : AppColors.surfaceLight),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight),
                                ),
                              ),
                              child: ListTile(
                                onTap: () {
                                  setState(() {
                                    _newlyArrivedMessageId = null;
                                  });
                                  ref
                                      .read(aiNotifierProvider.notifier)
                                      .selectConversation(conv.id);
                                  Navigator.pop(context);
                                },
                                leading: Icon(
                                  isSelected
                                      ? Icons.chat_bubble_rounded
                                      : Icons.chat_bubble_outline_rounded,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey,
                                ),
                                title: Text(
                                  conv.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  _formatDate(conv.updatedAt),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18),
                                      onPressed: () => _showRenameDialog(
                                          context, conv.id, conv.title, isDark),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red),
                                      onPressed: () => _showDeleteConfirmDialog(
                                          context, conv.id, conv.title),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRenameDialog(
      BuildContext context, String convId, String oldTitle, bool isDark) {
    final textController = TextEditingController(text: oldTitle);
    final l10n = AppLocalizations.of(context);
    final isEnglish = l10n.languageCode == 'en';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          title: Text(isEnglish ? 'Edit Conversation Title' : 'Edit Judul Percakapan'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: isEnglish ? 'Enter new title...' : 'Masukkan judul baru...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isEnglish ? 'Cancel' : 'Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newTitle = textController.text.trim();
                if (newTitle.isNotEmpty) {
                  ref
                      .read(aiNotifierProvider.notifier)
                      .renameConversation(convId, newTitle);
                  Navigator.pop(context);
                }
              },
              child: Text(isEnglish ? 'Save' : 'Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, String convId, String title) {
    final l10n = AppLocalizations.of(context);
    final isEnglish = l10n.languageCode == 'en';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEnglish ? 'Delete Conversation?' : 'Hapus Percakapan?'),
          content: Text(isEnglish
              ? 'Are you sure you want to delete "$title"?'
              : 'Yakin ingin menghapus percakapan "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isEnglish ? 'Cancel' : 'Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref
                    .read(aiNotifierProvider.notifier)
                    .deleteConversation(convId);
                Navigator.pop(context);
              },
              child: Text(isEnglish ? 'Delete' : 'Hapus', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEnglish = l10n.languageCode == 'en';
    final aiState = ref.watch(aiNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeConv = aiState.conversations.firstWhere(
      (c) => c.id == aiState.currentConversationId,
      orElse: () => AiConversation(
        id: '',
        title: l10n.cuanBuddyAI,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    ref.listen(aiNotifierProvider, (prev, next) {
      final bool conversationChanged = prev?.currentConversationId != next.currentConversationId;

      if (conversationChanged) {
        if (_newlyArrivedMessageId != null) {
          setState(() {
            _newlyArrivedMessageId = null;
          });
        }
        return;
      }

      // Detect when a NEW response finishes loading from AI within the SAME active conversation
      if (prev?.isLoading == true &&
          next.isLoading == false &&
          prev?.messages.length != null &&
          next.messages.length > prev!.messages.length) {
        if (next.messages.isNotEmpty && next.messages.last.role == 'assistant') {
          final lastMsg = next.messages.last;
          final msgKey = lastMsg.id ?? '${lastMsg.content.hashCode}_${next.messages.length - 1}';
          setState(() {
            _newlyArrivedMessageId = msgKey;
          });
        }
      }

      if (prev?.messages.length != next.messages.length) {
        _scrollToBottomIfNearEnd();
      }
    });

    final bool isEmptyConversation = aiState.messages.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          aiState.currentConversationId != null
              ? activeConv.title
              : l10n.cuanBuddyAI,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: AppColors.primary),
            tooltip: isEnglish ? 'Conversation History' : 'Riwayat Percakapan',
            onPressed: () => _showConversationsSheet(context, isDark),
          ),
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: isEnglish ? 'New Conversation' : 'Percakapan Baru',
            onPressed: () => _handleStartNewChat(context, isDark),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Background Tech/Finance Pattern Painter
          Positioned.fill(
            child: CustomPaint(
              painter: AiBackgroundPatternPainter(
                isDark: isDark,
                primaryColor: AppColors.primary,
              ),
            ),
          ),

          // 2. Full-height Scrollable Content (spans underneath the floating input bar)
          Positioned.fill(
            child: isEmptyConversation
                ? _buildEmptyConversationState(context, isDark, isEnglish)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 16, bottom: 130),
                    itemCount: aiState.messages.length + (aiState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Render animated 3-dot bouncing typing bubble for AI loading state
                      if (aiState.isLoading && index == aiState.messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark.withAlpha(220)
                                  : AppColors.surfaceLight.withAlpha(230),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(16),
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: BouncingDotsIndicator(
                              color: AppColors.primary,
                              size: 8.0,
                            ),
                          ),
                        );
                      }

                      final msg = aiState.messages[index];
                      final isUser = msg.role == 'user';
                      final displayContent = _cleanText(msg.content);
                      final msgKey = msg.id ?? '${msg.content.hashCode}_$index';
                      final bool isNewlyArrivedAssistantMsg =
                          !isUser &&
                          index == aiState.messages.length - 1 &&
                          _newlyArrivedMessageId == msgKey;

                      return Align(
                        alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.surfaceDark.withAlpha(220)
                                    : AppColors.surfaceLight.withAlpha(230)),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                          ),
                          child: isNewlyArrivedAssistantMsg
                              ? TypewriterText(
                                  text: displayContent,
                                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white : Colors.black87,
                                    height: 1.5,
                                  ),
                                  onTick: _scrollToBottomIfNearEnd,
                                  onFinished: () {
                                    if (_newlyArrivedMessageId == msgKey) {
                                      setState(() {
                                        _newlyArrivedMessageId = null;
                                      });
                                    }
                                  },
                                )
                              : Text(
                                  displayContent,
                                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                                    color: isUser
                                        ? Colors.white
                                        : (isDark ? Colors.white : Colors.black87),
                                    height: 1.5,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),

          // 3. Floating Glassmorphism Input Bar at Bottom (100% Transparent Wrapper)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFloatingInputBar(context, isDark, isEnglish, l10n, aiState),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingInputBar(
    BuildContext context,
    bool isDark,
    bool isEnglish,
    AppLocalizations l10n,
    AiState aiState,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2A38).withAlpha(160)
                    : Colors.white.withAlpha(190),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(40)
                      : Colors.white.withAlpha(160),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 35 : 10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 1. Multi-line Scrollable Text Field (Expandable 1 to 5 lines with hidden scrollbar)
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 140, // Max height (~5 lines) before internal scrolling
                      ),
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 5,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.askAboutFinances,
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Send Button Anchored at Bottom Right
                  GestureDetector(
                    onTap: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty && !aiState.isLoading) {
                        ref.read(aiNotifierProvider.notifier).sendMessage(text);
                        _controller.clear();
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeBasedGreeting(String userName, bool isEnglish) {
    final hour = DateTime.now().hour;
    final name = userName.trim().isNotEmpty ? userName.trim() : 'CuanBuddy';
    if (isEnglish) {
      if (hour >= 4 && hour < 12) {
        return 'Good morning, $name.';
      } else if (hour >= 12 && hour < 17) {
        return 'Good afternoon, $name.';
      } else if (hour >= 17 && hour < 21) {
        return 'Good evening, $name.';
      } else {
        return 'Good night, $name.';
      }
    } else {
      if (hour >= 4 && hour < 11) {
        return 'Selamat pagi, $name.';
      } else if (hour >= 11 && hour < 15) {
        return 'Selamat siang, $name.';
      } else if (hour >= 15 && hour < 18) {
        return 'Selamat sore, $name.';
      } else {
        return 'Selamat malam, $name.';
      }
    }
  }

  Widget _buildEmptyConversationState(BuildContext context, bool isDark, bool isEnglish) {
    final questionItems = _getEmptyQuestionItems(isEnglish);
    final profileAsync = ref.watch(profileProvider);
    final profileData = profileAsync.value;
    final userName = (profileData?['fullName'] ?? profileData?['name'] ?? profileData?['username'] ?? '').toString();
    final greetingText = _getTimeBasedGreeting(userName, isEnglish);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 36),

          // 1. Centered AI Illustration (enlarged)
          Center(
            child: Image.asset(
              'assets/illustrations/ai-illustration.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.smart_toy_rounded,
                        size: 56, color: AppColors.primary),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2. Centered Time-Based Greeting ("Selamat siang, DhiF.")
          Text(
            greetingText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 32),

          // 3. Question Cards List (Clean open design)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questionItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = questionItems[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _sendTemplate(item.prompt),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark.withAlpha(230)
                          : Colors.white.withAlpha(240),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 15 : 6),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon Box
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? item.iconColor.withAlpha(40)
                                : item.iconBgLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text Title
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
