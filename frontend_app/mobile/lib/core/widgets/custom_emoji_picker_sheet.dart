import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_bottom_sheet.dart';

class CustomEmojiPickerSheet {
  static void show({
    required BuildContext context,
    required Function(String) onEmojiSelected,
  }) {
    AppBottomSheet.show(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return SizedBox(
          height: 350,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Select Emoji',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    onEmojiSelected(emoji.emoji);
                  },
                  config: Config(
                    height: 350,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: Colors.transparent,
                      columns: 7,
                      emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
                    ),
                    skinToneConfig: const SkinToneConfig(),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: Colors.transparent,
                      indicatorColor: AppColors.primary,
                      iconColorSelected: AppColors.primary,
                      iconColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      dividerColor: Colors.transparent,
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      backgroundColor: Colors.transparent,
                      buttonColor: Colors.transparent,
                      buttonIconColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    searchViewConfig: const SearchViewConfig(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
