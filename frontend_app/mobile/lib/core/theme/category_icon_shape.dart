import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CategoryIconShape {
  circle,
  square,
  hexagon,
  diamond,
  sharp,
  squircle,
}

extension CategoryIconShapeExtension on CategoryIconShape {
  String get displayName {
    switch (this) {
      case CategoryIconShape.circle:
        return 'Circle';
      case CategoryIconShape.square:
        return 'Rounded Square';
      case CategoryIconShape.hexagon:
        return 'Hexagon';
      case CategoryIconShape.diamond:
        return 'Diamond';
      case CategoryIconShape.sharp:
        return 'Sharp Square';
      case CategoryIconShape.squircle:
        return 'Squircle';
    }
  }

  ShapeBorder toShapeBorder(double size) {
    switch (this) {
      case CategoryIconShape.circle:
        return const CircleBorder();
      case CategoryIconShape.square:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size * 0.25),
        );
      case CategoryIconShape.hexagon:
        return _HexagonBorder();
      case CategoryIconShape.diamond:
        return _DiamondBorder();
      case CategoryIconShape.sharp:
        return const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        );
      case CategoryIconShape.squircle:
        return ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(size * 0.4),
        );
    }
  }
}

class _HexagonBorder extends ShapeBorder {
  const _HexagonBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _hexPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _hexPath(rect);

  Path _hexPath(Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = math.min(rect.width, rect.height) / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 6 + (math.pi / 3) * i;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class _DiamondBorder extends ShapeBorder {
  const _DiamondBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _diamondPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _diamondPath(rect);

  Path _diamondPath(Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final hw = rect.width / 2;
    final hh = rect.height / 2;
    return Path()
      ..moveTo(cx, cy - hh)
      ..lineTo(cx + hw, cy)
      ..lineTo(cx, cy + hh)
      ..lineTo(cx - hw, cy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
