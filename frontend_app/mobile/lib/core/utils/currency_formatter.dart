import 'package:intl/intl.dart';

/// Utility class for formatting currency amounts throughout the app.
///
/// Format: Indonesian style — dot (.) as thousands separator, comma (,) as decimal.
/// Example: 9.000.000,99
///
/// Rules:
/// - [decimalPrecision] controls how many decimal digits are shown **for rounded values**.
/// - For display-only from a raw input string (e.g. calculator), use [formatRawInput]
///   which does NOT pad trailing zeros beyond what the user typed.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format a [double] value with the given [symbol] and [decimalPrecision].
  ///
  /// Always shows exactly [decimalPrecision] decimal places (pads with zeros).
  /// Example: formatAmount(9000.5, symbol: 'Rp', decimalPrecision: 2) → 'Rp 9.000,50'
  static String formatAmount(
    double value, {
    String symbol = '',
    int decimalPrecision = 2,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: symbol.isEmpty ? '' : '$symbol ',
      decimalDigits: decimalPrecision,
    );
    return formatter.format(value).trim();
  }

  /// Format a raw input string from the calculator (e.g. '9000,5') for display.
  ///
  /// Does NOT pad trailing zeros — shows exactly as many decimals as the user typed,
  /// up to [decimalPrecision]. If input exceeds precision, it is NOT rounded (display only).
  ///
  /// Example:
  ///   formatRawInput('9000,5', 2) → '9.000,5'    (1 decimal typed, shown as-is)
  ///   formatRawInput('9000,50', 2) → '9.000,50'   (2 decimals typed)
  ///   formatRawInput('9000', 2) → '9.000'          (no decimal typed)
  static String formatRawInput(String rawInput, int decimalPrecision) {
    // rawInput uses comma as decimal separator (user-facing)
    if (rawInput.isEmpty) return '';

    // Split on comma
    final parts = rawInput.split(',');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : null;

    // Parse integer part for thousands separator
    final intValue = int.tryParse(intPart.isEmpty ? '0' : intPart) ?? 0;
    final intFormatter = NumberFormat('#,##0', 'id');
    final formattedInt = intFormatter.format(intValue);

    if (decPart == null) {
      // No comma typed yet
      return formattedInt;
    } else {
      // Comma was typed — show it along with whatever was typed after (no padding)
      return '$formattedInt,$decPart';
    }
  }

  /// Format a [double] for display using the ID locale, without trailing zeros
  /// beyond what's needed (uses '#,##0.##' pattern).
  ///
  /// Example: 9000.5 → '9.000,5'  |  9000.0 → '9.000'
  static String formatCompact(double value) {
    final formatter = NumberFormat('#,##0.##', 'id');
    return formatter.format(value);
  }
}
