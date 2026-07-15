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

class _RoomFormScreenState extends ConsumerState<RoomFormScreen>
    with TickerProviderStateMixin {
  int _currentStep = 1;

  // Step 1 states
  // Ordered list: newest selection is at index 0 (shown leftmost)
  List<String> _selectedFriendIds = [];
  final _searchController = TextEditingController();

  // Controls the smooth show/hide of the selected-users section
  late final AnimationController _sectionCtrl;
  late final Animation<double> _sectionFade;

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
    _sectionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _sectionFade = CurvedAnimation(
      parent: _sectionCtrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _sectionCtrl.dispose();
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

  /// Called whenever selection changes to animate the section in/out.
  void _updateSectionVisibility() {
    if (_selectedFriendIds.isNotEmpty) {
      _sectionCtrl.forward();
    } else {
      _sectionCtrl.reverse();
    }
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
                  // ── Animated selected-users section ──────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: FadeTransition(
                      opacity: _sectionFade,
                      child: _selectedFriendIds.isEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSelectedUsersHorizontalList(
                                    state, isDark),
                                Container(
                                  height: 0.5,
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  margin: const EdgeInsets.only(
                                      top: 6, bottom: 2),
                                ),
                              ],
                            ),
                    ),
                  ),
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
                    ? 'Nama atau nama pengguna'
                    : 'Name or username',
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
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSelectedUsersHorizontalList(SharedState state, bool isDark) {
    final friendMap = <String, dynamic>{
      for (final f in state.friends) f['userId'] as String: f,
    };
    return _ChipRow(
      selectedIds: _selectedFriendIds,
      friendMap: friendMap,
      isDark: isDark,
      onRemove: _removeSelectedFriend,
    );
  }

  Widget _buildStep1Members(
      SharedState state, bool isDark, AppLocalizations l10n) {
    final isLoading = state.isLoading && state.friends.isEmpty;

    // ── Skeleton while loading ───────────────────────────────────────────────
    if (isLoading) {
      return _FriendListSkeleton(isDark: isDark);
    }

    // ── True empty (data already fetched, list is genuinely empty) ───────────
    if (state.friends.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: l10n.noFriendsInvite,
      );
    }

    // ── Filter by fullName + username only ────────────────────────────────────
    final query = _searchController.text.trim().toLowerCase();
    final filtered = state.friends.where((friend) {
      final fullName =
          (friend['fullName'] ?? '').toString().toLowerCase();
      final username =
          (friend['username'] ?? '').toString().toLowerCase();
      return fullName.contains(query) || username.contains(query);
    }).toList();

    // ── No search results ────────────────────────────────────────────────────
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

    // ── Animated list ────────────────────────────────────────────────────────
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: ListView.builder(
        key: ValueKey(query), // re-animate when query changes
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

          return _FriendListItem(
            key: ValueKey(friendId),
            index: index,
            friendId: friendId,
            name: name,
            username: friend['username'] as String?,
            avatarUrl: avatarUrl,
            borderAsset: borderAsset,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () {
              if (isSelected) {
                _removeSelectedFriend(friendId);
              } else {
                _addSelectedFriend(friendId);
              }
            },
          );
        },
      ),
    );
  }

  /// Adds a friend to the selection (newest appears leftmost).
  void _addSelectedFriend(String friendId) {
    setState(() {
      _selectedFriendIds = [friendId, ..._selectedFriendIds];
    });
    _updateSectionVisibility();
  }

  /// Removes a friend from the selection.
  void _removeSelectedFriend(String friendId) {
    setState(() {
      _selectedFriendIds =
          _selectedFriendIds.where((id) => id != friendId).toList();
    });
    _updateSectionVisibility();
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
            if (_selectedFriendIds.isNotEmpty) ...[
              Text('Anggota Terpilih', style: AppTypography.textTheme.titleSmall),
              const SizedBox(height: 8),
              _ChipRow(
                selectedIds: _selectedFriendIds,
                friendMap: {for (var f in ref.watch(sharedNotifierProvider).friends) f['userId'] as String: f},
                isDark: isDark,
                onRemove: _removeSelectedFriend,
              ),
              const SizedBox(height: 24),
            ],
            SingleChildScrollView(
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

// ─── Chip Row ─────────────────────────────────────────────────────────────────
/// Horizontal scrollable row of selected-user chips.
/// Each chip uses SizeTransition(axis: horizontal) + FadeTransition so that
/// when a new chip grows in at the left, ALL existing chips slide right
/// naturally via the Row layout — giving every chip a smooth animation.
class _ChipRow extends StatefulWidget {
  const _ChipRow({
    required this.selectedIds,
    required this.friendMap,
    required this.isDark,
    required this.onRemove,
  });

  final List<String> selectedIds;
  final Map<String, dynamic> friendMap;
  final bool isDark;
  final void Function(String id) onRemove;

  @override
  State<_ChipRow> createState() => _ChipRowState();
}

class _ChipRowState extends State<_ChipRow> with TickerProviderStateMixin {
  // Per-chip animation controllers (also tracks chips animating out)
  final Map<String, AnimationController> _ctrls = {};
  // Render list: includes chips currently animating out
  final List<String> _renderIds = [];

  @override
  void initState() {
    super.initState();
    // Pre-populate without animation (screen opens with 0 selected usually)
    for (final id in widget.selectedIds) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 320),
        value: 1.0, // already visible
      );
      _ctrls[id] = ctrl;
      _renderIds.add(id);
    }
  }

  @override
  void didUpdateWidget(_ChipRow old) {
    super.didUpdateWidget(old);

    final oldSet = old.selectedIds.toSet();
    final newSet = widget.selectedIds.toSet();

    // ── Added chips ──────────────────────────────────────────────────────────
    for (final id in widget.selectedIds) {
      if (!oldSet.contains(id)) {
        final ctrl = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
        );
        _ctrls[id] = ctrl;
        // Insert at front to match parent ordering
        setState(() => _renderIds.insert(0, id));
        ctrl.forward();
      }
    }

    // ── Removed chips ────────────────────────────────────────────────────────
    for (final id in old.selectedIds) {
      if (!newSet.contains(id)) {
        _ctrls[id]?.reverse().then((_) {
          if (mounted) {
            setState(() {
              _renderIds.remove(id);
              _ctrls.remove(id)?.dispose();
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108, // Increased slightly to prevent any vertical scroll clipping
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _renderIds.map((id) {
            final ctrl = _ctrls[id]!;
            final friend =
                widget.friendMap[id] as Map<String, dynamic>? ?? {};
            final name = (friend['fullName'] ??
                    friend['username'] ??
                    friend['email'] ??
                    '') as String;
            final avatarUrl = friend['avatar'] as String?;
            final avatarBorderId = friend['avatarBorder'] as String?;
            final borderAsset = borderAssetFromId(avatarBorderId);

            // SizeTransition grows width 0→full (pushes siblings right)
            // FadeTransition fades the content in/out simultaneously
            return SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: ctrl,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
              axis: Axis.horizontal,
              alignment: Alignment.centerLeft, // anchor to the left edge
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: ctrl,
                  curve: Curves.easeOut,
                  reverseCurve: Curves.easeIn,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: AvatarWithBorder(
                                  size: 56,
                                  borderAsset: borderAsset,
                                  avatarUrl: avatarUrl,
                                  fallbackName: name,
                                ),
                              ),
                              // X badge — placed within bounds to avoid SizeTransition clipping
                              Align(
                                alignment: Alignment.bottomRight,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => widget.onRemove(id),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 2, right: 2, top: 8, left: 8),
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: widget.isDark
                                            ? Colors.grey[700]
                                            : Colors.grey[500],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: widget.isDark
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
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Friend List Item (animated) ──────────────────────────────────────────────
/// Individual friend row with a staggered fade+slide-up entrance animation.
class _FriendListItem extends StatefulWidget {
  const _FriendListItem({
    super.key,
    required this.index,
    required this.friendId,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.borderAsset,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final int index;
  final String friendId;
  final String name;
  final String? username;
  final String? avatarUrl;
  final String borderAsset;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_FriendListItem> createState() => _FriendListItemState();
}

class _FriendListItemState extends State<_FriendListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Stagger each item by 40 ms × index (capped at 320 ms)
    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 320));

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                AvatarWithBorder(
                  size: 52,
                  borderAsset: widget.borderAsset,
                  avatarUrl: widget.avatarUrl,
                  fallbackName: widget.name,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username on top with @ prefix, accent color
                      if (widget.username != null &&
                          widget.username!.isNotEmpty) ...[
                        Text(
                          '@${widget.username}',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      // Full name below
                      Text(
                        widget.name,
                        style:
                            AppTypography.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 24,
                  height: 24,
                  decoration: widget.isSelected
                      ? BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        )
                      : BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isDark
                                ? Colors.white30
                                : Colors.black26,
                            width: 2,
                          ),
                        ),
                  child: widget.isSelected
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
        ),
      ),
    );
  }
}

// ─── Friend List Skeleton ──────────────────────────────────────────────────────
/// Shimmer-style placeholder rows while friends are being fetched.
class _FriendListSkeleton extends StatefulWidget {
  const _FriendListSkeleton({required this.isDark});
  final bool isDark;

  @override
  State<_FriendListSkeleton> createState() => _FriendListSkeletonState();
}

class _FriendListSkeletonState extends State<_FriendListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shimmer = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E7EB);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final shimmerColor = Color.lerp(
          base,
          widget.isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF3F4F6),
          _shimmer.value,
        )!;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 88),
          itemCount: 8,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  // Avatar circle placeholder
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username placeholder
                        Container(
                          height: 11,
                          width: 80,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Full name placeholder
                        Container(
                          height: 15,
                          width: 140,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Checkbox placeholder
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
