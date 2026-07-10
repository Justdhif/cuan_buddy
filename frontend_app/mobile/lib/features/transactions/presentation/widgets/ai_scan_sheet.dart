import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

enum AiScanState { idle, processing, review }

class AiScanSheet extends ConsumerStatefulWidget {
  const AiScanSheet({super.key});

  @override
  ConsumerState<AiScanSheet> createState() => _AiScanSheetState();
}

class _AiScanSheetState extends ConsumerState<AiScanSheet> {
  AiScanState _state = AiScanState.idle;
  String? _imagePath;
  Map<String, dynamic>? _extractedData;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source, 
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        setState(() {
          _imagePath = image.path;
          _state = AiScanState.processing;
        });
        await _processImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(context,
            title: l10n.error,
            message: 'Failed to pick image: $e',
            type: SnackbarType.error);
      }
    }
  }

  Future<void> _processImage(String path) async {
    final result = await ref
        .read(aiNotifierProvider.notifier)
        .processReceiptTransaction(path);

    if (result != null && result['extracted'] != null) {
      setState(() {
        _extractedData = result['extracted'];
        _state = AiScanState.review;
      });
    } else {
      if (mounted) {
        final error = ref.read(aiNotifierProvider).error;
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: error ?? 'Failed to extract data from receipt',
          type: SnackbarType.error,
        );
        setState(() {
          _state = AiScanState.idle;
          _imagePath = null;
        });
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
            'Scanned Receipt',
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
          message: 'Transaction saved successfully',
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

  Widget _buildIdleUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.document_scanner, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        Text(
          'Scan Receipt',
          style: AppTypography.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Take a photo or upload a receipt image',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Camera',
                icon: const Icon(Icons.camera_alt),
                onPressed: () => _pickImage(ImageSource.camera),
                type: AppButtonType.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                label: 'Gallery',
                icon: const Icon(Icons.photo_library),
                onPressed: () => _pickImage(ImageSource.gallery),
                type: AppButtonType.outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProcessingUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 48),
        if (_imagePath != null)
          Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: FileImage(File(_imagePath!)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 32),
        Text(
          'Analyzing Receipt...',
          style: AppTypography.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Extracting transaction details',
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
          'Review Transaction',
          style: AppTypography.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_imagePath != null)
          Center(
            child: Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                image: DecorationImage(
                  image: FileImage(File(_imagePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
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
          label: 'Retake',
          onPressed: () {
            setState(() {
              _state = AiScanState.idle;
              _extractedData = null;
              _imagePath = null;
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
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
          if (_state == AiScanState.idle) _buildIdleUI(),
          if (_state == AiScanState.processing) _buildProcessingUI(),
          if (_state == AiScanState.review) _buildReviewUI(),
        ],
      ),
    );
  }
}

Future<bool?> showAiScanSheet(BuildContext context) {
  return AppBottomSheet.show<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const AiScanSheet(),
  );
}
