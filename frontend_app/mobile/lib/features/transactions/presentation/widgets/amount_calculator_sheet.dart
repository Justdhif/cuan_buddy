import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class AmountCalculatorSheet extends StatefulWidget {
  const AmountCalculatorSheet({
    super.key,
    required this.initialAmount,
    required this.initialCurrency,
    required this.onSave,
    this.title,
    this.description,
    this.decimalPrecision = 2,
  });

  final double initialAmount;
  final String initialCurrency;
  final void Function(double amount, String currency) onSave;
  final String? title;
  final String? description;
  final int decimalPrecision;

  @override
  State<AmountCalculatorSheet> createState() => _AmountCalculatorSheetState();

  static void show(
    BuildContext context, {
    required double initialAmount,
    required String initialCurrency,
    required void Function(double amount, String currency) onSave,
    String? title,
    String? description,
    int decimalPrecision = 2,
  }) {
    AppBottomSheet.show(
      context: context,
      builder: (_) => AmountCalculatorSheet(
        initialAmount: initialAmount,
        initialCurrency: initialCurrency,
        onSave: onSave,
        title: title,
        description: description,
        decimalPrecision: decimalPrecision,
      ),
    );
  }
}

class _AmountCalculatorSheetState extends State<AmountCalculatorSheet> {
  late String _currency;
  String _expression = '';
  double _result = 0.0;
  String? _pressedKey;

  @override
  void initState() {
    super.initState();
    _currency = widget.initialCurrency;
    if (widget.initialAmount > 0) {
      // Convert initial double to comma-based expression string
      if (widget.initialAmount.truncateToDouble() == widget.initialAmount) {
        _expression = widget.initialAmount.toInt().toString();
      } else {
        _expression = widget.initialAmount.toString().replaceAll('.', ',');
      }
    }
    _evaluateExpression();
  }

  void _onKeyPress(String key) {
    setState(() {
      _pressedKey = key;

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
        final isOperator = ['+', '-', '×', '÷'].contains(key);

        if (key == ',') {
          // Prevent duplicate comma in the current number segment
          final segments = _expression.split(RegExp(r'[+\-×÷]'));
          final lastSegment = segments.isNotEmpty ? segments.last : '';
          if (lastSegment.contains(',')) return;
          // Start with 0, if expression is empty or last char is operator
          if (_expression.isEmpty || ['+', '-', '×', '÷'].contains(_expression[_expression.length - 1])) {
            _expression += '0,';
          } else {
            _expression += ',';
          }
        } else if (isOperator && _expression.isNotEmpty) {
          final lastChar = _expression[_expression.length - 1];
          if (['+', '-', '×', '÷'].contains(lastChar)) {
            // Replace trailing operator
            _expression = _expression.substring(0, _expression.length - 1) + key;
          } else if (lastChar == ',') {
            // Close trailing comma before adding operator
            _expression = '${_expression}0$key';
          } else {
            _expression += key;
          }
        } else if (!isOperator) {
          _expression += key;
        }
        // Don't allow starting expression with an operator
      }
      _evaluateExpression();
    });

    // Clear pressed state after a short delay for visual feedback
    Future.delayed(const Duration(milliseconds: 130), () {
      if (mounted) setState(() => _pressedKey = null);
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
      // Keep previous valid result on incomplete expression
    }
  }

