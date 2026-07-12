import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/custom_emoji_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/color_picker_sheet.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../transactions/presentation/widgets/amount_calculator_sheet.dart';
import '../providers/savings_provider.dart';
import '../../../wallets/providers/wallet_provider.dart';

class SavingsFormScreen extends ConsumerStatefulWidget {
  const SavingsFormScreen({super.key, this.goal});
  final Map<String, dynamic>? goal;

  @override
  ConsumerState<SavingsFormScreen> createState() => _SavingsFormScreenState();
}

class _SavingsFormScreenState extends ConsumerState<SavingsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _linkController = TextEditingController();
  String? _selectedWalletId;
  String? _roomId;
  DateTime? _selectedDate;
  String _selectedCurrency = AppConstants.defaultCurrency;
  String? _selectedEmoji;
  Color _selectedColor = AppColors.primary;
  bool _isPin = false;
  bool _isSaving = false;

  final List<Color> _presetColors = [
    AppColors.primary,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
  ];

  Color _colorFromHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.primary;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    final argb = color.toARGB32();
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _roomId = widget.goal!['roomId'] as String?;
      _nameController.text = widget.goal!['name'] ?? '';
      _selectedEmoji = widget.goal!['emojiIcon'] as String?;
      _selectedColor = _colorFromHex(widget.goal!['colorCode'] as String?);
      _isPin = widget.goal!['isPin'] as bool? ?? false;
      _linkController.text = widget.goal!['link'] as String? ?? '';

      final rawT = widget.goal!['targetAmount'];
      final targetAmount = rawT is num
          ? rawT.toDouble()
          : double.tryParse(rawT?.toString() ?? '0') ?? 0;
      _amountController.text = NumberFormat('#,###').format(targetAmount);

      _selectedCurrency =
          widget.goal!['currency'] ?? AppConstants.defaultCurrency;
          
      _selectedWalletId = widget.goal!['walletId']?.toString();

      final targetDateStr = widget.goal!['targetDate']?.toString();
      if (targetDateStr != null) {
        _selectedDate = DateTime.tryParse(targetDateStr);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _showEmojiPicker() {
    CustomEmojiPickerSheet.show(
      context: context,
      onEmojiSelected: (emoji) {
        setState(() {
          _selectedEmoji = emoji;
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

  void _showNameInputSheet() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetController = TextEditingController(text: _nameController.text);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.goalName,
                style: AppTypography.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: sheetController,
                label: l10n.goalName,
                hint: l10n.goalNameHint,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _nameController.text = sheetController.text;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      l10n.saveChanges,
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAmountCalculatorSheet() {
    final initialAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    AmountCalculatorSheet.show(
      context,
      initialAmount: initialAmount,
      initialCurrency: _selectedCurrency,
      onSave: (amount, currency) {
        setState(() {
          _amountController.text = NumberFormat('#,###').format(amount);
          _selectedCurrency = currency;
        });
      },
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    
    // Custom validation for Top Integrated Name & Amount
    if (_nameController.text.trim().isEmpty) {
      AppSnackbar.show(context,
          title: l10n.error,
          message: l10n.nameRequired,
          type: SnackbarType.error);
      return;
    }
    
    final rawAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (rawAmount <= 0) {
      AppSnackbar.show(context,
          title: l10n.error,
          message: l10n.amountRequired,
          type: SnackbarType.error);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'name': _nameController.text.trim(),
        'emojiIcon': _selectedEmoji,
        'colorCode': _colorToHex(_selectedColor),
        'targetAmount': rawAmount,
        'currency': _selectedCurrency,
        'isPin': _isPin,
        'link': _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        if (_selectedWalletId != null) 'walletId': _selectedWalletId,
        if (_roomId != null) 'roomId': _roomId,
      };
      if (_selectedDate != null) {
        payload['targetDate'] = _selectedDate!.toUtc().toIso8601String();
      }
      final dio = ref.read(dioClientProvider).dio;
      if (widget.goal == null || widget.goal!['id'] == null) {
        await dio.post('/goals', data: payload);
        ref.invalidate(savingsNotifierProvider);
        if (mounted) {
          context.pop();
          AppSnackbar.show(context,
              title: l10n.success,
              message: l10n.goalSavedSuccess,
              type: SnackbarType.success);
        }
      } else {
        await dio.patch('/goals/${widget.goal!['id']}', data: payload);
        ref.invalidate(savingsNotifierProvider);
        if (mounted) {
          context.pop();
          AppSnackbar.show(context,
              title: l10n.success,
              message: 'Goal updated successfully',
              type: SnackbarType.success);
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackbar.show(context,
            title: l10n.error,
            message: e.toString(),
            type: SnackbarType.error);
      }
    }
  }

  Future<void> _confirmAndDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteGoal),
        content: Text(l10n.deleteGoalConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        await ref
            .read(savingsNotifierProvider.notifier)
            .deleteGoal(widget.goal!['id']);
        if (mounted) {
          context.pop();
          AppSnackbar.show(
            context,
            title: l10n.success,
            message: 'Goal deleted successfully',
            type: SnackbarType.success,
          );
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          AppSnackbar.show(
            context,
            title: l10n.error,
            message: '${l10n.failedToDelete}: $e',
            type: SnackbarType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(walletsProvider);
    final iconShape = ref.watch(categoryIconShapeProvider);

    // Auto-select first wallet if creating a new goal
    if (widget.goal == null &&
        _selectedWalletId == null &&
        walletsAsync is AsyncData &&
        walletsAsync.value != null &&
        walletsAsync.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedWalletId = walletsAsync.value!.first['id']);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          widget.goal == null ? l10n.newGoal : l10n.editGoal,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.goal != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              onPressed: _confirmAndDelete,
              tooltip: l10n.deleteGoal,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Integrated Block ──────────────────────────────────
                Container(
                  color: isDark
                      ? const Color(0xFF232838)
                      : AppColors.primary.withValues(alpha: 0.05),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_amountController, _nameController]),
                    builder: (context, _) {
                      final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
                      return SavingsFormHeader(
                        amount: amount,
                        currencyCode: _selectedCurrency,
                        emoji: _selectedEmoji,
                        color: _selectedColor,
                        name: _nameController.text,
                        isDark: isDark,
                        iconShape: iconShape,
                        onEmojiTap: _showEmojiPicker,
                        onAmountTap: _showAmountCalculatorSheet,
                        onNameTap: _showNameInputSheet,
                      );
                    },
                  ),
                ),

                // ── Form Fields ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.budgetColor, style: AppTypography.textTheme.titleSmall),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 32),

                      // ── Wallet Selector ──────────────────────────────────
                      Text(l10n.selectWallet, style: AppTypography.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      walletsAsync.when(
                        loading: () => const SizedBox(height: 44, child: Center(child: CircularProgressIndicator())),
                        error: (_, __) => Text(l10n.failedToLoadWallet,
                            style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                        data: (wallets) {
                          if (wallets.isEmpty) {
                            return Row(
                              children: [
                                Expanded(child: Text(l10n.noWalletsFound)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => context.push('/manage-wallets'),
                                ),
                              ],
                            );
                          }
                          return SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              clipBehavior: Clip.none,
                              physics: const BouncingScrollPhysics(),
                              itemCount: wallets.length + 1,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                if (index == wallets.length) {
                                  return GestureDetector(
                                    onTap: () => context.push('/manage-wallets'),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Center(child: Icon(Icons.add, size: 20)),
                                    ),
                                  );
                                }

                                final wallet = wallets[index];
                                final walletId = wallet['id'] as String;
                                final walletName = '${wallet['name']} (${wallet['currency']})';
                                final walletEmoji = wallet['emojiIcon'] as String? ?? '💼';
                                final walletColorHex = wallet['colorCode'] as String? ?? '#6C63FF';
                                final walletColor = AppColors.colorFromHex(walletColorHex, fallback: AppColors.primary);
                                final isSelected = _selectedWalletId == walletId;

                                return GestureDetector(
                                  onTap: () => setState(() => _selectedWalletId = walletId),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? walletColor.withValues(alpha: 0.2)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      border: Border.all(
                                        color: isSelected ? walletColor : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(walletEmoji, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Text(
                                          walletName,
                                          style: AppTypography.textTheme.labelMedium?.copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected
                                                ? (isDark ? Colors.white : walletColor)
                                                : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // ── Target Date ────────────────────────────────────────
                      Text(l10n.targetDateOptional, style: AppTypography.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate != null
                                    ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                                    : l10n.selectDate,
                                style: AppTypography.textTheme.bodyLarge?.copyWith(
                                  color: _selectedDate == null
                                      ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                      : null,
                                ),
                              ),
                              const Icon(Icons.calendar_today_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Pinned Switch ──────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: SwitchListTile.adaptive(
                          title: Row(
                            children: [
                              Icon(
                                _isPin ? Icons.push_pin : Icons.push_pin_outlined,
                                color: _isPin ? AppColors.primary : (isDark ? Colors.white60 : Colors.black54),
                              ),
                              const SizedBox(width: 12),
                              Text(l10n.pinGoal),
                            ],
                          ),
                          value: _isPin,
                          onChanged: (val) => setState(() => _isPin = val),
                          activeTrackColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Target Purchase Link ──────────────────────────────
                      Text(l10n.purchaseLinkOptional, style: AppTypography.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _linkController,
                        label: l10n.purchaseLinkLabel,
                        hint: l10n.purchaseLinkHint,
                        prefixIcon: const Icon(Icons.link_rounded),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: _isSaving ? null : _save,
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
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        height: 24, width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                    )
                  : Center(
                      child: Text(
                        l10n.saveGoal,
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

// ── Savings Form Header ───────────────────────────────────────────────────────
class SavingsFormHeader extends StatelessWidget {
  const SavingsFormHeader({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.name,
    this.emoji,
    this.color,
    required this.isDark,
    required this.iconShape,
    required this.onEmojiTap,
    required this.onAmountTap,
    required this.onNameTap,
  });

  final double amount;
  final String currencyCode;
  final String? name;
  final String? emoji;
  final Color? color;
  final bool isDark;
  final CategoryIconShape iconShape;
  final VoidCallback onEmojiTap;
  final VoidCallback onAmountTap;
  final VoidCallback onNameTap;

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;
    final l10n = AppLocalizations.of(context);
    final displayName = (name == null || name!.isEmpty) ? l10n.goalName : name!;

    return Material(
      color: themeColor.withValues(alpha: 0.15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name Area (Top)
          InkWell(
            onTap: onNameTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: IntrinsicWidth(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 3),
                          ),
                        ),
                        child: Text(
                          displayName,
                          style: AppTypography.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Emoji & Amount Area (Bottom)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Emoji Hitbox (Left Side)
                InkWell(
                  onTap: onEmojiTap,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 12.0, bottom: 24.0),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: ShapeDecoration(
                        color: emoji == null
                            ? (isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B))
                            : themeColor.withValues(alpha: 0.2),
                        shape: iconShape.toShapeBorder(64),
                      ),
                      child: Center(
                        child: emoji == null
                            ? null
                            : Text(emoji!, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),
                ),
                // Amount Hitbox (Right Side)
                Expanded(
                  child: InkWell(
                    onTap: onAmountTap,
                    child: Container(
                      padding: const EdgeInsets.only(right: 24.0, left: 12.0, bottom: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                currencyCode,
                                style: AppTypography.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  amount == 0 ? '0' : NumberFormat('#,###').format(amount),
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
