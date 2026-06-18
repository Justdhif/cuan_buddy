import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'New Goal',
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
                  label: 'Goal Name',
                  hint: 'e.g. New Car',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _targetAmountController,
                  label: 'Target Amount',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '\$',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Amount is required';
                    if (double.tryParse(value) == null) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _currentAmountController,
                  label: 'Initial Amount Saved (Optional)',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '\$',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                      return 'Invalid amount';
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
                      labelText: 'Target Date (Optional)',
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
                              : 'Select a date',
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
                  label: 'Save Goal',
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await ref.read(savingsNotifierProvider.notifier).createGoal(
                          name: _nameController.text,
                          targetAmount: double.parse(_targetAmountController.text),
                          currentAmount: _currentAmountController.text.isNotEmpty ? double.parse(_currentAmountController.text) : 0,
                          targetDate: _selectedDate?.toUtc().toIso8601String(),
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          AppSnackbar.show(context, title: 'Info', message: 'Error saving goal: $e', type: SnackbarType.info);
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