  double _calculateBODMAS(String expr) {
    // 1. Tokenize by operators
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

    // 2. Convert comma to dot for parsing; handle trailing comma (e.g. "1,") → "1.0"
    for (int i = 0; i < tokens.length; i++) {
      if (!['+', '-', '×', '÷'].contains(tokens[i])) {
        var t = tokens[i].replaceAll(',', '.');
        if (t.endsWith('.')) t = '${t}0';
        tokens[i] = t;
      }
    }

    // 3. Evaluate × and ÷ first (BODMAS)
    var tempTokens = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token == '×' || token == '÷') {
        if (tempTokens.isEmpty || i == tokens.length - 1) continue;
        final left = double.tryParse(tempTokens.removeLast()) ?? 0.0;
        final right = double.tryParse(tokens[i + 1]) ?? 0.0;
        final res = token == '×' ? left * right : (right != 0 ? left / right : 0);
        tempTokens.add(res.toString());
        i++;
      } else {
        tempTokens.add(token);
      }
    }

    // 4. Evaluate + and -
    double finalResult = double.tryParse(tempTokens.isNotEmpty ? tempTokens[0] : '0') ?? 0.0;
    for (int i = 1; i < tempTokens.length; i += 2) {
      final op = tempTokens[i];
      if (i + 1 >= tempTokens.length) break;
      final right = double.tryParse(tempTokens[i + 1]) ?? 0.0;
      if (op == '+') {
        finalResult += right;
      } else if (op == '-') {
        finalResult -= right;
      }
    }

    return finalResult;
  }

  /// Main display for the large result number.
  ///
  /// - No operator → format raw input (preserve trailing comma, don't pad zeros)
  /// - Has operator → show calculated result rounded to [decimalPrecision], no trailing zeros
  String _getDisplayResult() {
    if (_expression.isEmpty) return '0';

    final hasOperator = _expression.contains(RegExp(r'[+\-×÷]'));
    if (!hasOperator) {
      return CurrencyFormatter.formatRawInput(_expression, widget.decimalPrecision);
    }

    // Calculated result: up to decimalPrecision digits, no trailing zeros
    if (widget.decimalPrecision == 0) {
      return NumberFormat('#,##0', 'id').format(_result);
    }
    final pattern = '#,##0.${'#' * widget.decimalPrecision}';
    return NumberFormat(pattern, 'id').format(_result);
  }

  /// Format expression string for the small secondary display (below the main number).
  String _buildDisplayExpr() {
    final compactFmt = NumberFormat('#,##0.##', 'id');
    String displayExpr = '';
    String currentNum = '';

    for (int i = 0; i < _expression.length; i++) {
      final char = _expression[i];
      if (['+', '-', '×', '÷'].contains(char)) {
        if (currentNum.isNotEmpty) {
          displayExpr += _formatNumToken(currentNum, compactFmt);
          currentNum = '';
        }
        displayExpr += ' $char ';
      } else {
        currentNum += char;
      }
    }
    if (currentNum.isNotEmpty) {
      displayExpr += _formatNumToken(currentNum, compactFmt);
    }
    return displayExpr;
  }

  String _formatNumToken(String token, NumberFormat fmt) {
    final hasTrailingComma = token.endsWith(',');
    final cleanToken = token.replaceAll(',', '.');
    final parseStr = cleanToken.endsWith('.') ? '${cleanToken}0' : cleanToken;
    final val = double.tryParse(parseStr);
    if (val == null) return token;
    final formatted = fmt.format(val);
    return hasTrailingComma ? '$formatted,' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final displayTitle = widget.title ?? l10n.amount;
    final displayDesc = widget.description ??
        (l10n.languageCode == 'id'
            ? 'Masukkan nominal jumlah transaksi'
            : 'Enter transaction nominal amount');

    final hasOperator = _expression.contains(RegExp(r'[+\-×÷]'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayTitle,
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayDesc,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),

        // ── Result Display ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getDisplayResult(),
                style: AppTypography.textTheme.headlineMedium?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasOperator) ...[
                const SizedBox(height: 4),
                Text(
                  _buildDisplayExpr(),
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Numpad ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A3349) : const Color(0xFFE8ECF2),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildNumpadRow(['1', '2', '3', '÷'], isDark),
                _buildNumpadRow(['4', '5', '6', '×'], isDark),
                _buildNumpadRow(['7', '8', '9', '-'], isDark),
                _buildNumpadRow([',', '0', '⌫', '+'], isDark),
              ],
            ),
          ),
        ),

        // ── Save Button ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
              l10n.walletDecimalSetAmount,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> keys, bool isDark) {
    return Row(
      children: keys.map((key) {
        final isPressed = _pressedKey == key;
        final isOperator = ['+', '-', '×', '÷'].contains(key);
        return Expanded(
          child: GestureDetector(
            onTap: () => _onKeyPress(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              height: 64,
              decoration: BoxDecoration(
                color: isPressed
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.10))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: AnimatedScale(
                  scale: isPressed ? 0.85 : 1.0,
                  duration: const Duration(milliseconds: 80),
                  child: key == '⌫'
                      ? Icon(
                          Icons.backspace_outlined,
                          size: 24,
                          color: isDark ? Colors.white : Colors.black87,
                        )
                      : Text(
                          key,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: isOperator
                                ? FontWeight.w300
                                : FontWeight.w400,
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
