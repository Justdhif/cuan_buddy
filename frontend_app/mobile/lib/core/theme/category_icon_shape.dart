enum CategoryIconShape {
  circle,
  square, // Rounded square
  squircle, // Continuous rounded rectangle (like iOS)
}

extension CategoryIconShapeExtension on CategoryIconShape {
  String get displayName {
    switch (this) {
      case CategoryIconShape.circle:
        return 'Circle';
      case CategoryIconShape.square:
        return 'Rounded Square';
      case CategoryIconShape.squircle:
        return 'Squircle';
    }
  }
}
