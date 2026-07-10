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
import '../../../../core/constants/app_constants.dart';
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
    _nameController = TextEditingController(text: widget.initialWallet?['name']);
    _balanceController = TextEditingController(text: widget.initialWallet?['balance']?.toString() ?? '0');
    _emojiController = TextEditingController(text: widget.initialWallet?['emojiIcon'] ?? '💼');
    _typeValue = widget.initialWallet?['type'] ?? 'cash';
    _currencyValue = widget.initialWallet?['currency'] ?? AppConstants.defaultCurrency;
    _isBaseCurrency = widget.initialWallet?['isBaseCurrency'] == true;
    _selectedColor = _colorFromHex(widget.initialWallet?['colorCode'] as String?);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final currency = _currencyValue;
    final balanceText = _balanceController.text.trim();
    final emoji = _emojiController.text.trim();
    final colorCode = _colorToHex(_selectedColor);

    if (name.isEmpty || currency.isEmpty || balanceText.isEmpty || emoji.isEmpty) {
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
        'balance': balance,
        'emojiIcon': emoji,
        'colorCode': colorCode,
      });
    } else {
      error = await notifier.updateWallet(
        widget.initialWallet!['id'],
        {
          'name': name,
          'type': _typeValue,
          'currency': currency,
          'isBaseCurrency': _isBaseCurrency,
          'balance': balance,
          'emojiIcon': emoji,
          'colorCode': colorCode,
        }
      );
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
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
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
                            _emojiController.text.isNotEmpty ? _emojiController.text : '💼',
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
                                    color: isDark ? Colors.white : AppColors.primary,
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
                                      color: isDark ? Colors.white : AppColors.primary,
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
                DropdownButtonFormField<String>(
                  initialValue: _typeValue,
                  dropdownColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: [
                    DropdownMenuItem(value: 'cash', child: Text(l10n.walletTypeCash)),
                    DropdownMenuItem(value: 'bank', child: Text(l10n.walletTypeBank)),
                    DropdownMenuItem(value: 'e_wallet', child: Text(l10n.walletTypeEWallet)),
                    DropdownMenuItem(value: 'crypto', child: Text(l10n.walletTypeCrypto)),
                    DropdownMenuItem(value: 'other', child: Text(l10n.other)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _typeValue = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _currencyValue,
                        dropdownColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Currency',
                          labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        items: AppConstants.supportedCurrencies.map((c) {
                          return DropdownMenuItem(
                            value: c['code'],
                            child: Text('${c['code']} - ${c['symbol']}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _currencyValue = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        label: l10n.initialBalance,
                        hint: '0',
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.isBaseCurrency, style: AppTypography.textTheme.bodyMedium),
                  value: _isBaseCurrency,
                  onChanged: (val) {
                    setState(() => _isBaseCurrency = val);
                  },
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.primary,
                ),
                const SizedBox(height: 32),
                const SizedBox(height: 12),
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
