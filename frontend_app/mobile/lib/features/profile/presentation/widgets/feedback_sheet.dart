import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/category_icon_shape.dart';
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

  String _getCategoryHint(String category, AppLocalizations l10n) {
    switch (category) {
      case 'bug':
        return l10n.hintBug;
      case 'feature_request':
        return l10n.hintFeatureRequest;
      case 'ui_ux':
        return l10n.hintUiUx;
      case 'question':
        return l10n.hintQuestion;
      case 'general':
      default:
        return l10n.feedbackMessageHint;
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

  Widget _buildRatingCard({
    required int rating,
    required String label,
    required Color color,
    required String emoji,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _isSubmitting ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              height: 62,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: isDark ? 0.18 : 0.08)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.05)),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isSelected ? 1.18 : 1.0,
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 32,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : color)
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required String id,
    required String name,
    required String emoji,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required CategoryIconShape iconShape,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 70,
      child: GestureDetector(
        onTap: _isSubmitting ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: isSelected
                        ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                        : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9)),
                    shape: iconShape.toShapeBorder(56),
                    shadows: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : color)
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final deviceInfo = _getDeviceInfo();
    final iconShape = ref.watch(categoryIconShapeProvider);

    final categories = [
      {
        'id': 'general',
        'name': l10n.categoryGeneral,
        'emoji': '⭐️',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'id': 'bug',
        'name': l10n.categoryBug,
        'emoji': '🐛',
        'color': const Color(0xFFEF4444),
      },
      {
        'id': 'feature_request',
        'name': l10n.categoryFeatureRequest,
        'emoji': '💡',
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 'ui_ux',
        'name': l10n.categoryUiUx,
        'emoji': '🎨',
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 'question',
        'name': l10n.categoryQuestion,
        'emoji': '❓',
        'color': const Color(0xFF10B981),
      },
    ];

    final ratingCards = [
      {
        'rating': 1,
        'label': l10n.ratingVeryPoor,
        'color': const Color(0xFFEF4444),
        'emoji': '😡',
      },
      {
        'rating': 2,
        'label': l10n.ratingPoor,
        'color': const Color(0xFFF97316),
        'emoji': '🙁',
      },
      {
        'rating': 3,
        'label': l10n.ratingAverage,
        'color': const Color(0xFFF59E0B),
        'emoji': '😐',
      },
      {
        'rating': 4,
        'label': l10n.ratingGood,
        'color': const Color(0xFF10B981),
        'emoji': '😊',
      },
      {
        'rating': 5,
        'label': l10n.ratingVeryGood,
        'color': const Color(0xFF8B5CF6),
        'emoji': '😍',
      },
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
            const SizedBox(height: 18),

            // --- 1. Rating Cards (Pure Emojis) ---
            Text(
              l10n.yourRating,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ratingCards.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final rating = item['rating'] as int;
                final label = item['label'] as String;
                final color = item['color'] as Color;
                final emoji = item['emoji'] as String;
                final isSelected = _selectedRating == rating;

                return Row(
                  children: [
                    if (idx > 0) const SizedBox(width: 6),
                    _buildRatingCard(
                      rating: rating,
                      label: label,
                      color: color,
                      emoji: emoji,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedRating = rating),
                    ),
                  ],
                );
              }).map((e) => Expanded(child: e)).toList(),
            ),
            const SizedBox(height: 22),

            // --- 2. Category Section (Budget Form Design Style with Icon Shape) ---
            Text(
              l10n.feedbackCategory,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categories.map((cat) {
                  final catId = cat['id'] as String;
                  final catName = cat['name'] as String;
                  final catEmoji = cat['emoji'] as String;
                  final catColor = cat['color'] as Color;
                  final isSelected = _selectedCategory == catId;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildCategoryTile(
                      id: catId,
                      name: catName,
                      emoji: catEmoji,
                      color: catColor,
                      isSelected: isSelected,
                      isDark: isDark,
                      iconShape: iconShape,
                      onTap: () => setState(() => _selectedCategory = catId),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. Message Input Section ---
            Text(
              l10n.yourMessage,
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
                hintText: _getCategoryHint(_selectedCategory, l10n),
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
                      'Device: $deviceInfo (${AppConstants.appVersion})',
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
                      'Auto',
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
