import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class WidgetService {
  static const String androidWidgetName = 'HomeWidgetProvider';

  static Future<void> updateWidgetData({
    required double balance,
    required double income,
    required double expense,
    required String currency,
  }) async {
    final currencySymbol = AppConstants.getCurrencySymbol(currency);
    final fmt = NumberFormat.currency(
        locale: 'en_US', symbol: currencySymbol, decimalDigits: 0);

    await HomeWidget.saveWidgetData<String>('tv_balance', fmt.format(balance));
    await HomeWidget.saveWidgetData<String>('tv_income', fmt.format(income));
    await HomeWidget.saveWidgetData<String>('tv_expense', fmt.format(expense));

    await HomeWidget.updateWidget(androidName: androidWidgetName);
  }
}
