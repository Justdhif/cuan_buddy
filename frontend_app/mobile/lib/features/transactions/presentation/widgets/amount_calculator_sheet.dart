import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import 'package:intl/intl.dart';

class AmountCalculatorSheet extends StatefulWidget {
  const AmountCalculatorSheet({
    super.key,
    required this.initialAmount,
    required this.initialCurrency,
    required this.onSave,
  });

  final double initialAmount;
  final String initialCurrency;
  final void Function(double amount, String currency) onSave;

  @override
  State<AmountCalculatorSheet> createState() => _AmountCalculatorSheetState();

  static void show(
    BuildContext context, {
    required double initialAmount,
    required String initialCurrency,
    required void Function(double amount, String currency) onSave,
  }) {
    AppBottomSheet.show(
      context: context,
      builder: (_) => AmountCalculatorSheet(
        initialAmount: initialAmount,
        initialCurrency: initialCurrency,
        onSave: onSave,
      ),
    );
  }
}

class _AmountCalculatorSheetState extends State<AmountCalculatorSheet> {
  late String _currency;
  String _expression = '';
  double _result = 0.0;

  @override
  void initState() {
    super.initState();
    _currency = widget.initialCurrency;
    _expression = widget.initialAmount > 0 
        ? widget.initialAmount.truncateToDouble() == widget.initialAmount 
            ? widget.initialAmount.toInt().toString() 
            : widget.initialAmount.toString()
        : '';
    _evaluateExpression();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _expression = '';
        _result = 0.0;
        return;
      }

      if (key == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else {
        // Prevent multiple operators in a row
        final isOperator = ['+', '-', '×', '÷'].contains(key);
        if (isOperator && _expression.isNotEmpty) {
          final lastChar = _expression[_expression.length - 1];
          if (['+', '-', '×', '÷'].contains(lastChar)) {
            _expression = _expression.substring(0, _expression.length - 1) + key;
          } else {
            _expression += key;
          }
        } else {
          _expression += key;
        }
      }
      _evaluateExpression();
    });
  }

  void _evaluateExpression() {
    if (_expression.isEmpty) {
      _result = 0.0;
      return;
    }
    try {
      _result = _calculateBODMAS(_expression);
    } catch (_) {
      // If incomplete expression, just ignore or keep previous valid result
    }
  }

  double _calculateBODMAS(String expr) {
    // Basic BODMAS evaluator without parentheses
    // 1. Tokenize
    final tokens = <String>[];
    String currentNumber = '';
    for (int i = 0; i < expr.length; i++) {
      final char = expr[i];
      if (['+', '-', '×', '÷'].contains(char)) {
        if (currentNumber.isNotEmpty) {
          tokens.add(currentNumber);
          currentNumber = '';
        }
        tokens.add(char);
      } else {
        currentNumber += char;
      }
    }
    if (currentNumber.isNotEmpty) {
      tokens.add(currentNumber);
    }

    // Replace commas with dots for parsing if any
    for (int i = 0; i < tokens.length; i++) {
      if (!['+', '-', '×', '÷'].contains(tokens[i])) {
        tokens[i] = tokens[i].replaceAll(',', '.');
      }
    }

    // 2. Evaluate × and ÷
    var tempTokens = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token == '×' || token == '÷') {
        if (tempTokens.isEmpty || i == tokens.length - 1) continue; // Invalid state
        final left = double.tryParse(tempTokens.removeLast()) ?? 0.0;
        final right = double.tryParse(tokens[i + 1]) ?? 0.0;
        double res = token == '×' ? left * right : (right != 0 ? left / right : 0);
        tempTokens.add(res.toString());
        i++; // Skip next number
      } else {
        tempTokens.add(token);
      }
    }

    // 3. Evaluate + and -
    double finalResult = double.tryParse(tempTokens.isNotEmpty ? tempTokens[0] : '0') ?? 0.0;
    for (int i = 1; i < tempTokens.length; i += 2) {
      final op = tempTokens[i];
      if (i + 1 >= tempTokens.length) break;
      final right = double.tryParse(tempTokens[i + 1]) ?? 0.0;
      if (op == '+') finalResult += right;
      else if (op == '-') finalResult -= right;
    }

    return finalResult;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    // Formatters
    final displayFormatter = NumberFormat('#,##0.##', 'id');
    final resultFormatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);

    // Format expression for display (add thousand separators to numbers)
    String displayExpr = '';
    String currentNum = '';
    for (int i = 0; i < _expression.length; i++) {
      final char = _expression[i];
      if (['+', '-', '×', '÷'].contains(char)) {
        if (currentNum.isNotEmpty) {
          final val = double.tryParse(currentNum.replaceAll(',', '.'));
          displayExpr += val != null ? displayFormatter.format(val) : currentNum;
          currentNum = '';
        }
        displayExpr += ' $char ';
      } else {
        currentNum += char;
      }
    }
    if (currentNum.isNotEmpty) {
      final val = double.tryParse(currentNum.replaceAll(',', '.'));
      displayExpr += val != null ? displayFormatter.format(val) : currentNum;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top section: Expression & Result
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Expression
              Text(
                displayExpr.isEmpty ? '0' : displayExpr,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 8),
              // Currency and Result Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Currency Dropdown
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currency,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      items: AppConstants.supportedCurrencies.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['code'],
                          child: Text('${c['symbol']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _currency = val);
                        }
                      },
                    ),
                  ),
                  // Live Result
                  Expanded(
                    child: Text(
                      resultFormatter.format(_result),
                      style: AppTypography.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Numpad Grid
        Container(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildNumpadRow(['1', '2', '3', '÷'], isDark),
              const SizedBox(height: 12),
              _buildNumpadRow(['4', '5', '6', '×'], isDark),
              const SizedBox(height: 12),
              _buildNumpadRow(['7', '8', '9', '-'], isDark),
              const SizedBox(height: 12),
              _buildNumpadRow([',', '0', '⌫', '+'], isDark),
            ],
          ),
        ),
        // Save Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () {
              widget.onSave(_result, _currency);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(
              'Atur jumlah', // Set amount
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> keys, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onKeyPress(key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: key == '⌫'
                      ? Icon(Icons.backspace_outlined, 
                          color: isDark ? Colors.white70 : Colors.black87)
                      : Text(
                          key,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: ['÷', '×', '-', '+'].contains(key) 
                                ? FontWeight.w400 
                                : FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
