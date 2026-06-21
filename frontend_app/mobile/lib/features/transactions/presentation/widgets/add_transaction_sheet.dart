import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

// ─── Add Transaction Sheet ────────────────────────────────────────────────────
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, required this.initialType, this.initialTransaction});
  final String initialType; // 'income' or 'expense'
  final Map<String, dynamic>? initialTransaction;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _allocationAmountController = TextEditingController();
  String? _selectedGoalId;
  late String _type;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = AppConstants.defaultCurrency;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (widget.initialTransaction != null) {
      final tx = widget.initialTransaction!;
      _type = tx['type'] as String? ?? widget.initialType;
      _amountController.text = (tx['amount'] ?? '').toString();
      _noteController.text = tx['note'] as String? ?? '';
      _selectedCategoryId = tx['categoryId'] as String?;
      if (tx['date'] != null) {
        _selectedDate = DateTime.parse(tx['date'] as String).toLocal();
      }
      if (tx['currency'] != null) {
        _selectedCurrency = tx['currency'] as String;
      }
    } else {
      // If we have access to profile provider here, we could set default to user profile currency.
      // But we will handle this by letting user choose or using default IDR.
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _allocationAmountController.dispose();
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
        'type': _type,
        'amount': double.parse(_amountController.text.replaceAll(',', '')),
        'currency': _selectedCurrency,
        'categoryId': _selectedCategoryId,
        'date': _selectedDate.toUtc().toIso8601String(),
      };
      if (_noteController.text.isNotEmpty) {
        payload['note'] = _noteController.text;
      }

      if (widget.initialTransaction != null) {
        final id = widget.initialTransaction!['id'];
        await dio.patch('/transactions/$id', data: payload);
      } else {
        await dio.post('/transactions', data: payload);

        // Handle Savings Allocation for new Income
        if (_type == 'income' && _selectedGoalId != null) {
          final allocAmountStr = _allocationAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
          if (allocAmountStr.isNotEmpty) {
            final allocAmount = double.parse(allocAmountStr);
            if (allocAmount > 0) {
              try {
                // 1. Get current goal balance
                final goals = ref.read(savingsNotifierProvider).goals;
                final goal = goals.firstWhere(
                  (g) => g['id'] == _selectedGoalId,
                  orElse: () => <String, dynamic>{},
                );
                
                if (goal.isNotEmpty) {
                  final currentAmount = (goal['currentAmount'] as num?)?.toDouble() ?? 0;
                  final newAmount = currentAmount + allocAmount;
                  final goalName = goal['name'] as String? ?? 'Goal';
                  
                  // 2. Update goal balance
                  await ref.read(savingsNotifierProvider.notifier).updateBalance(_selectedGoalId!, newAmount);
                  
                  // 3. Create expense transaction
                  final categories = await ref.read(categoriesProvider.future);
                  final savingsCategory = categories.firstWhere(
                    (c) => c['name'].toString().toLowerCase() == 'others',
                    orElse: () => null,
                  );

                  await dio.post('/transactions', data: {
                    'type': 'expense',
                    'amount': allocAmount,
                    'currency': _selectedCurrency,
                    'categoryId': savingsCategory?['id'],
                    'note': 'Alokasi ke Tabungan: $goalName',
                    'date': _selectedDate.toUtc().toIso8601String(),
                  });
                }
              } catch (e) {
                debugPrint('Failed to process savings allocation: $e');
              }
            }
          }
        }
      }

      // Invalidate all relevant providers to refresh data
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(analyticsSummaryProvider);
      ref.invalidate(financialHealthProvider);
      ref.invalidate(calendarSummaryProvider); // New provider
      ref.read(notificationsNotifierProvider.notifier).fetchNotifications();

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.show(context, title: l10n.success, message: l10n.transactionSaved, type: SnackbarType.success);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackbar.show(context, title: l10n.error, message: e.toString(), type: SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _type == 'income' ? AppColors.success : AppColors.danger;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialTransaction != null ? l10n.editTransaction : l10n.addTransaction,
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        label: l10n.amount,
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
                const SizedBox(height: 16),

                // ── Category ────────────────────────────────────────────
                Text(l10n.category, style: AppTypography.textTheme.labelMedium),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  loading: () => _buildCategorySkeletonLoader(isDark),
                  error: (_, __) => Text(
                    l10n.failedToLoadCategories,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                  data: (allCategories) {
                    // Filter by type
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
                          final catEmoji = cat['emojiIcon'] as String? ?? cat['emoji'] as String? ?? '💰';
                          final isSelected = _selectedCategoryId == catId;

                          final catColor = AppColors.colorFromHex(cat['colorCode'] as String?, fallback: typeColor);

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
                                  Text(
                                    catEmoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
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

                // ── Savings Goal Allocation (Income Only) ──────────────────────
                if (_type == 'income' && widget.initialTransaction == null)
                  _buildSavingsAllocationSection(isDark),

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
        ],
      ),
    );
  }

  Widget _buildSavingsAllocationSection(bool isDark) {
    final savingsState = ref.watch(savingsNotifierProvider);
    if (savingsState.goals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Alokasi ke Tabungan (Opsional)', style: AppTypography.textTheme.labelMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGoalId,
          decoration: InputDecoration(
            labelText: 'Pilih Tabungan',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Tidak ada alokasi'),
            ),
            ...savingsState.goals.map((g) {
              return DropdownMenuItem<String>(
                value: g['id'] as String,
                child: Text(g['name'] as String? ?? 'Goal'),
              );
            }),
          ],
          onChanged: (val) {
            setState(() => _selectedGoalId = val);
          },
        ),
        if (_selectedGoalId != null) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _allocationAmountController,
            label: 'Jumlah Alokasi',
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  /// Skeleton loader untuk baris chip kategori
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

  /// Builds a single type tab, identical to the style in _FilterRow
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
