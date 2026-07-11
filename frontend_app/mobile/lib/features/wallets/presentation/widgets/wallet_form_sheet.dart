import '../../../../core/widgets/custom_emoji_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/widgets/color_picker_sheet.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../transactions/presentation/widgets/amount_calculator_sheet.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../providers/wallet_provider.dart';

class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({
    super.key,
    this.initialWallet,
  });

  final Map<String, dynamic>? initialWallet;

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _emojiController;
  late String _typeValue;
  late String _currencyValue;
  late bool _isBaseCurrency;
  late int _decimalPrecision;
  bool _isLoading = false;

  final List<Color> _presetColors = [
    const Color(0xFF6C63FF),
    const Color(0xFF66BB6A),
    const Color(0xFF26A69A),
    const Color(0xFF26C6DA),
    const Color(0xFF42A5F5),
    const Color(0xFF7E57C2),
  ];

  late Color _selectedColor;

  Color _colorFromHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return _presetColors.first;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialWallet?['name']);
    _balanceController = TextEditingController(
        text: widget.initialWallet?['balance']?.toString() ?? '0');
    _balanceController.addListener(_onBalanceChanged);
    _emojiController =
        TextEditingController(text: widget.initialWallet?['emojiIcon'] ?? '💼');
    _typeValue = widget.initialWallet?['type'] ?? 'cash';
    _currencyValue =
        widget.initialWallet?['currency'] ?? AppConstants.defaultCurrency;
    _isBaseCurrency = widget.initialWallet?['isBaseCurrency'] == true;
    _decimalPrecision =
        (widget.initialWallet?['decimalPrecision'] as num?)?.toInt() ?? 2;
    _selectedColor =
        _colorFromHex(widget.initialWallet?['colorCode'] as String?);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.removeListener(_onBalanceChanged);
    _balanceController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _onBalanceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final currency = _currencyValue;
    final balanceText = _balanceController.text.trim();
    final emoji = _emojiController.text.trim();
    final colorCode = _colorToHex(_selectedColor);

    if (name.isEmpty ||
        currency.isEmpty ||
        balanceText.isEmpty ||
        emoji.isEmpty) {
      AppSnackbar.show(
        context,
        title: l10n.info,
        message: l10n.pleaseFillAllFields,
        type: SnackbarType.warning,
      );
      return;
    }

    final balance = double.tryParse(balanceText) ?? 0.0;
    setState(() => _isLoading = true);

    final notifier = ref.read(walletsProvider.notifier);
    String? error;

    if (widget.initialWallet == null) {
      error = await notifier.createWallet({
        'name': name,
        'type': _typeValue,
        'currency': currency,
        'isBaseCurrency': _isBaseCurrency,
        'decimalPrecision': _decimalPrecision,
        'balance': balance,
        'emojiIcon': emoji,
        'colorCode': colorCode,
      });
    } else {
      error = await notifier.updateWallet(widget.initialWallet!['id'], {
        'name': name,
        'type': _typeValue,
        'currency': currency,
        'isBaseCurrency': _isBaseCurrency,
        'decimalPrecision': _decimalPrecision,
        'balance': balance,
        'emojiIcon': emoji,
        'colorCode': colorCode,
      });
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.pop(context);
      AppSnackbar.show(
        context,
        title: l10n.success,
        message: l10n.walletSaved,
        type: SnackbarType.success,
      );
    } else {
      AppSnackbar.show(
        context,
        title: l10n.error,
        message: error,
        type: SnackbarType.error,
      );
    }
  }

  void _showEmojiPicker() {
    CustomEmojiPickerSheet.show(
      context: context,
      onEmojiSelected: (emoji) {
        setState(() {
          _emojiController.text = emoji;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _showColorPicker() async {
    final newColor = await showCustomColorPicker(
      context: context,
      initialColor: _selectedColor,
    );
    if (newColor != null) {
      setState(() => _selectedColor = newColor);
    }
  }

  String _formatPreviewAmount(double value) {
    return CurrencyFormatter.formatAmount(value, decimalPrecision: _decimalPrecision);
  }

  String _getCountryForCurrency(String code) {
    switch (code) {
      case 'IDR': return 'Indonesia';
      case 'USD': return 'United States';
      case 'EUR': return 'Euro Member';
      case 'SGD': return 'Singapore';
      case 'MYR': return 'Malaysia';
      case 'GBP': return 'United Kingdom';
      case 'JPY': return 'Japan';
      case 'AUD': return 'Australia';
      default: return '';
    }
  }

  void _showDecimalPrecisionSheet() {
    AppBottomSheet.show(
      context: context,
      builder: (_) => _DecimalPrecisionSheet(
        initialPrecision: _decimalPrecision,
        onSave: (val) {
          setState(() {
            _decimalPrecision = val;
          });
        },
      ),
    );
  }

  void _showBalanceCalculatorSheet() {
    final currentAmount = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    AmountCalculatorSheet.show(
      context,
      initialAmount: currentAmount,
      initialCurrency: _currencyValue,
      decimalPrecision: _decimalPrecision,
      title: l10n.initialBalance,
      description: l10n.languageCode == 'id'
          ? 'Saldo awal untuk memulai pencatatan wallet'
          : 'Initial balance to start tracking wallet',
      onSave: (amount, currency) {
        setState(() {
          _balanceController.text = amount.toString();
          _currencyValue = currency;
        });
      },
    );
  }

  Future<void> _confirmDelete() async {
    if (widget.initialWallet == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteWallet),
        content: Text(l10n.deleteWalletConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await ref
        .read(walletsProvider.notifier)
        .deleteWallet(widget.initialWallet!['id']);

    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      AppSnackbar.show(
        context,
        title: l10n.success,
        message: l10n.deleteWallet,
        type: SnackbarType.success,
      );
    } else {
      AppSnackbar.show(
        context,
        title: l10n.error,
        message: error,
        type: SnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconShape = ref.watch(categoryIconShapeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialWallet == null ? l10n.addWallet : l10n.editWallet,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.initialWallet != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              onPressed: _confirmDelete,
              tooltip: l10n.deleteWallet,
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _showEmojiPicker();
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: ShapeDecoration(
                          color: _selectedColor,
                          shape: iconShape.toShapeBorder(64),
                        ),
                        child: Center(
                          child: Text(
                            _emojiController.text.isNotEmpty
                                ? _emojiController.text
                                : '💼',
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        label: l10n.walletName,
                        hint: 'e.g. Main Bank',
                        controller: _nameController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _showColorPicker();
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB3B9D6),
                            shape: BoxShape.circle,
                            border: !_presetColors.contains(_selectedColor)
                                ? Border.all(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.primary,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: const Icon(
                            Icons.palette_outlined,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ..._presetColors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            setState(() => _selectedColor = color);
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.primary,
                                      width: 3,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.isBaseCurrency,
                      style: AppTypography.textTheme.bodyMedium),
                  value: _isBaseCurrency,
                  onChanged: (val) {
                    setState(() => _isBaseCurrency = val);
                  },
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.primary,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _typeValue,
                  dropdownColor: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.walletType,
                    labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'cash', child: Text(l10n.walletTypeCash)),
                    DropdownMenuItem(
                        value: 'bank', child: Text(l10n.walletTypeBank)),
                    DropdownMenuItem(
                        value: 'e_wallet', child: Text(l10n.walletTypeEWallet)),
                    DropdownMenuItem(
                        value: 'crypto', child: Text(l10n.walletTypeCrypto)),
                    DropdownMenuItem(value: 'other', child: Text(l10n.other)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _typeValue = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // ── Decimal Precision & Initial Balance Combined Card (Stacked vertically) ──
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Column(
                    children: [
                      // Top hitbox: Decimal Precision (no left icon)
                      InkWell(
                        onTap: _showDecimalPrecisionSheet,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.walletDecimalPrecision,
                                  style: AppTypography.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.walletDecimalBadge(_decimalPrecision),
                                  style: AppTypography.textTheme.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Horizontal Divider
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                      // Bottom hitbox: Initial Balance (label + amount stacked, chevron right)
                      InkWell(
                        onTap: _showBalanceCalculatorSheet,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.initialBalance,
                                      style: AppTypography.textTheme.labelMedium?.copyWith(
                                        color: isDark ? Colors.white54 : Colors.black45,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatPreviewAmount(double.tryParse(_balanceController.text.trim()) ?? 0),
                                      style: AppTypography.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // ── Currency Selection Section ──
                Builder(
                  builder: (context) {
                    final currencies = AppConstants.supportedCurrencies;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: currencies.length,
                      itemBuilder: (context, index) {
                        final c = currencies[index];
                        final code = c['code']!;
                        final symbol = c['symbol']!;
                        final name = c['name']!;
                        final country = _getCountryForCurrency(code);
                        final isSelected = _currencyValue == code;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currencyValue = code;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.black12),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  code,
                                  style: AppTypography.textTheme.labelSmall?.copyWith(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  symbol,
                                  style: AppTypography.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  country.isNotEmpty ? country : name,
                                  style: AppTypography.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: _isLoading ? null : _submit,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        l10n.saveButton,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DecimalPrecisionSheet extends StatefulWidget {
  const _DecimalPrecisionSheet({
    required this.initialPrecision,
    required this.onSave,
  });

  final int initialPrecision;
  final void Function(int precision) onSave;

  @override
  State<_DecimalPrecisionSheet> createState() => _DecimalPrecisionSheetState();
}

class _DecimalPrecisionSheetState extends State<_DecimalPrecisionSheet> {
  // null = no user input yet (show placeholder)
  String? _typedStr;
  String? _pressedKey;

  String get _displayStr => _typedStr ?? widget.initialPrecision.toString();
  bool get _hasUserInput => _typedStr != null;

  void _onKeyPress(String key) {
    setState(() {
      _pressedKey = key;
      if (key == '⌫') {
        if (_typedStr != null && _typedStr!.isNotEmpty) {
          final next = _typedStr!.substring(0, _typedStr!.length - 1);
          _typedStr = next.isEmpty ? null : next;
        }
      } else if (key == ',') {
        // Precision is integer only, ignore comma
      } else {
        // Start fresh on first key press
        if (_typedStr == null) {
          _typedStr = key == '0' ? '0' : key;
        } else {
          if (_typedStr == '0') {
            _typedStr = key;
          } else if (_typedStr!.length < 2) {
            _typedStr = _typedStr! + key;
          }
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 130), () {
      if (mounted) setState(() => _pressedKey = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header: Title + Description ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.walletDecimalPrecision,
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.walletDecimalPrecisionSheetDesc,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
        // ── Number Display (like calculator) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              _displayStr,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: _hasUserInput
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white24 : Colors.black26),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // ── Numpad Grid ──
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
                _buildNumpadRow(['1', '2', '3'], isDark),
                _buildNumpadRow(['4', '5', '6'], isDark),
                _buildNumpadRow(['7', '8', '9'], isDark),
                _buildNumpadRow(['', '0', '⌫'], isDark),
              ],
            ),
          ),
        ),
        // ── Action Buttons ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              // Reset Button
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _typedStr = '2');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.walletDecimalReset,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Save Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    final val = int.tryParse(_displayStr) ?? 2;
                    widget.onSave(val);
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
          ),
        ),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> keys, bool isDark) {
    return Row(
      children: keys.map((key) {
        if (key.isEmpty) {
          // Empty placeholder cell
          return const Expanded(child: SizedBox(height: 64));
        }
        final isPressed = _pressedKey == key;
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
                          size: 22,
                          color: isDark ? Colors.white70 : Colors.black54,
                        )
                      : Text(
                          key,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
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
