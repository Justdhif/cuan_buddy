import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class WidgetService {
  static const String androidWidgetName = 'AppHomeWidgetProvider';

  static Future<void> updateWidgetData({
    required double balance,
    required double income,
    required double expense,
    required String currency,
  }) async {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: currency == AppConstants.defaultCurrency ? 'Rp ' : '$currency ',
      decimalDigits: 0,
    );

    try {
      await HomeWidget.saveWidgetData<String>(
          'balance', formatCurrency.format(balance));
      await HomeWidget.saveWidgetData<String>(
          'income', formatCurrency.format(income));
      await HomeWidget.saveWidgetData<String>(
          'expense', formatCurrency.format(expense));
      await HomeWidget.updateWidget(androidName: androidWidgetName);
    } catch (e) {
      // Ignore widget update errors on platforms that don't support it
    }
  }

  static const String androidSavingsWidgetName = 'SavingsWidgetProvider';

  static Future<void> updateSavingsWidgetData({
    required String emoji,
    required String name,
    required double savedAmount,
    required double targetAmount,
    required String currency,
  }) async {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: currency == AppConstants.defaultCurrency ? 'Rp ' : '$currency ',
      decimalDigits: 0,
    );

    final percent = targetAmount > 0
        ? ((savedAmount / targetAmount) * 100).clamp(0, 100).toInt()
        : 0;
    final progressText =
        '${formatCurrency.format(savedAmount)} / ${formatCurrency.format(targetAmount)}';

    try {
      await HomeWidget.saveWidgetData<String>('savings_emoji', emoji);
      await HomeWidget.saveWidgetData<String>('savings_name', name);
      await HomeWidget.saveWidgetData<String>(
          'savings_progress_text', progressText);
      await HomeWidget.saveWidgetData<String>(
          'savings_percent', percent.toString());
      await HomeWidget.updateWidget(androidName: androidSavingsWidgetName);
    } catch (e) {
      // Ignore widget update errors
    }
  }
}
