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
import '../../../../core/widgets/custom_emoji_picker_sheet.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../providers/shared_provider.dart';
import '../../../profile/presentation/widgets/avatar_border_helper.dart';

class RoomFormScreen extends ConsumerStatefulWidget {
  const RoomFormScreen({super.key});

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  int _currentStep = 1;

  // Step 1 states
  final List<String> _selectedFriendIds = [];
  final _searchController = TextEditingController();

  // Step 2 states
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
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
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
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
    final description = _descriptionController.text.trim();
    final colorCode = _colorToHex(_selectedColor);

    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(sharedNotifierProvider.notifier);

    final error = await notifier.createRoom(
      name,
      _selectedFriendIds,
      emojiIcon: emoji,
      colorCode: colorCode,
      description: description.isNotEmpty ? description : null,
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
        Navigator.pop(context);
      }
    }
  }

  void _goToStep2() {
    if (_selectedFriendIds.isEmpty) {
      final l10n = AppLocalizations.of(context);
      AppSnackbar.show(
        context,
        title: l10n.info,
        message: l10n.noFriendsInvite,
        type: SnackbarType.warning,
      );
      return;
    }
    setState(() {
      _currentStep = 2;
    });
  }

  void _goBack() {
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(sharedNotifierProvider);
    final l10n = AppLocalizations.of(context);
    final iconShape = ref.watch(categoryIconShapeProvider);

    return Scaffold(
      resizeToAvoidBottomInset: _currentStep == 2,
      appBar: _currentStep == 2
          ? AppBar(
              title: Text(
                l10n.createRoom,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _goBack,
              ),
            )
          : null,
      body: _currentStep == 1
          ? SafeArea(
              child: Column(
                children: [
                  _buildCustomHeader(isDark, l10n),
                  if (_selectedFriendIds.isNotEmpty) ...[
                    _buildSelectedUsersHorizontalList(state, isDark),
                    Container(
                      height: 0.5,
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                    ),
                  ],
                  Expanded(
                    child: _buildStep1Members(state, isDark, l10n),
                  ),
                ],
              ),
            )
          : _buildStep2Details(isDark, l10n, iconShape),
      floatingActionButton: _currentStep == 1
          ? FloatingActionButton(
              onPressed: _goToStep2,
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : null,
      bottomNavigationBar: _currentStep == 2
          ? GestureDetector(
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
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
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
            )
          : null,
    );
  }

  Widget _buildCustomHeader(bool isDark, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _goBack,
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: Localizations.localeOf(context).languageCode == 'id'
                    ? 'Nama, nomor, nama pengguna'
                    : 'Name, username, or email',
                hintStyle: TextStyle(
                  color:
                      isDark ? AppColors.textHintDark : AppColors.textHintLight,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 15,
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.dialpad_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSelectedUsersHorizontalList(SharedState state, bool isDark) {
    final selectedFriends = state.friends.where((friend) {
      return _selectedFriendIds.contains(friend['userId']);
    }).toList();

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: selectedFriends.length,
        itemBuilder: (context, index) {
          final friend = selectedFriends[index];
          final friendId = friend['userId'];
          final name =
              friend['fullName'] ?? friend['username'] ?? friend['email'] ?? '';
          final avatarUrl = friend['avatar'];
          final avatarBorderId = friend['avatarBorder'] as String?;
          final borderAsset = borderAssetFromId(avatarBorderId);

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 60,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AvatarWithBorder(
                        size: 56,
                        borderAsset: borderAsset,
                        avatarUrl: avatarUrl,
                        fallbackName: name,
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFriendIds.remove(friendId);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[400],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep1Members(
      SharedState state, bool isDark, AppLocalizations l10n) {
    if (state.friends.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: l10n.noFriendsInvite,
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = state.friends.where((friend) {
      final name =
          (friend['fullName'] ?? friend['username'] ?? friend['email'] ?? '')
              .toString()
              .toLowerCase();
      return name.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: Localizations.localeOf(context).languageCode == 'id'
            ? 'Tidak ada teman ditemukan'
            : 'No friends found',
        subtitle: Localizations.localeOf(context).languageCode == 'id'
            ? 'Coba cari dengan kata kunci lain'
            : 'Try searching with another keyword',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final friend = filtered[index];
        final String friendId = friend['userId'];
        final String name =
            friend['fullName'] ?? friend['username'] ?? friend['email'];
        final bool isSelected = _selectedFriendIds.contains(friendId);
        final avatarUrl = friend['avatar'];
        final avatarBorderId = friend['avatarBorder'] as String?;
        final borderAsset = borderAssetFromId(avatarBorderId);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedFriendIds.remove(friendId);
              } else {
                _selectedFriendIds.add(friendId);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                AvatarWithBorder(
                  size: 52,
                  borderAsset: borderAsset,
                  avatarUrl: avatarUrl,
                  fallbackName: name,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (friend['email'] != null &&
                          (friend['email'] as String).isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          friend['email'],
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 24,
                  height: 24,
                  decoration: isSelected
                      ? const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        )
                      : BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white30 : Colors.black26,
                            width: 2,
                          ),
                        ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep2Details(
      bool isDark, AppLocalizations l10n, CategoryIconShape iconShape) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
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
            AppTextField(
              label: 'Deskripsi',
              hint: 'Masukkan deskripsi ruang...',
              controller: _descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(l10n.budgetColor, style: AppTypography.textTheme.titleSmall),
            const SizedBox(height: 12),
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
                                color:
                                    isDark ? Colors.white : AppColors.primary,
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
                                  color:
                                      isDark ? Colors.white : AppColors.primary,
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
          ],
        ),
      ),
    );
  }
}
