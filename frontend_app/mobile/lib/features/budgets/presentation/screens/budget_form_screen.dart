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
import '../../../wallets/providers/wallet_provider.dart';

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
  String? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = AppConstants.defaultCurrency;
  int _periodCount = 1;
  int _startDay = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      final rawL = widget.budget!['limitAmount'];
      final limitAmount = rawL is num
          ? rawL.toDouble()
          : double.tryParse(rawL?.toString() ?? '0') ?? 0;
      _amountController.text = limitAmount.toStringAsFixed(0);
      _selectedCategoryId = widget.budget!['categoryId']?.toString();
      _selectedWalletId = widget.budget!['walletId']?.toString();
      _selectedCurrency =
          widget.budget!['currency'] ?? AppConstants.defaultCurrency;
      _periodCount = (widget.budget!['periodCount'] as num?)?.toInt() ?? 1;
      _startDay = (widget.budget!['startDay'] as num?)?.toInt() ?? 1;

      if (widget.budget!['monthYear'] != null) {
        final parts = widget.budget!['monthYear'].toString().split('-');
        if (parts.length == 2) {
          _selectedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        }
      }

      final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      if (_startDay > daysInMonth) {
        _startDay = daysInMonth;
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
            title: l10n.error, message: e.toString(), type: SnackbarType.error);
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
            child:
                const Text('Delete', style: TextStyle(color: AppColors.danger)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(walletsProvider);

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
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
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
                        initialValue: _selectedCurrency,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        decoration: InputDecoration(
                          labelText: l10n.currency,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                        ),
                        items: AppConstants.supportedCurrencies.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['code'],
                            child: Text('${c['code']} (${c['symbol']})',
                                style: AppTypography.textTheme.bodyMedium),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCurrency = val);
                          }
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.amountRequired;
                          }
                          if (double.tryParse(value.replaceAll(',', '')) ==
                              null) {
                            return l10n.invalidAmount;
                          }
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
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 12),
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
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                              _selectedCategoryId = isSelected ? null : catId;
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
                                      color:
                                          isSelected ? AppColors.primary : null,
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

                // ── Wallet Selector ───────────────────────────────────────
                Text('Pilih Dompet', style: AppTypography.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  'Biarkan "Semua Dompet" untuk membuat budget global',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                walletsAsync.when(
                  loading: () => _buildCategorySkeletonLoader(isDark),
                  error: (_, __) => const Text('Gagal memuat dompet', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                  data: (wallets) {
                    return SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: wallets.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final walletId = isAll ? null : wallets[index - 1]['id'] as String;
                          final walletName = isAll ? 'Semua Dompet' : wallets[index - 1]['name'] as String;
                          final isSelected = _selectedWalletId == walletId;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedWalletId = walletId),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : (isDark ? AppColors.surfaceDark : const Color(0xFFF3F0FF)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAll ? Icons.account_balance_wallet_rounded : Icons.account_balance_wallet_outlined,
                                    size: 18,
                                    color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    walletName,
                                    style: AppTypography.textTheme.labelMedium?.copyWith(
                                      color: isSelected ? AppColors.primary : null,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

                // ── Start Month Picker ─────────────────────────────────────
                Text('Bulan Mulai', style: AppTypography.textTheme.labelMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                        final daysInMonth = DateTime(picked.year, picked.month + 1, 0).day;
                        if (_startDay > daysInMonth) {
                          _startDay = daysInMonth;
                        }
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
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

                // ── Start Day ─────────────────────────────────────────────
                Text('Mulai Tanggal', style: AppTypography.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  'Periode dimulai pada tanggal berapa setiap bulannya',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDayPicker(isDark),
                const SizedBox(height: 24),

                // ── Period Count ──────────────────────────────────────────
                Text('Jumlah Periode (Bulan)', style: AppTypography.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  'Berapa bulan budget ini berlaku',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPeriodStepper(isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: _isSaving ? null : _save,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        l10n.saveBudget,
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

  // ── Start Day Picker ──────────────────────────────────────
  Widget _buildDayPicker(bool isDark) {
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(daysInMonth, (i) {
              final day = i + 1;
              final isSelected = _startDay == day;
              return GestureDetector(
                onTap: () => setState(() => _startDay = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? const Color(0xFF2D3748)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tanggal dipilih: $_startDay',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Period Count Stepper ─────────────────────────────────────────────────
  Widget _buildPeriodStepper(bool isDark) {
    final endMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + _periodCount - 1,
    );
    final endMonthStr = DateFormat('MMMM yyyy').format(endMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Decrease
              _StepperButton(
                icon: Icons.remove_rounded,
                onTap: _periodCount > 1
                    ? () => setState(() => _periodCount--)
                    : null,
                isDark: isDark,
              ),
              // Value display
              Column(
                children: [
                  Text(
                    '$_periodCount',
                    style: AppTypography.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _periodCount == 1 ? 'bulan' : 'bulan',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              // Increase
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: () => setState(() => _periodCount++),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.date_range_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('MMM yyyy').format(_selectedDate)}  →  $endMonthStr',
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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

// ─── Stepper Button ───────────────────────────────────────────────────────────
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.3)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Icon(
          icon,
          color: enabled
              ? AppColors.primary
              : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
          size: 22,
        ),
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
