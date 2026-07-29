import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../providers/ai_provider.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  final VoidCallback? onTick;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.speed = const Duration(milliseconds: 16),
    this.onTick,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  int _charCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _charCount = 0;
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (widget.text.isEmpty) return;
    _timer = Timer.periodic(widget.speed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charCount < widget.text.length) {
        setState(() {
          _charCount = (_charCount + 3).clamp(0, widget.text.length);
        });
        widget.onTick?.call();
      } else {
        timer.cancel();
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
    final displayText = widget.text.substring(0, _charCount);
    return Text(
      displayText,
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTemplate(String prompt) {
    ref.read(aiNotifierProvider.notifier).sendMessage(prompt);
  }

  void _handleStartNewChat(BuildContext context, bool isDark) {
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
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    final bool isEmptyConversation = aiState.messages.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/illustrations/ai-illustration.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.smart_toy_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                aiState.currentConversationId != null
                    ? activeConv.title
                    : l10n.cuanBuddyAI,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
      body: Column(
        children: [
          Expanded(
            child: isEmptyConversation
                ? _buildEmptyConversationState(context, isDark, isEnglish)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
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
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight,
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
                      final isLatestAssistantMessage =
                          !isUser && index == aiState.messages.length - 1;

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
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight),
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
                          child: isLatestAssistantMessage
                              ? TypewriterText(
                                  text: displayContent,
                                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white : Colors.black87,
                                    height: 1.5,
                                  ),
                                  onTick: _scrollToBottom,
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
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: l10n.askAboutFinances,
                        hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (text) {
                        if (text.trim().isNotEmpty) {
                          ref
                              .read(aiNotifierProvider.notifier)
                              .sendMessage(text.trim());
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty && !aiState.isLoading) {
                        ref.read(aiNotifierProvider.notifier).sendMessage(text);
                        _controller.clear();
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 24,
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
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

  Widget _buildEmptyConversationState(BuildContext context, bool isDark, bool isEnglish) {
    final questionItems = _getEmptyQuestionItems(isEnglish);
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero AI Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark
                  : AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.primary.withAlpha(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 6),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // AI Illustration Image
                Image.asset(
                  'assets/illustrations/ai-illustration.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.smart_toy_rounded,
                            size: 40, color: AppColors.primary),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text(
                            'Hi, CuanBuddy!',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text('👋', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isEnglish
                            ? 'Ask me anything about your finances. I am ready to provide insights and top advice!'
                            : 'Tanyakan apa saja tentang keuanganmu. Aku siap membantu memberi insight dan saran terbaik!',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
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
          const SizedBox(height: 16),

          // 2. Question Cards List (NO "Pertanyaan Populer" or "Lihat semua" header!)
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
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : Colors.white,
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? item.iconColor.withAlpha(40)
                                : item.iconBgLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.subtitle,
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
