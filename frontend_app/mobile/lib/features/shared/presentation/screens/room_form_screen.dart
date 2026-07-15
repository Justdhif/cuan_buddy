import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/shared_provider.dart';
import '../../../profile/presentation/widgets/avatar_border_helper.dart';
import 'package:go_router/go_router.dart';
import '../widgets/selected_users_chip_row.dart';

class RoomFormScreen extends ConsumerStatefulWidget {
  const RoomFormScreen({super.key});

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen>
    with TickerProviderStateMixin {
  // Step 1 states
  // Ordered list: newest selection is at index 0 (shown leftmost)
  List<String> _selectedFriendIds = [];
  final _searchController = TextEditingController();

  // Controls the smooth show/hide of the selected-users section
  late final AnimationController _sectionCtrl;
  late final Animation<double> _sectionFade;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(sharedNotifierProvider);
    final l10n = AppLocalizations.of(context);
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      body: SafeArea(
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
                          _buildSelectedUsersHorizontalList(state, isDark, accentColor),
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
      ),
      floatingActionButton: _selectedFriendIds.isEmpty
          ? null
          : GestureDetector(
              onTap: () {
                context.push('/shared/room-details', extra: _selectedFriendIds);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
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
                  size: 32,
                ),
              ),
            ),
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
                hintText: l10n.nameOrUsername,
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

  Widget _buildSelectedUsersHorizontalList(SharedState state, bool isDark, Color? accentColor) {
    final friendMap = <String, dynamic>{
      for (final f in state.friends) f['userId'] as String: f,
    };
    return SelectedUsersChipRow(
      selectedIds: _selectedFriendIds,
      friendMap: friendMap,
      isDark: isDark,
      accentColor: accentColor,
      onRemove: _removeSelectedFriend,
    );
  }

  Widget _buildStep1Members(
      SharedState state, bool isDark, AppLocalizations l10n) {
    final isLoading = state.isLoading && state.friends.isEmpty;

    if (isLoading) {
      return _FriendListSkeleton(isDark: isDark);
    }

    if (state.friends.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: l10n.noFriendsInvite,
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = state.friends.where((friend) {
      final fullName =
          (friend['fullName'] ?? '').toString().toLowerCase();
      final username =
          (friend['username'] ?? '').toString().toLowerCase();
      return fullName.contains(query) || username.contains(query);
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: ListView.builder(
        key: ValueKey(query),
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

  void _addSelectedFriend(String friendId) {
    setState(() {
      _selectedFriendIds = [friendId, ..._selectedFriendIds];
    });
    _updateSectionVisibility();
  }

  void _removeSelectedFriend(String friendId) {
    setState(() {
      _selectedFriendIds =
          _selectedFriendIds.where((id) => id != friendId).toList();
    });
    _updateSectionVisibility();
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
