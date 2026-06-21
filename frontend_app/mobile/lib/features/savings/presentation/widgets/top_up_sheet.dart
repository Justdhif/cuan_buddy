import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/savings_provider.dart';

void showTopUpSheet(BuildContext context, Map<String, dynamic> goal) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _TopUpSheet(goal: goal),
  );
}

class _TopUpSheet extends ConsumerStatefulWidget {
  const _TopUpSheet({required this.goal});
  final Map<String, dynamic> goal;

  @override
  ConsumerState<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<_TopUpSheet> {
  final _amountController = TextEditingController();
  bool _isAdding = true; // true = Add, false = Reduce
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountStr.isEmpty) return;

    final amount = double.parse(amountStr);
    if (amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final currentAmount = (widget.goal['currentAmount'] as num?)?.toDouble() ?? 0;
      final newAmount = _isAdding ? currentAmount + amount : currentAmount - amount;
      
      // Prevent negative balance
      if (newAmount < 0) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.balanceCannotBeNegative)),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final id = widget.goal['id'] as String;
      final name = widget.goal['name'] as String? ?? 'Goal';
      await ref.read(savingsNotifierProvider.notifier).updateBalance(id, newAmount);

      // Create a transaction for this savings operation
      try {
        final categories = await ref.read(categoriesProvider.future);
        final savingsCategory = categories.firstWhere(
          (c) => c['id'] == widget.goal['categoryId'],
          orElse: () => null,
        );

        final dio = ref.read(dioClientProvider).dio;
        await dio.post('/transactions', data: {
          'type': _isAdding ? 'expense' : 'income',
          'amount': amount,
          'currency': widget.goal['currency'] ?? AppConstants.defaultCurrency,
          'categoryId': savingsCategory?['id'],
          'note': _isAdding ? 'Transfer ke Tabungan: $name' : 'Tarik dari Tabungan: $name',
          'date': DateTime.now().toUtc().toIso8601String(),
        });

        // Invalidate transaction providers
        ref.invalidate(allTransactionsProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(analyticsSummaryProvider);
        ref.invalidate(financialHealthProvider);
        ref.invalidate(calendarSummaryProvider);
      } catch (e) {
        // Just log the error, don't fail the top-up
        debugPrint('Failed to create savings transaction: $e');
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.pop(context);
        AppSnackbar.show(context, title: l10n.success, message: _isAdding ? l10n.fundsAddedSuccess : l10n.fundsReducedSuccess, type: SnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(context, title: l10n.error, message: e.toString(), type: SnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goalCurrency = widget.goal['currency'] as String? ?? AppConstants.defaultCurrency;
    final currencySymbol = AppConstants.getCurrencySymbol(goalCurrency);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = widget.goal['name'] as String? ?? l10n.unnamedGoal;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.updateGoalTitle(name), style: AppTypography.textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Add or Reduce Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAdding = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isAdding 
                            ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _isAdding
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.addFunds,
                        style: TextStyle(
                          fontWeight: _isAdding ? FontWeight.bold : FontWeight.normal,
                          color: _isAdding 
                              ? AppColors.primary
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAdding = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isAdding 
                            ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_isAdding
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.reduce,
                        style: TextStyle(
                          fontWeight: !_isAdding ? FontWeight.bold : FontWeight.normal,
                          color: !_isAdding 
                              ? AppColors.danger
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Amount Input
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.amount,
              prefixText: '$currencySymbol ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          AppButton(
            label: _isAdding ? l10n.addFunds : l10n.reduceFunds,
            onPressed: _submit,
            isLoading: _isLoading,
            type: _isAdding ? AppButtonType.primary : AppButtonType.danger,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
