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
    final bumpRadius = 24.0;

    return Stack(
      children: [
        // Main sheet background with the seamless bump
        ClipPath(
          clipper: _SheetBumpClipper(bumpRadius: bumpRadius),
          child: Container(
            color: bgColor,
            padding: EdgeInsets.only(top: bumpRadius + 24), // Extra padding to push content safely below the bump
            width: double.infinity,
            child: child,
          ),
        ),
        
        // The floating close button positioned perfectly inside the bump
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: bumpRadius * 2,
              height: bumpRadius * 2,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetBumpClipper extends CustomClipper<Path> {
  final double bumpRadius;
  _SheetBumpClipper({required this.bumpRadius});

  @override
  Path getClip(Size size) {
    final path = Path();
    final double bumpHeight = bumpRadius;
    final double radius = 32.0; // corner radius of the sheet

    // Start at top-left, just below the bump height
    path.moveTo(0, bumpHeight + radius);
    path.quadraticBezierTo(0, bumpHeight, radius, bumpHeight);

    // Draw straight line to start of the bump curve
    final double center = size.width / 2;
    final double curveWidth = bumpRadius * 1.8; // Width of the smooth transition

    path.lineTo(center - curveWidth, bumpHeight);
    
    // Smooth bezier curve for the bump
    // Using two cubic beziers to create a smooth hill shape
    path.cubicTo(
      center - curveWidth / 2, bumpHeight,
      center - bumpRadius, 0,
      center, 0,
    );
    path.cubicTo(
      center + bumpRadius, 0,
      center + curveWidth / 2, bumpHeight,
      center + curveWidth, bumpHeight,
    );

    // Continue to top-right
    path.lineTo(size.width - radius, bumpHeight);
    path.quadraticBezierTo(size.width, bumpHeight, size.width, bumpHeight + radius);

    // Bottom right
    path.lineTo(size.width, size.height);
    // Bottom left
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
