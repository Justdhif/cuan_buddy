import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/amount_calculator_sheet.dart';
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
  TimeOfDay _selectedTime = TimeOfDay.now();
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
      bottomNavigationBar: SafeArea(
        child: InkWell(
          onTap: _selectedCategoryId == null
              ? () => _showCategoryPickerSheet(context, isDark, categoriesAsync)
              : _isSaving ? null : _save,
          child: Container(
            width: double.infinity,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(_selectedCategoryId == null ? 0.7 : 1.0),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24, width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    _selectedCategoryId == null ? l10n.selectCategoryAction : l10n.saveTransaction,
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Integrated Block ─────────────────────────────────────────────
            Container(
              color: isDark ? const Color(0xFF232838) : AppColors.primary.withOpacity(0.05),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildTypeTab(
                        context: context,
                        targetType: 'expense',
                        label: l10n.expenseType,
                        activeColor: isDark ? const Color(0xFF2A3043) : AppColors.primary.withOpacity(0.1),
                        isDark: isDark,
                        icon: Icons.arrow_drop_down_rounded,
                        iconColor: AppColors.danger,
                      ),
                      _buildTypeTab(
                        context: context,
                        targetType: 'income',
                        label: l10n.incomeType,
                        activeColor: isDark ? const Color(0xFF2A3043) : AppColors.primary.withOpacity(0.1),
                        isDark: isDark,
                        icon: Icons.arrow_drop_up_rounded,
                        iconColor: AppColors.success,
                      ),
                    ],
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _amountController,
                    ]),
                    builder: (context, _) {
                      Map<String, dynamic>? selectedCategoryObj;
                      categoriesAsync.whenData((categories) {
                        if (_selectedCategoryId != null) {
                          try {
                            selectedCategoryObj = categories.firstWhere((c) => c['id'] == _selectedCategoryId);
                          } catch (_) {}
                        }
                      });

                      final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
                      final categoryEmoji = selectedCategoryObj?['emojiIcon'] as String?;
                      final categoryColorHex = selectedCategoryObj?['colorCode'] as String?;
                      final categoryColor = categoryColorHex != null 
                          ? AppColors.colorFromHex(categoryColorHex)
                          : const Color(0xFF121212);

                      return TransactionFormHeader(
                        amount: amount,
                        currencyCode: _selectedCurrency,
                        categoryEmoji: categoryEmoji,
                        categoryColor: categoryColor,
                        type: _type,
                        isDark: isDark,
                        onCategoryTap: () => _showCategoryPickerSheet(context, isDark, categoriesAsync),
                        onAmountTap: () {
                          _showAmountCalculatorSheet();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Scrollable Form Fields ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Date & Time Picker ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: Date
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 20),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _pickDate,
                                child: Text(
                                  DateFormat('MMM').format(_selectedDate),
                                  style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: _pickDate,
                                child: Text(
                                  DateFormat('dd').format(_selectedDate),
                                  style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: _pickDate,
                                child: Text(
                                  DateFormat('yyyy').format(_selectedDate),
                                  style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          // Right: Time
                          InkWell(
                            onTap: _pickTime,
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedTime.format(context),
                                  style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // ── Savings Goals ──────────────────────────────────────
                      if (widget.lockedSavingsGoal && _selectedSavingsGoalId != null) ...[
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
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.lock_rounded, size: 11, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Terkunci',
                                          style: AppTypography.textTheme.labelSmall?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      border: Border.all(color: AppColors.primary, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(goalEmoji, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Text(
                                          goalName,
                                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 24),
                      ] else ...[
                        SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 2 + (savingsState.isLoading ? 3 : savingsState.goals.length),
                                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      final isSelected = _selectedSavingsGoalId == null;
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedSavingsGoalId = null),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary.withOpacity(0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                            border: Border.all(
                                              color: isSelected ? AppColors.primary : Colors.transparent,
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Tidak ada tujuan',
                                              style: AppTypography.textTheme.bodyMedium?.copyWith(
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white70 : Colors.black87),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else if (index == 1) {
                                      return GestureDetector(
                                        onTap: () => context.push('/savings/form'),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.add, size: 20),
                                          ),
                                        ),
                                      );
                                    } else {
                                      final goalIndex = index - 2;
                                      if (savingsState.isLoading) {
                                        return _SkeletonChip(isDark: isDark);
                                      }

                                      final goal = savingsState.goals[goalIndex];
                                      final goalId = goal['id'] as String;
                                      final goalName = goal['name'] as String? ?? '';
                                      final goalEmoji = goal['emojiIcon'] as String? ?? '🎯';
                                      
                                      final isSelected = _selectedSavingsGoalId == goalId;
                                      
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedSavingsGoalId = goalId),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary.withOpacity(0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                            border: Border.all(
                                              color: isSelected ? AppColors.primary : Colors.transparent,
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(goalEmoji, style: const TextStyle(fontSize: 16)),
                                              const SizedBox(width: 8),
                                              Text(
                                                goalName,
                                                style: AppTypography.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white70 : Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Title & Notes Area ─────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            AppTextField(
                              controller: _titleController,
                              hint: l10n.transactionTitleHint,
                              prefixIcon: const Icon(Icons.title_rounded),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.titleRequired;
                                }
                                return null;
                              },
                            ),
                            const Divider(height: 1, indent: 48),
                            AppTextField(
                              controller: _noteController,
                              hint: l10n.noteOptional,
                              prefixIcon: const Icon(Icons.notes_rounded),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    IconData? icon,
    Color? iconColor,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? (iconColor ?? AppColors.primary) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? iconColor : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _showAmountCalculatorSheet() {
    AmountCalculatorSheet.show(
      context,
      initialAmount: double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0,
      initialCurrency: _selectedCurrency,
      onSave: (amount, currency) {
        setState(() {
          _amountController.text = NumberFormat('#,###').format(amount);
          _selectedCurrency = currency;
        });
      },
    );
  }

  void _showCategoryPickerSheet(BuildContext context, bool isDark, AsyncValue<List<dynamic>> categoriesAsync) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih Kategori',
              style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  final filtered = categories.where((c) {
                    final catType = (c as Map)['type'] as String?;
                    return catType == _type || catType == null;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text(l10n.noCategories));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final cat = filtered[index] as Map;
                      final catId = cat['id'] as String;
                      final catName = cat['name'] as String;
                      final catEmoji = cat['emojiIcon'] as String? ?? '💰';
                      final catColorHex = cat['colorCode'] as String?;
                      final catColor = AppColors.colorFromHex(catColorHex);

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategoryId = catId);
                          Navigator.pop(context);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: catColor, width: 2),
                              ),
                              child: Center(
                                child: Text(catEmoji, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              catName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(l10n.error)),
              ),
            ),
          ],
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
class TransactionFormHeader extends StatelessWidget {
  const TransactionFormHeader({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.categoryEmoji,
    this.categoryColor,
    required this.type,
    required this.isDark,
    required this.onCategoryTap,
    required this.onAmountTap,
  });

  final double amount;
  final String currencyCode;
  final String? categoryEmoji;
  final Color? categoryColor;
  final String type;
  final bool isDark;
  final VoidCallback onCategoryTap;
  final VoidCallback onAmountTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = type == 'income' ? AppColors.success : AppColors.danger;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onCategoryTap,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryEmoji == null 
                        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                        : (categoryColor ?? typeColor).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: categoryEmoji == null ? Colors.transparent : (categoryColor ?? typeColor),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: categoryEmoji == null
                        ? Icon(
                            Icons.grid_view_rounded,
                            color: isDark ? Colors.white54 : Colors.black54,
                          )
                        : Text(categoryEmoji!, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: onAmountTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              currencyCode,
                              style: AppTypography.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat('#,###').format(amount),
                        style: AppTypography.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
