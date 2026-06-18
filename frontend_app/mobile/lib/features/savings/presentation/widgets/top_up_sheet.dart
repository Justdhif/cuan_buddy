import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Balance cannot be negative')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final slug = widget.goal['slug'] as String;
      await ref.read(savingsNotifierProvider.notifier).updateBalance(slug, newAmount);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.show(context, title: 'Success', message: _isAdding ? 'Funds added successfully!' : 'Funds reduced successfully!', type: SnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, title: 'Info', message: e.toString(), type: SnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = widget.goal['name'] as String? ?? 'Goal';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Update $name', style: AppTypography.textTheme.titleMedium),
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
                        'Add Funds',
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
                        'Reduce',
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
              labelText: 'Amount',
              prefixText: 'Rp ',
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
          
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAdding ? AppColors.primary : AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    _isAdding ? 'Add Funds' : 'Reduce Funds',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
