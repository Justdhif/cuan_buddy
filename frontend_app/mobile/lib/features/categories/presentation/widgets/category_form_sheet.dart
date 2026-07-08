import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
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
    AppBottomSheet.show(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              setState(() {
                _emojiController.text = emoji.emoji;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconShape = ref.watch(categoryIconShapeProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initialCategory == null
                ? l10n.newCategory
                : l10n.editCategory,
            style: AppTypography.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
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
                    shape: iconShape == CategoryIconShape.circle
                        ? const CircleBorder()
                        : iconShape == CategoryIconShape.squircle
                            ? ContinuousRectangleBorder(borderRadius: BorderRadius.circular(32))
                            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          AppButton(
            label: widget.initialCategory == null
                ? l10n.createCategory
                : l10n.saveChanges,
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
