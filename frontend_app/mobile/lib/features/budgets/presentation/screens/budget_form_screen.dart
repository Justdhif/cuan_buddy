import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../providers/budgets_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart'
    show categoriesProvider;
import '../../../transactions/presentation/widgets/amount_calculator_sheet.dart';
import '../../../wallets/providers/wallet_provider.dart';
import '../../../../core/widgets/custom_emoji_picker_sheet.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budget, this.initialCategoryId});
  final Map<String, dynamic>? budget;
  final String? initialCategoryId;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  
  String? _selectedEmoji;
  Color _selectedColor = AppColors.primary;
  String _budgetType = 'category'; // 'standalone' or 'category'
  Set<String> _selectedCategoryIds = {};
  
  String? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'IDR';
  int _periodCount = 1;
  int _startDay = 1;
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

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      final rawL = widget.budget!['limitAmount'];
      final limitAmount = rawL is num
          ? rawL.toDouble()
          : double.tryParse(rawL?.toString() ?? '0') ?? 0;
      _amountController.text = limitAmount.toStringAsFixed(0);
      
      _nameController.text = widget.budget!['name'] as String? ?? '';
      _selectedEmoji = widget.budget!['emojiIcon'] as String?;
      
      final colorHex = widget.budget!['colorCode'] as String?;
      if (colorHex != null) {
        _selectedColor = AppColors.colorFromHex(colorHex);
      }
      
      // Parse type
      _budgetType = widget.budget!['type'] == 'standalone' ? 'standalone' : 'category';
      
      // Parse category IDs
      final cats = widget.budget!['categoryIds'];
      if (cats is List) {
        _selectedCategoryIds = cats.map((e) => e.toString()).toSet();
      } else if (widget.budget!['categoryId'] != null) {
        _selectedCategoryIds = {widget.budget!['categoryId'].toString()};
      }
      
      if (_budgetType == 'category' && _selectedCategoryIds.isEmpty && widget.budget!['categoryId'] != null) {
          _selectedCategoryIds.add(widget.budget!['categoryId'].toString());
      }
      
      _selectedWalletId = widget.budget!['walletId']?.toString();
      _selectedCurrency = widget.budget!['currency'] ?? 'IDR';
      _periodCount = (widget.budget!['periodCount'] as num?)?.toInt() ?? 1;
      _startDay = (widget.budget!['startDay'] as num?)?.toInt() ?? 1;

      if (widget.budget!['monthYear'] != null) {
        final parts = widget.budget!['monthYear'].toString().split('-');
        if (parts.length == 2) {
          _selectedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        }
      }

      final daysInMonth =
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      if (_startDay > daysInMonth) {
        _startDay = daysInMonth;
      }
    } else if (widget.initialCategoryId != null) {
      _selectedCategoryIds = {widget.initialCategoryId!};
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final monthYearStr = DateFormat('yyyy-MM').format(_selectedDate);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final payload = {
        'name': _nameController.text.trim(),
        'emojiIcon': _selectedEmoji,
        'colorCode': '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
        'type': _budgetType,
        'categoryIds': _budgetType == 'standalone' ? [] : _selectedCategoryIds.toList(),
        if (_budgetType == 'category' && _selectedCategoryIds.isNotEmpty)
           'categoryId': _selectedCategoryIds.first, // Backward compatibility
        'limitAmount':
            double.parse(_amountController.text.replaceAll(',', '')),
        'currency': _selectedCurrency,
        'monthYear': monthYearStr,
        'periodCount': _periodCount,
        'startDay': _startDay,
        if (_selectedWalletId != null) 'walletId': _selectedWalletId,
      };
      
      if (widget.budget == null) {
        await dio.post('/budgets', data: payload);
        ref.invalidate(budgetsNotifierProvider);
        if (mounted) {
          context.pop();
          AppSnackbar.show(context,
              title: l10n.success,
              message: 'Budget saved successfully',
              type: SnackbarType.success);
        }
      } else {
        await dio.patch('/budgets/${widget.budget!['id']}', data: payload);
        ref.invalidate(budgetsNotifierProvider);
        if (mounted) {
          context.pop();
          AppSnackbar.show(context,
              title: l10n.success,
              message: 'Budget updated successfully',
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

  Future<void> _deleteBudget() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget?'),
        content:
            const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref
            .read(budgetsNotifierProvider.notifier)
            .deleteBudget(widget.budget!['id']);
        if (mounted) {
          context.pop();
          AppSnackbar.show(context,
              title: l10n.success,
              message: 'Budget deleted successfully',
              type: SnackbarType.success);
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(context,
              title: l10n.error,
              message: 'Failed to delete budget: $e',
              type: SnackbarType.error);
        }
      }
    }
  }

  void _showAmountCalculatorSheet() {
    AmountCalculatorSheet.show(
      context,
      initialAmount:
          double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0,
      initialCurrency: _selectedCurrency,
      onSave: (amount, currency) {
        setState(() {
          _amountController.text = NumberFormat('#,###').format(amount);
          _selectedCurrency = currency;
        });
      },
    );
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
  
  void _showColorPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.budgetColor,
              style: AppTypography.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _presetColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3) : null,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final iconShape = ref.watch(categoryIconShapeProvider);

    // Auto-select base currency wallet on create
    if (widget.budget == null &&
        _selectedWalletId == null &&
        walletsAsync is AsyncData &&
        walletsAsync.value != null &&
        walletsAsync.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            final baseWallet = walletsAsync.value!
                .firstWhere((w) => w['isBaseCurrency'] == true);
            setState(() => _selectedWalletId = baseWallet['id']);
          } catch (_) {
            setState(() => _selectedWalletId = walletsAsync.value!.first['id']);
          }
        }
      });
    }

    // Sync currency from selected wallet
    if (_selectedWalletId != null &&
        walletsAsync is AsyncData &&
        walletsAsync.value != null) {
      try {
        final wallet = walletsAsync.value!
            .firstWhere((w) => w['id'] == _selectedWalletId);
        final walletCurrency = wallet['currency'] as String?;
        if (walletCurrency != null && walletCurrency != _selectedCurrency) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedCurrency = walletCurrency);
          });
        }
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          widget.budget == null ? l10n.setBudget : 'Edit Budget',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.budget != null)
            IconButton(
              onPressed: _deleteBudget,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              tooltip: 'Delete Budget',
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
                    animation: _amountController,
                    builder: (context, _) {
                      final amount =
                          double.tryParse(_amountController.text
                                  .replaceAll(',', '')) ??
                              0.0;

                      return BudgetFormHeader(
                        amount: amount,
                        currencyCode: _selectedCurrency,
                        categoryEmoji: _selectedEmoji,
                        categoryColor: _selectedColor,
                        name: null,
                        isDark: isDark,
                        iconShape: iconShape,
                        onCategoryTap: _showEmojiPicker,
                        onAmountTap: _showAmountCalculatorSheet,
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
                      Text('Wallet', style: AppTypography.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      walletsAsync.when(
                        loading: () => _buildCategorySkeletonLoader(isDark),
                        error: (_, __) => const Text('Gagal memuat dompet',
                            style: TextStyle(
                                color: AppColors.danger, fontSize: 12)),
                        data: (wallets) {
                          if (wallets.isEmpty) {
                            return Row(
                              children: [
                                const Expanded(
                                    child: Text(
                                        'No wallets found. Please create one.')),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () =>
                                      context.push('/manage-wallets'),
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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                if (index == wallets.length) {
                                  return GestureDetector(
                                    onTap: () =>
                                        context.push('/manage-wallets'),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: const Center(
                                          child: Icon(Icons.add, size: 20)),
                                    ),
                                  );
                                }

                                final wallet = wallets[index];
                                final walletId = wallet['id'] as String;
                                final walletName =
                                    '${wallet['name']} (${wallet['currency']})';
                                final walletEmoji =
                                    wallet['emojiIcon'] as String? ?? '💼';
                                final walletColorHex =
                                    wallet['colorCode'] as String? ??
                                        '#6C63FF';
                                final walletColor = AppColors.colorFromHex(
                                    walletColorHex,
                                    fallback: AppColors.primary);
                                final isSelected =
                                    _selectedWalletId == walletId;

                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedWalletId = walletId),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? walletColor.withValues(alpha: 0.2)
                                          : (isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFF1F5F9)),
                                      border: Border.all(
                                        color: isSelected
                                            ? walletColor
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(walletEmoji,
                                            style:
                                                const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Text(
                                          walletName,
                                          style: AppTypography
                                              .textTheme.labelMedium
                                              ?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? (isDark
                                                    ? Colors.white
                                                    : walletColor)
                                                : (isDark
                                                    ? Colors.white70
                                                    : Colors.black87),
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
                      const SizedBox(height: 32),

                      AppTextField(
                        controller: _nameController,
                        label: l10n.budgetName,
                        hint: l10n.budgetNameHint,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseFillAllFields;
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),

                      Text('Period', style: AppTypography.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n.periodCountMonths, style: AppTypography.textTheme.bodyLarge),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      color: _selectedColor,
                                      onPressed: _periodCount > 1
                                          ? () => setState(() => _periodCount--)
                                          : null,
                                    ),
                                    Text(
                                      '$_periodCount',
                                      style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: _selectedColor,
                                      onPressed: () => setState(() => _periodCount++),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // ── Budget Type ──
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _budgetType = 'standalone'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _budgetType == 'standalone' ? _selectedColor.withOpacity(0.15) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _budgetType == 'standalone' ? _selectedColor : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    l10n.budgetTypeStandalone,
                                    style: TextStyle(
                                      fontWeight: _budgetType == 'standalone' ? FontWeight.bold : FontWeight.normal,
                                      color: _budgetType == 'standalone' ? (isDark ? Colors.white : _selectedColor) : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _budgetType = 'category'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _budgetType == 'category' ? _selectedColor.withOpacity(0.15) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _budgetType == 'category' ? _selectedColor : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    l10n.budgetTypeSpecific,
                                    style: TextStyle(
                                      fontWeight: _budgetType == 'category' ? FontWeight.bold : FontWeight.normal,
                                      color: _budgetType == 'category' ? (isDark ? Colors.white : _selectedColor) : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Categories Grid (If specific) ──
                      if (_budgetType == 'category') ...[
                        Text(l10n.selectCategories, style: AppTypography.textTheme.titleSmall),
                        const SizedBox(height: 12),
                        categoriesAsync.when(
                          loading: () => _buildCategorySkeletonLoader(isDark),
                          error: (_, __) => Text('Error loading categories', style: TextStyle(color: AppColors.danger)),
                          data: (categories) {
                            final filtered = categories.where((c) {
                              final catType = (c as Map)['type'] as String?;
                              return catType == 'expense' || catType == null;
                            }).toList();

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: filtered.length + 1, // +1 for "All" button
                              itemBuilder: (context, index) {
                                // The first item is "All" button
                                if (index == 0) {
                                  final isAllSelected = _selectedCategoryIds.isEmpty;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategoryIds.clear(); // Clear all specific categories, means "All" is active
                                      });
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Stack(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              width: 56,
                                              height: 56,
                                              alignment: Alignment.center,
                                              decoration: ShapeDecoration(
                                                color: isAllSelected ? AppColors.primary.withOpacity(0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                                shape: iconShape == CategoryIconShape.circle
                                                    ? const CircleBorder()
                                                    : iconShape == CategoryIconShape.squircle
                                                        ? ContinuousRectangleBorder(borderRadius: BorderRadius.circular(28))
                                                        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                shadows: isAllSelected ? [
                                                  BoxShadow(
                                                    color: AppColors.primary.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    spreadRadius: -2,
                                                  )
                                                ] : null,
                                              ),
                                              child: Text('🌐', style: const TextStyle(fontSize: 24)),
                                            ),
                                            if (isAllSelected)
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                                  ),
                                                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'All',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.textTheme.labelSmall?.copyWith(
                                            fontWeight: isAllSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isAllSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final catIndex = index - 1;
                                final cat = filtered[catIndex] as Map;
                                final catId = cat['id'] as String;
                                final catName = cat['name'] as String;
                                final catEmoji = cat['emojiIcon'] as String? ?? cat['emoji'] as String? ?? '💰';
                                final catColorHex = cat['colorCode'] as String?;
                                final catColor = catColorHex != null ? AppColors.colorFromHex(catColorHex) : AppColors.primary;
                                final isSelected = _selectedCategoryIds.contains(catId);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedCategoryIds.remove(catId);
                                      } else {
                                        _selectedCategoryIds.add(catId); // Adding a specific category auto-cancels "All" because _selectedCategoryIds is no longer empty
                                      }
                                    });
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: 56,
                                            height: 56,
                                            alignment: Alignment.center,
                                            decoration: ShapeDecoration(
                                              color: isSelected ? catColor.withOpacity(0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                              shape: iconShape == CategoryIconShape.circle
                                                  ? const CircleBorder()
                                                  : iconShape == CategoryIconShape.squircle
                                                      ? ContinuousRectangleBorder(borderRadius: BorderRadius.circular(28))
                                                      : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              shadows: isSelected ? [
                                                BoxShadow(
                                                  color: catColor.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: -2,
                                                )
                                              ] : null,
                                            ),
                                            child: Text(catEmoji, style: const TextStyle(fontSize: 24)),
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: catColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                                ),
                                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        catName,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.textTheme.labelSmall?.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? (isDark ? Colors.white : catColor) : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                      

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
            color: _selectedColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      ),
                    )
                  : Center(
                      child: Text(
                        l10n.saveBudget,
                        style:
                            AppTypography.textTheme.titleMedium?.copyWith(
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



  Widget _buildCategorySkeletonLoader(bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => _SkeletonChip(isDark: isDark),
      ),
    );
  }
}

// ─── Skeleton Chip ────────────────────────────────────────────────────────────
class _SkeletonChip extends StatefulWidget {
  const _SkeletonChip({required this.isDark});
  final bool isDark;

  @override
  State<_SkeletonChip> createState() => _SkeletonChipState();
}

class _SkeletonChipState extends State<_SkeletonChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 80,
          height: 44,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ─── Budget Form Header ───────────────────────────────────────────────────────
class BudgetFormHeader extends StatelessWidget {
  const BudgetFormHeader({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.name,
    this.categoryEmoji,
    this.categoryColor,
    required this.isDark,
    required this.iconShape,
    required this.onCategoryTap,
    required this.onAmountTap,
  });

  final double amount;
  final String currencyCode;
  final String? name;
  final String? categoryEmoji;
  final Color? categoryColor;
  final bool isDark;
  final CategoryIconShape iconShape;
  final VoidCallback onCategoryTap;
  final VoidCallback onAmountTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = categoryColor ?? AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Hitbox (Left Side)
          Material(
            color: typeColor.withValues(alpha: 0.15),
            child: InkWell(
              onTap: onCategoryTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 24.0),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: ShapeDecoration(
                    color: categoryEmoji == null
                        ? (isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF1E293B))
                        : typeColor.withValues(alpha: 0.2),
                    shape: iconShape == CategoryIconShape.circle
                        ? const CircleBorder()
                        : iconShape == CategoryIconShape.squircle
                            ? ContinuousRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              )
                            : RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                  ),
                  child: Center(
                    child: categoryEmoji == null
                        ? null
                        : Text(categoryEmoji!,
                            style: const TextStyle(fontSize: 28)),
                  ),
                ),
              ),
            ),
          ),

          // Amount & Name Hitbox (Right Side)
          Expanded(
            child: Material(
              color: typeColor.withValues(alpha: 0.15),
              child: InkWell(
                onTap: onAmountTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 24.0),
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
                            style: AppTypography.textTheme.headlineMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              amount == 0
                                  ? '0'
                                  : NumberFormat('#,###').format(amount),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.headlineMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (name != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          name!,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
