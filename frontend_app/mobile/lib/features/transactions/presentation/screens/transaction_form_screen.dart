import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/amount_calculator_sheet.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../providers/transaction_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../savings/presentation/providers/savings_provider.dart';
import '../../../wallets/providers/wallet_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

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
  String? _selectedBudgetId;
  String? _selectedWalletId;
  String? _roomId;
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
      _roomId = tx['roomId'] as String?;
      _type = tx['type'] as String? ?? widget.initialType;
      _titleController.text = tx['title'] as String? ?? '';
      _amountController.text = (tx['amount'] ?? '').toString();
      _noteController.text = tx['note'] as String? ?? '';
      _selectedCategoryId = tx['categoryId'] as String?;
      _selectedSavingsGoalId = tx['savingsGoalId'] as String?;
      _selectedBudgetId = tx['budgetId'] as String?;
      _selectedWalletId = tx['walletId'] as String?;
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
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a wallet'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final baseCurrency = ref.read(profileProvider).valueOrNull?['currency'] as String? ?? 'IDR';
      final currencyService = ref.read(currencyServiceProvider);
      double exchangeRate = 1.0;
      if (_selectedCurrency != baseCurrency) {
        try {
          exchangeRate = await currencyService.convert(1.0, _selectedCurrency, baseCurrency);
        } catch (_) {}
      }

      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'type': _type,
        'amount': double.parse(_amountController.text.replaceAll(',', '')),
        'walletId': _selectedWalletId,
        'exchangeRate': exchangeRate,
        'categoryId': _selectedCategoryId,
        'savingsGoalId': _selectedSavingsGoalId,
        'budgetId': _selectedBudgetId,
        'date': _selectedDate.toUtc().toIso8601String(),
      };
      if (_roomId != null) {
        payload['roomId'] = _roomId;
      }
      if (_noteController.text.isNotEmpty) {
        payload['note'] = _noteController.text.trim();
      }

      if (widget.initialTransaction != null && widget.initialTransaction!['id'] != null) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final savingsState = ref.watch(savingsNotifierProvider);
    final budgetsState = ref.watch(budgetsNotifierProvider);
    final iconShape = ref.watch(categoryIconShapeProvider);
    final walletsState = ref.watch(walletsProvider);

    // Auto-select first wallet if none selected
    if (widget.initialTransaction == null && _selectedWalletId == null && walletsState is AsyncData && walletsState.value != null && walletsState.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) setState(() => _selectedWalletId = walletsState.value!.first['id']);
      });
    }

    // Auto-update currency based on wallet
    String? currentWalletCurrency;
    if (_selectedWalletId != null && walletsState is AsyncData && walletsState.value != null) {
       try {
         final wallet = walletsState.value!.firstWhere((w) => w['id'] == _selectedWalletId);
         currentWalletCurrency = wallet['currency'];
       } catch (e) {
         // Ignore if wallet is not found
       }
    }
    
    if (currentWalletCurrency != null && currentWalletCurrency != _selectedCurrency) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) setState(() => _selectedCurrency = currentWalletCurrency!);
       });
    }

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
      bottomNavigationBar: GestureDetector(
        onTap: _selectedCategoryId == null
            ? () => _showCategoryPickerSheet(context, isDark, categoriesAsync)
            : _isSaving ? null : _save,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _selectedCategoryId == null
                ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                : AppColors.primary,
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
                        _selectedCategoryId == null ? l10n.selectCategoryAction : l10n.saveTransaction,
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
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Integrated Block (scrolls with page) ─────────────────
                Container(
                  color: isDark ? const Color(0xFF232838) : AppColors.primary.withValues(alpha: 0.05),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildTypeTab(
                            context: context,
                            targetType: 'expense',
                            label: l10n.expenseType,
                            activeColor: isDark ? const Color(0xFF2A3043) : AppColors.primary.withValues(alpha: 0.1),
                            isDark: isDark,
                            icon: Icons.arrow_drop_down_rounded,
                            iconColor: AppColors.danger,
                          ),
                          _buildTypeTab(
                            context: context,
                            targetType: 'income',
                            label: l10n.incomeType,
                            activeColor: isDark ? const Color(0xFF2A3043) : AppColors.primary.withValues(alpha: 0.1),
                            isDark: isDark,
                            icon: Icons.arrow_drop_up_rounded,
                            iconColor: AppColors.success,
                          ),
                        ],
                      ),
                      AnimatedBuilder(
                        animation: _amountController,
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
                            title: _titleController.text,
                            amount: amount,
                            currencyCode: _selectedCurrency,
                            categoryEmoji: categoryEmoji,
                            categoryColor: categoryColor,
                            type: _type,
                            isDark: isDark,
                            iconShape: iconShape,
                            onCategoryTap: () => _showCategoryPickerSheet(context, isDark, categoriesAsync),
                            onAmountTap: _showAmountCalculatorSheet,
                            onTitleTap: _showTitleInputSheet,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Form Fields ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Budget Info for selected category (above Date Picker) ──
                      if (_selectedCategoryId != null && _type == 'expense') ...[
                        Builder(builder: (context) {
                          final budget = budgetsState.budgets.cast<Map<String, dynamic>?>().firstWhere(
                            (b) => b?['category']?['id'] == _selectedCategoryId || b?['categoryId'] == _selectedCategoryId,
                            orElse: () => null,
                          );

                          if (budget == null) return const SizedBox.shrink();

                          final rawL = budget['limitAmount'];
                          final limitAmount = rawL is num ? rawL.toDouble() : double.tryParse(rawL?.toString() ?? '0') ?? 0;
                          final rawS = budget['spentAmount'];
                          final spentAmount = rawS is num ? rawS.toDouble() : double.tryParse(rawS?.toString() ?? '0') ?? 0;
                          
                          final budgetCurrency = budget['currency'] as String? ?? AppConstants.defaultCurrency;
                          final enteredAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;

                          final catHex = budget['category']?['colorCode'] as String? ?? budget['colorCode'] as String?;
                          final budgetColor = AppColors.colorFromHex(catHex, fallback: AppColors.primary);
                          final fmt = NumberFormat.currency(locale: 'en_US', symbol: AppConstants.getCurrencySymbol(budgetCurrency), decimalDigits: 0);

                          return FutureBuilder<double>(
                            future: ref.read(currencyServiceProvider).convert(enteredAmount, _selectedCurrency, budgetCurrency),
                            builder: (context, snapshot) {
                              final convertedInput = snapshot.data ?? enteredAmount;
                              final newSpent = spentAmount + convertedInput;
                              final remaining = limitAmount - newSpent;
                              final percentage = limitAmount > 0 ? (newSpent / limitAmount).clamp(0.0, 1.0) : 0.0;

                              Color progressColor;
                              if (percentage >= 1.0) {
                                progressColor = AppColors.danger;
                              } else if (percentage >= 0.8) {
                                progressColor = AppColors.warning;
                              } else {
                                progressColor = AppColors.success;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: budgetColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: budgetColor.withValues(alpha: remaining < 0 ? 0.6 : 0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.account_balance_wallet_rounded, size: 14, color: budgetColor),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Budget Kategori',
                                              style: AppTypography.textTheme.labelMedium?.copyWith(
                                                color: budgetColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          fmt.format(limitAmount),
                                          style: AppTypography.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        minHeight: 6,
                                        backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Terpakai: ${fmt.format(newSpent)}',
                                          style: AppTypography.textTheme.labelSmall?.copyWith(
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              remaining < 0 ? Icons.warning_rounded : Icons.savings_rounded,
                                              size: 13,
                                              color: remaining < 0 ? AppColors.danger : AppColors.success,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              remaining < 0
                                                  ? 'Melebihi ${fmt.format(remaining.abs())}'
                                                  : 'Sisa ${fmt.format(remaining)}',
                                              style: AppTypography.textTheme.labelSmall?.copyWith(
                                                color: remaining < 0 ? AppColors.danger : AppColors.success,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }),
                      ],

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

                      // ── Wallet Selector ──────────────────────────────────────
                      walletsState.when(
                        data: (wallets) {
                          if (wallets.isEmpty) {
                            return Row(
                              children: [
                                const Expanded(child: Text('No wallets found. Please create one.')),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => context.push('/manage-wallets'),
                                ),
                              ],
                            );
                          }
                          return SizedBox(
                            height: 36,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              physics: const BouncingScrollPhysics(),
                              itemCount: wallets.length + 1,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                if (index == wallets.length) {
                                  // Last item: Button plus
                                  return GestureDetector(
                                    onTap: () => context.push('/manage-wallets'),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.add, size: 16),
                                      ),
                                    ),
                                  );
                                }
                                
                                final wallet = wallets[index];
                                final walletId = wallet['id'] as String;
                                final walletName = wallet['name'] as String;
                                final walletCurrency = wallet['currency'] as String;
                                final walletEmoji = wallet['emojiIcon'] as String? ?? '💼';
                                final walletColorHex = wallet['colorCode'] as String? ?? '#6C63FF';
                                final walletColor = AppColors.colorFromHex(walletColorHex, fallback: AppColors.primary);
                                final isSelected = _selectedWalletId == walletId;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedWalletId = walletId;
                                      if (_selectedSavingsGoalId != null) {
                                        final currentGoal = savingsState.goals.cast<Map<String, dynamic>?>().firstWhere(
                                          (g) => g?['id'] == _selectedSavingsGoalId,
                                          orElse: () => null,
                                        );
                                        if (currentGoal != null) {
                                          final goalWalletId = currentGoal['walletId'] as String? ?? currentGoal['wallet']?['id'] as String?;
                                          if (goalWalletId != null && goalWalletId != walletId) {
                                            _selectedSavingsGoalId = null;
                                          }
                                        }
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? walletColor.withValues(alpha: 0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      border: Border.all(
                                        color: isSelected ? walletColor : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(walletEmoji, style: const TextStyle(fontSize: 14)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$walletName ($walletCurrency)',
                                          style: AppTypography.textTheme.labelMedium?.copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? (isDark ? Colors.white : walletColor) : (isDark ? Colors.white70 : Colors.black87),
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
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Failed to load wallets'),
                      ),
                      const SizedBox(height: 12),

                      // ── Savings Goals ──────────────────────────────────────
                      if (widget.lockedSavingsGoal && _selectedSavingsGoalId != null) ...[
                        Builder(builder: (context) {
                          final goal = savingsState.goals.cast<Map<String, dynamic>?>().firstWhere(
                            (g) => g?['id'] == _selectedSavingsGoalId,
                            orElse: () => null,
                          );
                          final goalName = goal?['name'] as String? ?? l10n.savingsGoals;
                          final goalEmoji = goal?['emojiIcon'] as String? ?? '🎯';
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
                                        Icon(Icons.lock_rounded, size: 11, color: AppColors.primary),
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
                        Builder(builder: (context) {
                          final goals = savingsState.goals.where((g) {
                            if (g == null) return false;
                            final goalWalletId = g['walletId'] as String? ?? g['wallet']?['id'] as String?;
                            return goalWalletId == null || goalWalletId == _selectedWalletId;
                          }).toList();
                          
                          return SizedBox(
                            height: 36,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              physics: const BouncingScrollPhysics(),
                              itemCount: 2 + (savingsState.isLoading ? 3 : goals.length),
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // 1. No saving goals
                                  final isSelected = _selectedSavingsGoalId == null;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedSavingsGoalId = null),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : Colors.transparent,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          l10n.noSavingsGoals,
                                          style: AppTypography.textTheme.labelMedium?.copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (index == 1 + (savingsState.isLoading ? 3 : goals.length)) {
                                  // 3. Button plus (Last item)
                                  return GestureDetector(
                                    onTap: () => context.push('/savings/form'),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.add, size: 16),
                                      ),
                                    ),
                                  );
                                } else {
                                  // 2. Data saving
                                  final goalIndex = index - 1;
                                  if (savingsState.isLoading) {
                                    return _SkeletonChip(isDark: isDark);
                                  }

                                  final goal = goals[goalIndex];
                                  final goalId = goal['id'] as String;
                                  final goalName = goal['name'] as String? ?? '';
                                  final goalEmoji = goal['emojiIcon'] as String? ?? '🎯';
                                  final goalColorHex = goal['colorCode'] as String? ?? '#6C63FF';
                                  final goalColor = AppColors.colorFromHex(goalColorHex, fallback: AppColors.primary);

                                  final isSelected = _selectedSavingsGoalId == goalId;

                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedSavingsGoalId = goalId),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? goalColor.withValues(alpha: 0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                        border: Border.all(
                                          color: isSelected ? goalColor : Colors.transparent,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(goalEmoji, style: const TextStyle(fontSize: 14)),
                                          const SizedBox(width: 6),
                                          Text(
                                            goalName,
                                            style: AppTypography.textTheme.labelMedium?.copyWith(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? (isDark ? Colors.white : goalColor) : (isDark ? Colors.white70 : Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],

                      // ── Budgets (standalone only) ──────────────────────────
                      Builder(builder: (context) {
                        final allBudgets = budgetsState.budgets;
                        final standaloneBudgets = allBudgets.where((b) {
                          return (b as Map)['type'] == 'standalone';
                        }).toList();

                        if (standaloneBudgets.isEmpty && !budgetsState.isLoading) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget',
                              style: AppTypography.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 36,
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                physics: const BouncingScrollPhysics(),
                                itemCount: 1 + (budgetsState.isLoading ? 3 : standaloneBudgets.length),
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    final isSelected = _selectedBudgetId == null;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedBudgetId = null),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        height: 36,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                          border: Border.all(
                                            color: isSelected ? AppColors.primary : Colors.transparent,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Tidak ada',
                                            style: AppTypography.textTheme.labelMedium?.copyWith(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white70 : Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final budgetIndex = index - 1;
                                  if (budgetsState.isLoading) {
                                    return _SkeletonChip(isDark: isDark);
                                  }

                                  final budget = standaloneBudgets[budgetIndex] as Map;
                                  final budgetId = budget['id'] as String;
                                  final budgetName = budget['name'] as String? ?? 'Budget';
                                  final budgetEmoji = budget['emojiIcon'] as String? ?? '💰';
                                  final budgetColorHex = budget['colorCode'] as String? ?? '#6C63FF';
                                  final budgetColor = AppColors.colorFromHex(budgetColorHex, fallback: AppColors.primary);
                                  final isSelected = _selectedBudgetId == budgetId;

                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedBudgetId = isSelected ? null : budgetId),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? budgetColor.withValues(alpha: 0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                        border: Border.all(
                                          color: isSelected ? budgetColor : Colors.transparent,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(budgetEmoji, style: const TextStyle(fontSize: 14)),
                                          const SizedBox(width: 6),
                                          Text(
                                            budgetName,
                                            style: AppTypography.textTheme.labelMedium?.copyWith(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? (isDark ? Colors.white : budgetColor) : (isDark ? Colors.white70 : Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }),

                      // ── Title & Notes Area ─────────────────────────────────
                      AppTextField(
                        controller: _noteController,
                        label: l10n.noteOptional,
                        hint: l10n.noteOptional,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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

  void _showTitleInputSheet() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetController = TextEditingController(text: _titleController.text);
    
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
                l10n.transactionTitle,
                style: AppTypography.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: sheetController,
                label: l10n.transactionTitle,
                hint: l10n.transactionTitleHint,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _titleController.text = sheetController.text;
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
                      'Save',
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
    final iconShape = ref.read(categoryIconShapeProvider);
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: Text(
                l10n.selectCategoryAction,
                style: AppTypography.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
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
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        final catColor = AppColors.primary;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push('/manage-categories');
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  alignment: Alignment.center,
                                  decoration: ShapeDecoration(
                                    color: catColor.withValues(alpha: 0.1),
                                    shape: iconShape.toShapeBorder(52),
                                  ),
                                  child: Icon(Icons.add_rounded, color: catColor, size: 28),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.newLabel,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: catColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final cat = filtered[index] as Map;
                      final catId = cat['id'] as String;
                      final catName = cat['name'] as String;
                      final catEmoji = cat['emojiIcon'] as String? ?? '💰';
                      final catColorHex = cat['colorCode'] as String?;
                      final catColor = AppColors.colorFromHex(catColorHex);
                      final isSelected = _selectedCategoryId == catId;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategoryId = catId);
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected ? catColor.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected ? Border.all(color: catColor, width: 1.5) : null,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: ShapeDecoration(
                                  color: catColor.withValues(alpha: 0.18),
                                  shape: iconShape.toShapeBorder(52),
                                ),
                                child: Text(catEmoji, style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                catName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.textTheme.labelSmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? catColor : null,
                                ),
                              ),
                            ],
                          ),
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
    this.title,
    required this.amount,
    required this.currencyCode,
    this.categoryEmoji,
    this.categoryColor,
    required this.type,
    required this.isDark,
    required this.iconShape,
    required this.onCategoryTap,
    required this.onAmountTap,
    required this.onTitleTap,
  });

  final String? title;
  final double amount;
  final String currencyCode;
  final String? categoryEmoji;
  final Color? categoryColor;
  final String type;
  final bool isDark;
  final CategoryIconShape iconShape;
  final VoidCallback onCategoryTap;
  final VoidCallback onAmountTap;
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = type == 'income' ? AppColors.success : AppColors.danger;
    final l10n = AppLocalizations.of(context);
    final displayTitle = (title == null || title!.isEmpty) ? l10n.transactionTitle : title!;

    return Material(
      color: typeColor.withValues(alpha: 0.15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Area (Top)
          InkWell(
            onTap: onTitleTap,
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
                          displayTitle,
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
                // Category Hitbox (Left Side)
                InkWell(
                  onTap: onCategoryTap,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 12.0, bottom: 24.0),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: ShapeDecoration(
                        color: categoryEmoji == null 
                            ? (isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B))
                            : (categoryColor ?? typeColor).withValues(alpha: 0.2),
                        shape: iconShape.toShapeBorder(64),
                      ),
                      child: Center(
                        child: categoryEmoji == null
                            ? null
                            : Text(categoryEmoji!, style: const TextStyle(fontSize: 28)),
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
