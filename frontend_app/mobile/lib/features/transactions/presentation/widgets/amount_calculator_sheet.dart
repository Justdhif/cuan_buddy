import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../wallets/providers/wallet_provider.dart';
import '../../../../core/services/currency_service.dart';
import 'package:intl/intl.dart';

class AmountCalculatorSheet extends ConsumerStatefulWidget {
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
  ConsumerState<AmountCalculatorSheet> createState() => _AmountCalculatorSheetState();

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

class _AmountCalculatorSheetState extends ConsumerState<AmountCalculatorSheet> {
  String _expression = '';
  double _result = 0.0;
  double _convertedResult = 0.0;
  String? _pressedKey;

  // Selected wallet for input
  Map<String, dynamic>? _selectedWallet;
  bool _isConverting = false;
  bool _showConverted = false; // Toggle state for display currency

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount > 0) {
      if (widget.initialAmount.truncateToDouble() == widget.initialAmount) {
        _expression = widget.initialAmount.toInt().toString();
      } else {
        _expression = widget.initialAmount.toString().replaceAll('.', ',');
      }
    }
    _evaluateExpression();

    // Auto-select initial wallet/currency after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallets = ref.read(walletsProvider).valueOrNull ?? [];
      if (wallets.isNotEmpty) {
        setState(() {
          _selectedWallet = wallets.firstWhere(
            (w) => w['currency'] == widget.initialCurrency,
            orElse: () => wallets.first,
          );
        });
        _updateConvertedResult();
      }
    });
  }

  void _onKeyPress(String key) {
    setState(() {
      _pressedKey = key;

      if (key == 'C') {
        _expression = '';
        _result = 0.0;
        _convertedResult = 0.0;
        return;
      }

      if (key == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else {
        final isOperator = ['+', '-', '×', '÷'].contains(key);

        if (key == ',') {
          final segments = _expression.split(RegExp(r'[+\-×÷]'));
          final lastSegment = segments.isNotEmpty ? segments.last : '';
          if (lastSegment.contains(',')) return;
          if (_expression.isEmpty || ['+', '-', '×', '÷'].contains(_expression[_expression.length - 1])) {
            _expression += '0,';
          } else {
            _expression += ',';
          }
        } else if (isOperator && _expression.isNotEmpty) {
          final lastChar = _expression[_expression.length - 1];
          if (['+', '-', '×', '÷'].contains(lastChar)) {
            _expression = _expression.substring(0, _expression.length - 1) + key;
          } else if (lastChar == ',') {
            _expression = '${_expression}0$key';
          } else {
            _expression += key;
          }
        } else if (!isOperator) {
          _expression += key;
        }
      }
      _evaluateExpression();
      _updateConvertedResult();
    });

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
      // Keep previous valid result
    }
  }

  Future<void> _updateConvertedResult() async {
    if (_selectedWallet == null) return;
    final txCurrency = _selectedWallet!['currency'] as String? ?? 'IDR';
    final baseCurrency = ref.read(profileProvider).valueOrNull?['currency'] as String? ?? 'IDR';

    if (txCurrency == baseCurrency) {
      if (mounted) {
        setState(() {
          _convertedResult = _result;
          _showConverted = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isConverting = true);
    try {
      final service = ref.read(currencyServiceProvider);
      final converted = await service.convert(_result, txCurrency, baseCurrency);
      if (mounted) {
        setState(() {
          _convertedResult = converted;
          _isConverting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  double _calculateBODMAS(String expr) {
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

    for (int i = 0; i < tokens.length; i++) {
      if (!['+', '-', '×', '÷'].contains(tokens[i])) {
        var t = tokens[i].replaceAll(',', '.');
        if (t.endsWith('.')) t = '${t}0';
        tokens[i] = t;
      }
    }

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

    // Base currency info
    final baseCurrency = ref.watch(profileProvider).valueOrNull?['currency'] as String? ?? 'IDR';
    final baseCurrencySymbol = AppConstants.getCurrencySymbol(baseCurrency);

    // Selected input currency info
    final txCurrency = _selectedWallet?['currency'] as String? ?? 'IDR';
    final txCurrencySymbol = AppConstants.getCurrencySymbol(txCurrency);

    // Precision is taken from selected wallet
    final selectedPrecision = (_selectedWallet?['decimalPrecision'] as num?)?.toInt() ?? widget.decimalPrecision;

    // Display formatted strings
    final displayConverted = CurrencyFormatter.formatAmount(_convertedResult, symbol: baseCurrencySymbol, decimalPrecision: selectedPrecision);
    final displayOriginal = CurrencyFormatter.formatAmount(_result, symbol: txCurrencySymbol, decimalPrecision: selectedPrecision);

    // Wallets for selector
    final walletsAsync = ref.watch(walletsProvider);
    final wallets = walletsAsync.valueOrNull ?? [];

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

        // ── Result Display & Converter ──
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Loading Spinner if converting
                  if (_isConverting)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  // Compact display: Toggles between original amount and converted amount
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        if (_showConverted) {
                          setState(() {
                            _showConverted = false;
                          });
                        }
                      },
                      child: Text(
                        _showConverted ? displayConverted : displayOriginal,
                        style: AppTypography.textTheme.headlineMedium?.copyWith(
                          fontSize: 36, // Smaller size, as requested
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Converter Action Button (only shown if selected wallet currency != base currency AND not currently showing converted)
                  if (txCurrency != baseCurrency && !_showConverted) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showConverted = true;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.currency_exchange_rounded,
                              size: 16,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              baseCurrency,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white60 : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasOperator) ...[
                const SizedBox(height: 8),
                Text(
                  _buildDisplayExpr(),
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Wallet Selector ──
        if (wallets.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: wallets.length + 1,
                itemBuilder: (context, index) {
                  // The last item is the '+' button
                  if (index == wallets.length) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to wallet form sheet to create a new wallet
                          context.push('/manage-wallets/form');
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black12,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    );
                  }

                  final wallet = wallets[index];
                  final isSelected = _selectedWallet?['id'] == wallet['id'];
                  final walletColorHex = wallet['colorCode'] as String? ?? '#6C63FF';
                  final walletColor = AppColors.colorFromHex(walletColorHex, fallback: AppColors.primary);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedWallet = wallet;
                        });
                        _updateConvertedResult();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? walletColor.withValues(alpha: 0.15)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          border: Border.all(
                            color: isSelected ? walletColor : (isDark ? Colors.white10 : Colors.black12),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${wallet['name']}',
                          style: TextStyle(
                            color: isSelected 
                                ? (isDark ? Colors.white : walletColor)
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // ── Numpad ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
              // Save the converted base currency amount & original currency
              widget.onSave(_convertedResult, baseCurrency);
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
