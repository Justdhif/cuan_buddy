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
import '../providers/savings_provider.dart';

class AddSavingsSheet extends ConsumerStatefulWidget {
  const AddSavingsSheet({super.key});

  @override
  ConsumerState<AddSavingsSheet> createState() => _AddSavingsSheetState();
}

class _AddSavingsSheetState extends ConsumerState<AddSavingsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedCurrency = AppConstants.defaultCurrency;

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.newGoal,
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
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: l10n.goalName,
                  hint: l10n.goalNameHint,
                  validator: (value) {
                    if (value == null || value.isEmpty) return l10n.nameRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // ── Target Amount & Currency ──────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded),
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        controller: _targetAmountController,
                        label: l10n.targetAmount,
                        hint: '0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.amountRequired;
                          if (double.tryParse(value) == null) return l10n.invalidAmount;
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _currentAmountController,
                  label: l10n.initialAmountSaved,
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      AppConstants.getCurrencySymbol(_selectedCurrency),
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                      return l10n.invalidAmount;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                      labelText: l10n.targetDateOptional,
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
                AppButton(
                  label: l10n.saveGoal,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final payload = {
                          'name': _nameController.text,
                          'targetAmount': double.parse(_targetAmountController.text),
                          'currentAmount': _currentAmountController.text.isNotEmpty ? double.parse(_currentAmountController.text) : 0,
                          'currency': _selectedCurrency,
                        };
                        if (_selectedDate != null) {
                          payload['targetDate'] = _selectedDate!.toUtc().toIso8601String();
                        }
                        final dio = ref.read(dioClientProvider).dio;
                        await dio.post('/savings-goals', data: payload);
                        ref.invalidate(savingsNotifierProvider);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          AppSnackbar.show(context, title: l10n.info, message: '${l10n.errorSavingGoal}: $e', type: SnackbarType.info);
                        }
                      }
                    }
                  },
                  type: AppButtonType.primary,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showAddSavingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => const AddSavingsSheet(),
  );
}
