import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

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

  static String formatRawInput(String rawInput, int decimalPrecision) {

    if (rawInput.isEmpty) return '';

    final parts = rawInput.split(',');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : null;

    final intValue = int.tryParse(intPart.isEmpty ? '0' : intPart) ?? 0;
    final intFormatter = NumberFormat('#,##0', 'id');
    final formattedInt = intFormatter.format(intValue);

    if (decPart == null) {

      return formattedInt;
    } else {

      return '$formattedInt,$decPart';
    }
  }

  static String formatCompact(double value) {
    final formatter = NumberFormat('#,##0.##', 'id');
    return formatter.format(value);
  }
}
