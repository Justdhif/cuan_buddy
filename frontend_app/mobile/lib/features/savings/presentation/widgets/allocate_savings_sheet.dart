import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/savings_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

void showAllocateSavingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AllocateSavingsSheet(),
  );
}

class _AllocateSavingsSheet extends ConsumerStatefulWidget {
  const _AllocateSavingsSheet();

  @override
  ConsumerState<_AllocateSavingsSheet> createState() =>
      _AllocateSavingsSheetState();
}

class _AllocateSavingsSheetState extends ConsumerState<_AllocateSavingsSheet> {
  final _amountController = TextEditingController();
  String? _selectedGoalId;
  String _selectedCurrency = AppConstants.defaultCurrency;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currency =
          ref.read(profileProvider).valueOrNull?['currency'] as String?;
      if (currency != null) {
        setState(() {
          _selectedCurrency = currency;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedGoalId == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectSavingsGoal)),
      );
      return;
    }

    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountStr.isEmpty) return;

    final amount = double.parse(amountStr);
    if (amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      // 1. Update savings balance
      final goals = ref.read(savingsNotifierProvider).goals;
      final goal = goals.firstWhere(
        (g) => g['id'] == _selectedGoalId,
        orElse: () => <String, dynamic>{},
      );

      if (goal.isNotEmpty) {
        final rawC = goal['currentAmount'];
        final currentAmount = rawC is num
            ? rawC.toDouble()
            : double.tryParse(rawC?.toString() ?? '0') ?? 0;
        final newAmount = currentAmount + amount;
        final goalName = goal['name'] as String? ?? 'Goal';

        await ref
            .read(savingsNotifierProvider.notifier)
            .updateBalance(_selectedGoalId!, newAmount);

        // 2. Create expense transaction
        final categories = await ref.read(categoriesProvider.future);
        final savingsCategory = categories.firstWhere(
          (c) => c['name'].toString().toLowerCase() == 'others',
          orElse: () => null,
        );

        final dio = ref.read(dioClientProvider).dio;
        await dio.post('/transactions', data: {
          'type': 'expense',
          'amount': amount,
          'currency': _selectedCurrency,
          'categoryId': savingsCategory?['id'],
          'note': 'Allocation to $goalName',
          'date': DateTime.now().toUtc().toIso8601String(),
        });

        // Invalidate transaction providers
        ref.invalidate(allTransactionsProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(analyticsSummaryProvider);
        ref.invalidate(financialHealthProvider);
        ref.invalidate(calendarSummaryProvider);
        ref.invalidate(monthlySummaryProvider);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.pop(context);
        AppSnackbar.show(context,
            title: l10n.success,
            message: l10n.allocationSuccessful,
            type: SnackbarType.success);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(context,
            title: l10n.error, message: e.toString(), type: SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savingsState = ref.watch(savingsNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text(
            l10n.allocateToSavings,
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Goal Selection
          DropdownButtonFormField<String>(
            value: _selectedGoalId,
            decoration: InputDecoration(
              labelText: l10n.selectSavingsGoal,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            items: savingsState.goals.map((g) {
              return DropdownMenuItem<String>(
                value: g['id'] as String,
                child: Text(g['name'] as String? ?? l10n.unnamedGoal),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedGoalId = val);
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
                    if (val != null) setState(() => _selectedCurrency = val);
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.amountRequired;
                    }
                    if (double.tryParse(value.replaceAll(',', '')) == null) {
                      return l10n.invalidAmount;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          AppButton(
            label: l10n.allocate,
            onPressed: _submit,
            isLoading: _isLoading,
            type: AppButtonType.primary,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
