import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import '../providers/transaction_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import 'package:intl/intl.dart';

enum AiVoiceState { idle, recording, processing, review }

class AiVoiceSheet extends ConsumerStatefulWidget {
  const AiVoiceSheet({super.key});

  @override
  ConsumerState<AiVoiceSheet> createState() => _AiVoiceSheetState();
}

class _AiVoiceSheetState extends ConsumerState<AiVoiceSheet>
    with SingleTickerProviderStateMixin {
  AiVoiceState _state = AiVoiceState.idle;
  late final AudioRecorder _audioRecorder;
  String? _audioPath;
  late AnimationController _animationController;
  Map<String, dynamic>? _extractedData;
  String? _transcription;
  bool _isSaving = false;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  double _amplitude = 0.0;

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
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    _animationController.dispose();
    _deleteAudioFile();
    super.dispose();
  }

  Future<void> _deleteAudioFile() async {
    try {
      if (_audioPath != null) {
        final file = File(_audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        _audioPath =
            '${dir.path}/voice_transaction_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _audioPath!,
        );

        _amplitudeSubscription?.cancel();
        _amplitudeSubscription = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 50))
            .listen((amp) {
          if (mounted) {
            setState(() {
              // Normal speech amplitude typically ranges from -40 to 0.
              // Adjust normalization so it looks good visually.
              final normalized = (amp.current + 40) / 40;
              _amplitude = normalized.clamp(0.0, 1.0);
            });
          }
        });

        setState(() {
          _state = AiVoiceState.recording;
        });
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(context,
            title: l10n.error,
            message: '${l10n.aiVoiceFailed} $e',
            type: SnackbarType.error);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _amplitudeSubscription?.cancel();
      _amplitude = 0.0;
      final path = await _audioRecorder.stop();
      setState(() {
        _state = AiVoiceState.processing;
      });

      if (path != null) {
        await _processVoice(path);
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(context,
            title: l10n.error,
            message: '${l10n.aiVoiceFailed} $e',
            type: SnackbarType.error);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _processVoice(String path) async {
    final result = await ref
        .read(aiNotifierProvider.notifier)
        .processVoiceTransaction(path);
    await _deleteAudioFile(); // clean up after processing

    if (result != null && result['extracted'] != null) {
      setState(() {
        _extractedData = result['extracted'];
        _transcription = result['transcription'];
        _state = AiVoiceState.review;
      });
    } else {
      if (mounted) {
        final error = ref.read(aiNotifierProvider).error;
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: error ?? l10n.aiVoiceErrorUnclear,
          type: SnackbarType.error,
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (_extractedData == null) return;
    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final payload = {
        'title': _extractedData!['title'] ??
            _extractedData!['note'] ??
            'Voice Transaction',
        'categoryId': _extractedData!['categoryId'],
        'amount': double.parse(_extractedData!['amount'].toString()),
        'currency': _extractedData!['currency'],
        'type': _extractedData!['type'] ?? 'expense',
        'note': _extractedData!['note'],
        'date': DateTime.now().toUtc().toIso8601String(),
      };

      await dio.post('/transactions', data: payload);

      // Invalidate providers
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(recentTransactionsProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: l10n.aiVoiceSuccess,
          type: SnackbarType.success,
        );
        Navigator.pop(context, true); // true indicates successful save
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(context,
            title: l10n.error, message: e.toString(), type: SnackbarType.error);
      }
    }
  }

  Widget _buildRecordingUI() {
    final l10n = AppLocalizations.of(context);
    final isRecording = _state == AiVoiceState.recording;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return GestureDetector(
              onTap: isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 100 + (_amplitude * 20),
                height: 100 + (_amplitude * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording ? AppColors.danger : AppColors.primary,
                  boxShadow: isRecording
                      ? [
                          BoxShadow(
                            color: AppColors.danger
                                .withValues(alpha: 0.3 + (_amplitude * 0.4)),
                            blurRadius: 20 + (_amplitude * 30),
                            spreadRadius: 10 + (_amplitude * 20),
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
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          isRecording ? l10n.aiVoiceListening : l10n.aiVoiceTitle,
          style: AppTypography.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          isRecording ? l10n.aiVoiceTapToStop : l10n.aiVoiceTapToStart,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProcessingUI() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 48),
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 32),
        Text(
          l10n.aiVoiceAnalyzing,
          style: AppTypography.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.aiVoiceExtracting,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildReviewUI() {
    if (_extractedData == null) return const SizedBox();

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final fmtOriginal = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '${_extractedData!['currency']} ',
      decimalDigits: 0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.aiVoiceTitle,
          style: AppTypography.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '"$_transcription"',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: secondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.borderLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            children: [
              _buildReviewRow(l10n.transactionTitle,
                  _extractedData!['title'] ?? _extractedData!['note'] ?? '-'),
              const Divider(height: 24),
              if (_extractedData!['note'] != null &&
                  _extractedData!['note'].toString().trim().isNotEmpty &&
                  _extractedData!['note'] != _extractedData!['title']) ...[
                _buildReviewRow(l10n.noteOptional, _extractedData!['note']),
                const Divider(height: 24),
              ],
              _buildReviewRow(
                  l10n.aiVoiceAmountField,
                  fmtOriginal.format(
                      double.tryParse(_extractedData!['amount'].toString()) ??
                          0)),
              const Divider(height: 24),
              _buildReviewRow(
                  l10n.aiVoiceTypeField,
                  _extractedData!['type'] == 'income'
                      ? l10n.aiVoiceIncome
                      : l10n.aiVoiceExpense,
                  color: _extractedData!['type'] == 'income'
                      ? AppColors.success
                      : AppColors.danger),
              const Divider(height: 24),
              _buildReviewRow(l10n.aiVoiceCategoryField,
                  _extractedData!['category'] ?? 'Uncategorized'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AppButton(
          label: l10n.aiVoiceBack,
          onPressed: () {
            setState(() {
              _state = AiVoiceState.idle;
              _extractedData = null;
              _transcription = null;
            });
          },
          type: AppButtonType.outlined,
        ),
        const SizedBox(height: 12),
        AppButton(
          label: l10n.aiVoiceSave,
          onPressed: _saveTransaction,
          type: AppButtonType.primary,
          isLoading: _isSaving,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_state == AiVoiceState.idle || _state == AiVoiceState.recording)
            _buildRecordingUI(),
          if (_state == AiVoiceState.processing) _buildProcessingUI(),
          if (_state == AiVoiceState.review) _buildReviewUI(),
        ],
      ),
    );
  }
}

Future<bool?> showAiVoiceSheet(BuildContext context) {
  return AppBottomSheet.show<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const AiVoiceSheet(),
  );
}
