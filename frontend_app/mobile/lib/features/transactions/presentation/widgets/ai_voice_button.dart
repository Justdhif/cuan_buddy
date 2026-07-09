import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'ai_voice_sheet.dart';

class AiVoiceButton extends ConsumerStatefulWidget {
  final VoidCallback onTransactionAdded;
  const AiVoiceButton({super.key, required this.onTransactionAdded});

  @override
  ConsumerState<AiVoiceButton> createState() => _AiVoiceButtonState();
}

class _AiVoiceButtonState extends ConsumerState<AiVoiceButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showAiVoiceSheet(context);
        if (result == true) {
          widget.onTransactionAdded();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
