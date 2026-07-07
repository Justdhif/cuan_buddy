import '../../../../core/utils/app_snackbar.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
import '../../../../core/widgets/color_picker_sheet.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../providers/savings_provider.dart';

class SavingsFormScreen extends ConsumerStatefulWidget {
  const SavingsFormScreen({super.key, this.goal});
  final Map<String, dynamic>? goal;

  @override
  ConsumerState<SavingsFormScreen> createState() => _SavingsFormScreenState();
}

class _SavingsFormScreenState extends ConsumerState<SavingsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedCurrency = AppConstants.defaultCurrency;
  String _selectedEmoji = '🎯';
  Color _selectedColor = AppColors.primary;
  bool _isSaving = false;

  Color _colorFromHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.primary;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    final argb = color.toARGB32();
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!['name'] ?? '';
      _selectedEmoji = widget.goal!['emojiIcon'] as String? ?? '🎯';
      _selectedColor = _colorFromHex(widget.goal!['colorCode'] as String?);

      final rawT = widget.goal!['targetAmount'];
      final targetAmount = rawT is num
          ? rawT.toDouble()
          : double.tryParse(rawT?.toString() ?? '0') ?? 0;
      _targetAmountController.text = targetAmount.toStringAsFixed(0);

      _selectedCurrency =
          widget.goal!['currency'] ?? AppConstants.defaultCurrency;

      final targetDateStr = widget.goal!['targetDate']?.toString();
      if (targetDateStr != null) {
        _selectedDate = DateTime.tryParse(targetDateStr);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  void _showEmojiPicker() {
    AppBottomSheet.show(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              setState(() {
                _selectedEmoji = emoji.emoji;
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _showColorPicker() async {
    final newColor = await showCustomColorPicker(
      context: context,
      initialColor: _selectedColor,
    );
    if (newColor != null) {
      setState(() => _selectedColor = newColor);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'name': _nameController.text,
        'emojiIcon': _selectedEmoji,
        'colorCode': _colorToHex(_selectedColor),
        'targetAmount': double.parse(_targetAmountController.text),
        'currency': _selectedCurrency,
      };
      if (_selectedDate != null) {
        payload['targetDate'] = _selectedDate!.toUtc().toIso8601String();
      }
      final dio = ref.read(dioClientProvider).dio;
      if (widget.goal == null) {
        await dio.post('/goals', data: payload);
        ref.invalidate(savingsNotifierProvider);
        if (mounted) {
          context.pop();
          AppSnackbar.show(context,
              title: l10n.success,
              message: l10n.goalSavedSuccess,
              type: SnackbarType.success);
        }
      } else {
        await dio.patch('/goals/${widget.goal!['id']}', data: payload);
        ref.invalidate(savingsNotifierProvider);
        if (mounted) {
          context.pop();
          AppSnackbar.show(context,
              title: l10n.success,
              message: 'Goal updated successfully', // You might want to localize this in the future
              type: SnackbarType.success);
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackbar.show(context,
            title: l10n.error,
            message: e.toString(),
            type: SnackbarType.error);
      }
    }
  }

  Future<void> _confirmAndDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteGoal),
        content: Text(l10n.deleteGoalConfirm),
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
        await ref
            .read(savingsNotifierProvider.notifier)
            .deleteGoal(widget.goal!['id']);
        if (mounted) {
          context.pop();
          AppSnackbar.show(
            context,
            title: l10n.success,
            message: 'Goal deleted successfully',
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
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.goal == null ? l10n.newGoal : l10n.editGoal,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.goal != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              onPressed: _confirmAndDelete,
              tooltip: l10n.deleteGoal,
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
                // ── Icon & Color Row ─────────────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _showEmojiPicker();
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _selectedColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _selectedColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _showColorPicker();
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _nameController,
                        label: l10n.goalName,
                        hint: l10n.goalNameHint,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.nameRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Target Amount & Currency ──────────────────────────────────────────
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
                        controller: _targetAmountController,
                        label: l10n.targetAmount,
                        hint: '0',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.amountRequired;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.invalidAmount;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Target Date ────────────────────────────────────────
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ??
                          DateTime.now().add(const Duration(days: 30)),
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
                          _selectedDate != null
                              ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                              : l10n.selectDate,
                          style: AppTypography.textTheme.bodyLarge?.copyWith(
                            color: _selectedDate == null
                                ? (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight)
                                : null,
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // ── Save Button ────────────────────────────────────────
                AppButton(
                  label: l10n.saveGoal,
                  onPressed: _save,
                  type: AppButtonType.primary,
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
}
