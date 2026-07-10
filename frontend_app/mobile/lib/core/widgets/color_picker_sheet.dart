import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../l10n/app_localizations.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';
import 'app_text_field.dart';

Future<Color?> showCustomColorPicker({
  required BuildContext context,
  required Color initialColor,
}) async {
  final l10n = AppLocalizations.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  Color tempColor = initialColor;
  final hexController = TextEditingController(
    text: tempColor.toARGB32().toRadixString(16).substring(2).toUpperCase(),
  );

  return AppBottomSheet.show<Color>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.customColor,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F3F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tag_rounded,
                      size: 20,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: ColorPicker(
                  pickerColor: tempColor,
                  onColorChanged: (Color color) {
                    setState(() {
                      tempColor = color;
                      // Update hex controller only if user is not currently typing in it
                      // Actually, if we just update it, it might move the cursor, but it's fine for simple use.
                      // To be safe, we only update if it doesn't match the current parsed value.
                      final currentHex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
                      if (hexController.text.toUpperCase() != currentHex) {
                        hexController.text = currentHex;
                      }
                    });
                  },
                  colorPickerWidth: 260,
                  pickerAreaHeightPercent: 1.0,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hueWheel,
                  hexInputBar: false, 
                  labelTypes: const [], // Hide RGB, HSV, HSL labels
                  portraitOnly: true,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: hexController,
                      label: l10n.hexColor,
                      hint: 'FFFFFF',
                      prefixIcon: Icon(Icons.numbers_rounded, color: AppColors.primary),
                      onChanged: (val) {
                        final hexStr = val.replaceAll('#', '');
                        if (hexStr.length == 6) {
                          try {
                            final newColor = Color(int.parse('FF$hexStr', radix: 16));
                            setState(() {
                              tempColor = newColor;
                            });
                          } catch (e) {
                            // ignore parsing error
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: l10n.confirm,
                      onPressed: () => Navigator.pop(ctx, tempColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        );
      },
    ),
  );
}
