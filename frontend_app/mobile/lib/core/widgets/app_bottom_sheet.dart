import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBottomSheet {
  /// Displays a custom bottom sheet with a seamless top bump containing a close button.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent, // We draw our own background
      elevation: 0, // Disable default shadow since we use custom shape
      builder: (context) {
        return _AppBottomSheetWrapper(
          child: builder(context),
        );
      },
    );
  }
}

class _AppBottomSheetWrapper extends StatelessWidget {
  final Widget child;
  const _AppBottomSheetWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 32.0),
            width: double.infinity,
            child: child,
          ),
          Container(
            margin: const EdgeInsets.only(top: 12.0),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }
}
