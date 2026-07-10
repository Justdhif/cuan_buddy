import '../../../../core/widgets/custom_emoji_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/widgets/color_picker_sheet.dart';
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
  AppLocalizations get l10n => AppLocalizations.of(context);
  late final TextEditingController _nameController;
  late final TextEditingController _emojiController;
  bool _isLoading = false;

  final List<Color> _presetColors = [
    const Color(0xFF66BB6A),
    const Color(0xFF26A69A),
    const Color(0xFF26C6DA),
    const Color(0xFF42A5F5),
    const Color(0xFF3949AB),
    const Color(0xFF7E57C2),
  ];

  late Color _selectedColor;

  Color _colorFromHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return _presetColors.first;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialCategory?['name']);
    _emojiController = TextEditingController(
        text: widget.initialCategory?['emojiIcon'] ?? '💰');
    _selectedColor =
        _colorFromHex(widget.initialCategory?['colorCode'] as String?);
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
    final colorCode = _colorToHex(_selectedColor);

    if (name.isEmpty || emoji.isEmpty) {
      AppSnackbar.show(
        context,
        title: l10n.info,
        message: l10n.pleaseFillAllFields,
        type: SnackbarType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final notifier = ref.read(categoryNotifierProvider.notifier);
    bool success;

    if (widget.initialCategory == null) {
      success = await notifier.addCategory(name, emoji, colorCode);
    } else {
      await notifier.updateCategory(widget.initialCategory!['id'], {
        'name': name,
        'emojiIcon': emoji,
        'colorCode': colorCode,
      });
      success = true;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      AppSnackbar.show(
        context,
        title: l10n.success,
        message: l10n.categorySaved,
        type: SnackbarType.success,
      );
    } else {
      final error = ref.read(categoryNotifierProvider).error;
      AppSnackbar.show(
        context,
        title: l10n.error,
        message: error ?? l10n.anErrorOccurred,
        type: SnackbarType.error,
      );
    }
  }

  void _showEmojiPicker() {
    CustomEmojiPickerSheet.show(
      context: context,
      onEmojiSelected: (emoji) {
        setState(() {
          _emojiController.text = emoji;
        });
        Navigator.pop(context);
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

  Future<void> _confirmDelete() async {
    if (widget.initialCategory == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text(l10n.deleteCategoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref
        .read(categoryNotifierProvider.notifier)
        .deleteCategory(widget.initialCategory!['id']);

    if (!mounted) return;
    Navigator.pop(context);
    AppSnackbar.show(
      context,
      title: l10n.success,
      message: l10n.deleteCategory,
      type: SnackbarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconShape = ref.watch(categoryIconShapeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialCategory == null ? l10n.newCategory : l10n.editCategory,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.initialCategory != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              onPressed: _confirmDelete,
              tooltip: l10n.deleteCategory,
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _showEmojiPicker();
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: ShapeDecoration(
                          color: _selectedColor,
                          shape: iconShape.toShapeBorder(64),
                        ),
                        child: Center(
                          child: Text(
                            _emojiController.text.isNotEmpty
                                ? _emojiController.text
                                : '💰',
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        label: l10n.categoryName,
                        hint: l10n.categoryNameHint,
                        controller: _nameController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _showColorPicker();
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB3B9D6),
                            shape: BoxShape.circle,
                            border: !_presetColors.contains(_selectedColor)
                                ? Border.all(
                                    color: isDark ? Colors.white : AppColors.primary,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: const Icon(
                            Icons.palette_outlined,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ..._presetColors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            setState(() => _selectedColor = color);
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: isDark ? Colors.white : AppColors.primary,
                                      width: 3,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: _isLoading ? null : _submit,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        widget.initialCategory == null
                            ? l10n.createCategory
                            : l10n.saveChanges,
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
    );
  }
}
