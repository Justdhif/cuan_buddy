import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/color_picker_sheet.dart';
import '../../../../core/widgets/custom_emoji_picker_sheet.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/shared_provider.dart';
import '../widgets/selected_users_chip_row.dart';

class RoomDetailsScreen extends ConsumerStatefulWidget {
  const RoomDetailsScreen({super.key, required this.selectedFriendIds});

  final List<String> selectedFriendIds;

  @override
  ConsumerState<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends ConsumerState<RoomDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController(text: '📁');

  final List<Color> _presetColors = [
    const Color(0xFF66BB6A),
    const Color(0xFF26A69A),
    const Color(0xFF26C6DA),
    const Color(0xFF42A5F5),
    const Color(0xFF3949AB),
    const Color(0xFF7E57C2),
  ];

  late Color _selectedColor;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = _presetColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim();
    final colorCode = _colorToHex(_selectedColor);

    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(sharedNotifierProvider.notifier);

    final error = await notifier.createRoom(
      name,
      widget.selectedFriendIds,
      emojiIcon: emoji,
      colorCode: colorCode,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (error != null) {
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: error,
          type: SnackbarType.error,
        );
      } else {
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: l10n.createRoomSuccess,
          type: SnackbarType.success,
        );
        if (context.canPop()) context.pop();
        if (context.canPop()) context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final iconShape = ref.watch(categoryIconShapeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final state = ref.watch(sharedNotifierProvider);
    final friendMap = {for (var f in state.friends) f['userId'] as String: f};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.createRoom,
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Emoji and Name
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
                                    : '📁',
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            label: l10n.roomName,
                            hint: l10n.roomNameHint,
                            controller: _nameController,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return l10n.roomNameRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Color Picker
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
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Selected Users Chips (Readonly)
                    if (widget.selectedFriendIds.isNotEmpty) ...[
                      Text(l10n.selectedMembers, style: AppTypography.textTheme.titleSmall),
                      const SizedBox(height: 16),
                      SelectedUsersChipRow(
                        selectedIds: widget.selectedFriendIds,
                        friendMap: friendMap,
                        isDark: isDark,
                        isReadonly: true, // Hides X button
                        contentPadding: EdgeInsets.zero,
                        accentColor: accentColor,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: GestureDetector(
        onTap: _isSaving ? null : _submit,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      ),
                    )
                  : Center(
                      child: Text(
                        l10n.createRoomButton,
                        style:
                            AppTypography.textTheme.titleMedium?.copyWith(
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
