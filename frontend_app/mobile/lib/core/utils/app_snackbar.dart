import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

enum SnackbarType { success, error, warning, info }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    SnackbarType type = SnackbarType.info,
  }) {
    ContentType contentType;
    switch (type) {
      case SnackbarType.success:
        contentType = ContentType.success;
        break;
      case SnackbarType.error:
        contentType = ContentType.failure;
        break;
      case SnackbarType.warning:
        contentType = ContentType.warning;
        break;
      case SnackbarType.info:
        contentType = ContentType.help;
        break;
    }

    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -100 * (1 - value)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: AwesomeSnackbarContent(
                title: title,
                message: message,
                contentType: contentType,
                inMaterialBanner: true, // Optimizes layout for top display
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
