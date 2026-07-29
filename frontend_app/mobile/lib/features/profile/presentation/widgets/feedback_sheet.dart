import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../providers/profile_provider.dart';

void showFeedbackSheet(BuildContext context) {
  AppBottomSheet.show(
    context: context,
    builder: (context) => const FeedbackSheetWidget(),
  );
}

class FeedbackSheetWidget extends ConsumerStatefulWidget {
  const FeedbackSheetWidget({super.key});

  @override
  ConsumerState<FeedbackSheetWidget> createState() => _FeedbackSheetWidgetState();
}

class _FeedbackSheetWidgetState extends ConsumerState<FeedbackSheetWidget> {
  final TextEditingController _controller = TextEditingController();
  int _selectedRating = 5;
  String _selectedCategory = 'general';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getDeviceInfo() {
    if (kIsWeb) return 'Web Browser';
    try {
      final osName = defaultTargetPlatform.name.toUpperCase();
      final osVer = Platform.operatingSystemVersion.split(' ').first;
      return '$osName $osVer';
    } catch (_) {
      return defaultTargetPlatform.name;
    }
  }

  String _getRatingLabel(int rating, bool isId) {
    switch (rating) {
      case 1:
        return isId ? '🙁 Sangat Kecewa' : '🙁 Very Poor';
      case 2:
        return isId ? '😐 Kurang Puas' : '😐 Needs Work';
      case 3:
        return isId ? '🙂 Cukup Baik' : '🙂 Okay';
      case 4:
        return isId ? '😊 Sangat Baik' : '😊 Great';
      case 5:
      default:
        return isId ? '😍 Luar Biasa!' : '😍 Excellent!';
    }
  }

  String _getCategoryHint(String category, bool isId) {
    switch (category) {
      case 'bug':
        return isId
            ? 'Jelaskan masalah atau error yang kamu alami...'
            : 'Describe the bug or issue you encountered...';
      case 'feature_request':
        return isId
            ? 'Ceritakan ide atau fitur baru yang kamu inginkan...'
            : 'Tell us about the new feature you would like to see...';
      case 'ui_ux':
        return isId
            ? 'Berikan masukan terkait tampilan atau kenyamanan aplikasi...'
            : 'Give feedback about design, layout, or user experience...';
      case 'question':
        return isId
            ? 'Tuliskan pertanyaan atau kendala penggunaan kamu...'
            : 'Ask a question or request help...';
      case 'general':
      default:
        return isId
            ? 'Tulis saran atau masukan Anda di sini...'
            : 'Write your feedback or suggestions here...';
    }
  }

  Future<void> _submitFeedback() async {
    final message = _controller.text.trim();
    final l10n = AppLocalizations.of(context);

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.feedbackEmptyError),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final deviceInfo = _getDeviceInfo();
      await ref.read(profileRepositoryProvider).submitFeedback(
            message: message,
            category: _selectedCategory,
            rating: _selectedRating,
            deviceInfo: deviceInfo,
            appVersion: AppConstants.appVersion,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.feedbackSentSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isId = l10n.languageCode == 'id';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final deviceInfo = _getDeviceInfo();

    final categories = [
      {'id': 'general', 'label': isId ? '⭐️ Umum' : '⭐️ General'},
      {'id': 'bug', 'label': isId ? '🐛 Bug / Error' : '🐛 Bug Report'},
      {'id': 'feature_request', 'label': isId ? '💡 Fitur Baru' : '💡 Feature Idea'},
      {'id': 'ui_ux', 'label': isId ? '🎨 UI / Tampilan' : '🎨 UI / Design'},
      {'id': 'question', 'label': isId ? '❓ Bantuan' : '❓ Question'},
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title Header ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.feedback_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.sendFeedback,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 1. Star Rating Section ---
            Text(
              isId ? 'Tingkat Kepuasan Anda' : 'Your Rating',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;
                      final isSelected = starNumber <= _selectedRating;
                      return GestureDetector(
                        onTap: _isSubmitting
                            ? null
                            : () => setState(() => _selectedRating = starNumber),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSelected ? Colors.amber : Colors.grey.withValues(alpha: 0.4),
                            size: 28,
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  Text(
                    _getRatingLabel(_selectedRating, isId),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // --- 2. Category Chips Section ---
            Text(
              isId ? 'Kategori Masukan' : 'Feedback Category',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        cat['label']!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white12 : Colors.black12),
                      ),
                      onSelected: _isSubmitting
                          ? null
                          : (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = cat['id']!);
                              }
                            },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // --- 3. Message Input Section ---
            Text(
              isId ? 'Pesan / Masukan' : 'Your Message',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 4,
              enabled: !_isSubmitting,
              style: TextStyle(
                fontSize: 14.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: _getCategoryHint(_selectedCategory, isId),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13.5,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 1.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // --- 4. Auto Device Metadata Info Pill ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phonelink_setup_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isId
                          ? 'Perangkat: $deviceInfo (${AppConstants.appVersion})'
                          : 'Device: $deviceInfo (${AppConstants.appVersion})',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isId ? 'Auto' : 'Auto',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // --- Submit Button ---
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.sendFeedback,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
