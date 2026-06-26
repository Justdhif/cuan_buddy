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
import '../providers/transaction_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../savings/presentation/providers/savings_provider.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    required this.initialType,
    this.initialTransaction,
    this.initialSavingsGoalId,
    this.lockedSavingsGoal = false,
  });

  final String initialType; // 'income' or 'expense'
  final Map<String, dynamic>? initialTransaction;
  final String? initialSavingsGoalId; // pre-select a savings goal
  final bool lockedSavingsGoal; // cannot be changed when true

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _type;
  String? _selectedCategoryId;
  String? _selectedSavingsGoalId;
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = AppConstants.defaultCurrency;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    // Pre-select a locked savings goal if provided
    if (widget.initialSavingsGoalId != null) {
      _selectedSavingsGoalId = widget.initialSavingsGoalId;
    }
    if (widget.initialTransaction != null) {
      final tx = widget.initialTransaction!;
      _type = tx['type'] as String? ?? widget.initialType;
      _titleController.text = tx['title'] as String? ?? '';
      _amountController.text = (tx['amount'] ?? '').toString();
      _noteController.text = tx['note'] as String? ?? '';
      _selectedCategoryId = tx['categoryId'] as String?;
      _selectedSavingsGoalId = tx['savingsGoalId'] as String?;
      if (tx['date'] != null) {
        _selectedDate = DateTime.parse(tx['date'] as String).toLocal();
      }
      if (tx['currency'] != null) {
        _selectedCurrency = tx['currency'] as String;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
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

    try {
      final dio = ref.read(dioClientProvider).dio;
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'type': _type,
        'amount': double.parse(_amountController.text.replaceAll(',', '')),
        'currency': _selectedCurrency,
        'categoryId': _selectedCategoryId,
        'savingsGoalId': _selectedSavingsGoalId,
        'date': _selectedDate.toUtc().toIso8601String(),
      };
      if (_noteController.text.isNotEmpty) {
        payload['note'] = _noteController.text.trim();
      }

      if (widget.initialTransaction != null) {
        final id = widget.initialTransaction!['id'];
        await dio.patch('/transactions/$id', data: payload);
      } else {
        await dio.post('/transactions', data: payload);
      }

      // Invalidate all relevant providers to refresh data
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(analyticsSummaryProvider);
      ref.invalidate(financialHealthProvider);
      ref.invalidate(calendarSummaryProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.read(notificationsNotifierProvider.notifier).fetchNotifications();

      if (mounted) {
        context.pop();
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: l10n.transactionSaved,
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: e.toString(),
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTransaction),
        content: Text(l10n.deleteTransactionConfirm),
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
        final dio = ref.read(dioClientProvider).dio;
        final id = widget.initialTransaction!['id'];
        await dio.delete('/transactions/$id');

        ref.invalidate(allTransactionsProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(analyticsSummaryProvider);
        ref.invalidate(financialHealthProvider);
        ref.invalidate(calendarSummaryProvider);
        ref.invalidate(monthlySummaryProvider);
        ref.read(notificationsNotifierProvider.notifier).fetchNotifications();

        if (mounted) {
          context.pop();
          AppSnackbar.show(
            context,
            title: l10n.success,
            message: l10n.deleteTransaction,
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
    final typeColor = _type == 'income' ? AppColors.success : AppColors.danger;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final savingsState = ref.watch(savingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialTransaction != null
              ? l10n.editTransaction
              : l10n.addTransaction,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.initialTransaction != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              onPressed: _confirmAndDelete,
              tooltip: l10n.deleteTransaction,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Type Toggle ─────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.borderLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildTypeTab(
                        context: context,
                        targetType: 'expense',
                        label: l10n.expenseType,
                        activeColor: AppColors.danger,
                        isDark: isDark,
                      ),
                      _buildTypeTab(
                        context: context,
                        targetType: 'income',
                        label: l10n.incomeType,
                        activeColor: AppColors.success,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Title ─────────────────────────────────────────────
                AppTextField(
                  controller: _titleController,
                  label: l10n.transactionTitle,
                  hint: l10n.transactionTitleHint,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.titleRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Amount & Currency ─────────────────────────────────────────────
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
                          labelText: 'Currency',
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
                            child: Text(
                              '${c['code']} (${c['symbol']})',
                              style: AppTypography.textTheme.bodyMedium,
                            ),
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
                        label: l10n.amount,
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
                const SizedBox(height: 16),

                // ── Category ────────────────────────────────────────────
                Text(l10n.category, style: AppTypography.textTheme.labelMedium),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  loading: () => _buildCategorySkeletonLoader(isDark),
                  error: (_, __) => Text(
                    l10n.failedToLoadCategories,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                  data: (allCategories) {
                    final filtered = allCategories.where((c) {
                      final catType = c['type'] as String?;
                      return catType == _type || catType == null;
                    }).toList();

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
                              '💰';
                          final isSelected = _selectedCategoryId == catId;
                          final catColor = AppColors.colorFromHex(
                              cat['colorCode'] as String?,
                              fallback: typeColor);

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
                                    ? catColor.withValues(alpha: 0.15)
                                    : (isDark
                                        ? AppColors.surfaceDark
                                        : const Color(0xFFF3F0FF)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? catColor
                                      : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(catEmoji,
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(
                                    catName,
                                    style: AppTypography.textTheme.labelMedium
                                        ?.copyWith(
                                      color: isSelected ? catColor : null,
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
                const SizedBox(height: 16),

                // ── Savings Goals ──────────────────────────────────────
                if (widget.lockedSavingsGoal && _selectedSavingsGoalId != null) ...[
                  // Locked goal from savings detail — show read-only chip
                  Builder(builder: (context) {
                    final goal = savingsState.goals.cast<Map<String, dynamic>?>().firstWhere(
                      (g) => g?['id'] == _selectedSavingsGoalId,
                      orElse: () => null,
                    );
                    final goalName = goal?['name'] as String? ?? l10n.savingsGoals;
                    final goalEmoji = goal?['emojiIcon'] as String? ?? '🎯';
                    final colorHex = goal?['colorCode'] as String? ?? '#6C63FF';
                    final goalColor = AppColors.colorFromHex(colorHex, fallback: AppColors.primary);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.selectSavingsGoal,
                              style: AppTypography.textTheme.titleSmall,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_rounded, size: 11, color: AppColors.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Locked',
                                    style: AppTypography.textTheme.labelSmall?.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: goalColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: goalColor, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(goalEmoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                goalName,
                                style: AppTypography.textTheme.labelMedium?.copyWith(
                                  color: goalColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.lock_rounded, size: 14, color: goalColor.withValues(alpha: 0.6)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ] else if (!savingsState.isLoading && savingsState.goals.isNotEmpty) ...[
                  Text(
                    l10n.selectSavingsGoal,
                    style: AppTypography.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: savingsState.goals.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // "Tidak ada tujuan" (None) button
                          final isSelected = _selectedSavingsGoalId == null;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedSavingsGoalId = null),
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
                                    l10n.noSavingsGoals,
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
                        }

                        final goal = savingsState.goals[index - 1];
                        final goalId = goal['id'] as String?;
                        final goalName = goal['name'] as String? ?? '';
                        final isSelected = _selectedSavingsGoalId == goalId;
                        final goalEmoji = goal['emojiIcon'] as String? ?? '🎯';

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedSavingsGoalId = goalId),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : (isDark
                                      ? AppColors.surfaceDark
                                      : const Color(0xFFF3F0FF)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.success
                                    : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(goalEmoji,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  goalName,
                                  style: AppTypography.textTheme.labelMedium
                                      ?.copyWith(
                                    color:
                                        isSelected ? AppColors.success : null,
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
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Note ───────────────────────────────────────────────
                AppTextField(
                  controller: _noteController,
                  label: l10n.noteOptional,
                  hint: l10n.expenseHint,
                ),
                const SizedBox(height: 16),

                // ── Date Picker ────────────────────────────────────────
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
                      labelText: l10n.date,
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
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: AppTypography.textTheme.bodyLarge,
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Save Button ────────────────────────────────────────
                AppButton(
                  label: l10n.saveTransaction,
                  onPressed: _save,
                  type: _type == 'income'
                      ? AppButtonType.primary
                      : AppButtonType.danger,
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

  Widget _buildTypeTab({
    required BuildContext context,
    required String targetType,
    required String label,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _type == targetType;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = targetType;
          _selectedCategoryId = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.titleSmall?.copyWith(
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

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
