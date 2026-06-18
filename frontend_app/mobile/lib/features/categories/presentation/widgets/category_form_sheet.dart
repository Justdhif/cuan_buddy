import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/category_provider.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({
    super.key,
    this.initialCategory,
  });

  final Map<String, dynamic>? initialCategory;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emojiController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCategory?['name']);
    _emojiController = TextEditingController(text: widget.initialCategory?['emojiIcon'] ?? '💰');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim();

    if (name.isEmpty || emoji.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final notifier = ref.read(categoryNotifierProvider.notifier);
    bool success;

    if (widget.initialCategory == null) {
      success = await notifier.addCategory(name, emoji);
    } else {
      success = await notifier.updateCategory(widget.initialCategory!['slug'], name, emoji);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
    } else {
      final error = ref.read(categoryNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initialCategory == null ? 'New Category' : 'Edit Category',
            style: AppTypography.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: TextField(
                  controller: _emojiController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  maxLength: 2,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppTextField(
                  label: 'Category Name',
                  hint: 'e.g., Food & Dining',
                  controller: _nameController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          AppButton(
            label: widget.initialCategory == null ? 'Create Category' : 'Save Changes',
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
