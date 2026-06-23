import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/providers/core_providers.dart';
import '../providers/budgets_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart'
    show categoriesProvider;

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
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = AppConstants.defaultCurrency;
  bool _isRecurring = false;
  bool _rollover = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      final rawL = widget.budget!['limitAmount'];
      final limitAmount = rawL is num ? rawL.toDouble() : double.tryParse(rawL?.toString() ?? '0') ?? 0;
      _amountController.text = limitAmount.toStringAsFixed(0);
      _selectedCategoryId = widget.budget!['categoryId']?.toString();
      _selectedCurrency = widget.budget!['currency'] ?? AppConstants.defaultCurrency;
      _isRecurring = widget.budget!['isRecurring'] ?? false;
      _rollover = widget.budget!['rollover'] ?? false;

      if (widget.budget!['monthYear'] != null) {
        final parts = widget.budget!['monthYear'].toString().split('-');
        if (parts.length == 2) {
          _selectedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        }
      }
    } else if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectCategory),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final monthYearStr = DateFormat('yyyy-MM').format(_selectedDate);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final payload = {
        'categoryId': _selectedCategoryId!,
        'limitAmount': double.parse(_amountController.text.replaceAll(',', '')),
        'currency': _selectedCurrency,
        'isRecurring': _isRecurring,
        'rollover': _rollover,
        'monthYear': monthYearStr,
      };
      if (widget.budget == null) {
        await dio.post('/budgets', data: payload);
        ref.invalidate(budgetsNotifierProvider);
        if (mounted) {
          context.pop();
          AppSnackbar.show(context, title: l10n.success, message: 'Budget saved successfully', type: SnackbarType.success);
        }
      } else {
        await dio.patch('/budgets/${widget.budget!['id']}', data: payload);
        ref.invalidate(budgetsNotifierProvider);
        if (mounted) {
          context.pop();
          AppSnackbar.show(context, title: l10n.success, message: 'Budget updated successfully', type: SnackbarType.success);
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackbar.show(context, title: l10n.error, message: e.toString(), type: SnackbarType.error);
      }
    }
  }

  Future<void> _deleteBudget() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(budgetsNotifierProvider.notifier).deleteBudget(widget.budget!['id']);
        if (mounted) {
          context.pop(); // Pop form screen
          AppSnackbar.show(context, title: l10n.success, message: 'Budget deleted successfully', type: SnackbarType.success);
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(context, title: l10n.error, message: 'Failed to delete budget: $e', type: SnackbarType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    // Only show expense categories for budgets
    final expenseCategories = categoriesAsync.whenData((all) =>
        all.where((c) => c['type'] == 'expense' || c['type'] == null).toList());

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          widget.budget == null ? l10n.setBudget : 'Edit Budget',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.budget != null)
            IconButton(
              onPressed: _deleteBudget,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              tooltip: 'Delete Budget',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Limit Amount & Currency ──────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        decoration: InputDecoration(
                          labelText: l10n.currency,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                        ),
                        items: AppConstants.supportedCurrencies.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['code'],
                            child: Text('${c['code']} (${c['symbol']})', style: AppTypography.textTheme.bodyMedium),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCurrency = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        controller: _amountController,
                        label: l10n.limitAmount,
                        hint: '0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.amountRequired;
                          if (double.tryParse(value.replaceAll(',', '')) == null) return l10n.invalidAmount;
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Category ──────────────────────────────────────────────
                Text(l10n.category, style: AppTypography.textTheme.labelMedium),
                const SizedBox(height: 8),
                expenseCategories.when(
                  loading: () => _buildCategorySkeletonLoader(isDark),
                  error: (_, __) => Text(
                    l10n.failedToLoadCategories,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                  data: (filtered) {
                    if (filtered.isEmpty) {
                      return Text(
                        l10n.noCategories,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      );
                    }
                    return SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = filtered[index];
                          final catId = cat['id'] as String?;
                          final catName = cat['name'] as String? ?? '';
                          final catEmoji = cat['emojiIcon'] as String? ??
                              cat['emoji'] as String? ??
                              '📦';
                          final isSelected = _selectedCategoryId == catId;

                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedCategoryId =
                                  isSelected ? null : catId;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : (isDark
                                        ? AppColors.surfaceDark
                                        : const Color(0xFFF3F0FF)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    catEmoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    catName,
                                    style: AppTypography.textTheme.labelMedium
                                        ?.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : null,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
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
                const SizedBox(height: 24),

                // ── Month Picker ───────────────────────────────────────────
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != _selectedDate) {
                      setState(() => _selectedDate = pickedDate);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.month,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedDate),
                          style: AppTypography.textTheme.bodyLarge,
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Recurring & Rollover Toggles ───────────────────────────
                SwitchListTile(
                  title: Text(l10n.recurringBudget, style: AppTypography.textTheme.bodyMedium),
                  value: _isRecurring,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() {
                      _isRecurring = val;
                      if (!val) _rollover = false;
                    });
                  },
                ),
                SwitchListTile(
                  title: Text(
                    l10n.rolloverRemaining,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: _isRecurring
                          ? null
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    )
                  ),
                  value: _rollover,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: _isRecurring ? (val) => setState(() => _rollover = val) : null,
                ),
                const SizedBox(height: 40),

                // ── Save Button ────────────────────────────────────────────
                AppButton(
                  label: l10n.saveBudget,
                  onPressed: _save,
                  type: AppButtonType.primary,
                  isLoading: _isSaving,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Skeleton loader for the category chips row
  Widget _buildCategorySkeletonLoader(bool isDark) {
    return SizedBox(
      height: 52,
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
    final baseColor = widget.isDark
        ? const Color(0xFF2D3748)
        : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 100,
          height: 52,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
