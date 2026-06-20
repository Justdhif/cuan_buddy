import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ai/presentation/providers/ai_provider.dart';

class AiVoiceButton extends ConsumerStatefulWidget {
  final VoidCallback onTransactionAdded;
  const AiVoiceButton({super.key, required this.onTransactionAdded});

  @override
  ConsumerState<AiVoiceButton> createState() => _AiVoiceButtonState();
}

class _AiVoiceButtonState extends ConsumerState<AiVoiceButton> with SingleTickerProviderStateMixin {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _audioPath;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        _audioPath = '${dir.path}/voice_transaction_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _audioPath!,
        );
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting record: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        _processVoice(path);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _processVoice(String path) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'AI is analyzing your voice...',
                style: AppTypography.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    final result = await ref.read(aiNotifierProvider.notifier).processVoiceTransaction(path);
    
    // Hide loading
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Delete temporary file
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    if (result != null && result['transaction'] != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Transaction added: ${result['extracted']['note']}'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onTransactionAdded();
      }
    } else {
      if (mounted) {
        final error = ref.read(aiNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to process voice transaction.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? AppColors.danger : AppColors.primary,
              boxShadow: _isRecording
                  ? [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.5 * _animationController.value),
                        blurRadius: 20 * _animationController.value,
                        spreadRadius: 10 * _animationController.value,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 32,
            ),
          );
        },
      ),
    );
  }
}
