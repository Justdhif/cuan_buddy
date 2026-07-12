import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../providers/shared_provider.dart';

class SharedScreen extends ConsumerStatefulWidget {
  const SharedScreen({super.key});

  @override
  ConsumerState<SharedScreen> createState() => _SharedScreenState();
}

class _SharedScreenState extends ConsumerState<SharedScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Speed-dial FAB state
  bool _fabOpen = false;
  late AnimationController _fabController;
  late Animation<double> _fade1, _fade2;
  late Animation<Offset> _slide1, _slide2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedNotifierProvider.notifier).fetchLobbyData();
    });

    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fade1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _fade2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    _slide1 = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slide2 = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _fabController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _fabOpen = !_fabOpen;
      if (_fabOpen) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  void _showCreateRoomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateRoomSheet(),
    );
  }

  Widget _buildSubFab({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Animation<double> fadeAnim,
    required Animation<Offset> slideAnim,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: IgnorePointer(
          ignoring: !_fabOpen,
          child: Tooltip(
            message: tooltip,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(sharedNotifierProvider);
    final textTheme = AppTypography.textTheme;
    final l10n = AppLocalizations.of(context);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final viewportHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        80;

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(sharedNotifierProvider.notifier).fetchLobbyData(),
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              controller: _scrollController,
              slivers: [
                // ── Hero header scrolls naturally with the page ─────────────
                SliverToBoxAdapter(
                  child: _SharedHeroHeader(isDark: isDark),
                ),

                if (state.isLoading)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (state.rooms.isEmpty)
                  SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: viewportHeight),
                      child: AppEmptyState(
                        icon: Icons.group_outlined,
                        title: l10n.noRoomsYet,
                        subtitle: l10n.noRoomsYetSubtitle,
                        action: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _showCreateRoomSheet,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(
                            l10n.createRoom,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final room = state.rooms[index];
                          final String name = room['name'] ?? 'Room';
                          final int membersCount = room['membersCount'] ?? 1;
                          final String role = room['role'] ?? 'member';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                context.push('/shared/room/${room['id']}');
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.forum_outlined,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.people_outline,
                                                size: 14,
                                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$membersCount ${l10n.members}',
                                                style: textTheme.bodySmall?.copyWith(
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: role == 'owner'
                                                      ? AppColors.warning.withValues(alpha: 0.2)
                                                      : AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  role == 'owner' ? 'Owner' : 'Member',
                                                  style: TextStyle(
                                                    color: role == 'owner' ? AppColors.warningDark : AppColors.primary,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: state.rooms.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120), // Bottom padding for FAB
                  ),
                ],
              ],
            ),
          ),
          // ── Pinned AppBar Background (appears on scroll) ─────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Builder(builder: (context) {
              final t = (_scrollOffset / 60).clamp(0.0, 1.0);
              return Opacity(
                opacity: t,
                child: Container(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  color: bgColor,
                ),
              );
            }),
          ),
          // ── Floating animated title (moves from hero to AppBar) ──────────────
          _buildFloatingTitle(context, l10n, isDark, bgColor),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sub 2: Manage Friends (topmost)
          _buildSubFab(
            icon: Icons.person_add_rounded,
            tooltip: l10n.manageFriends,
            onTap: () {
              _toggleFab();
              context.push('/shared/friends');
            },
            fadeAnim: _fade2,
            slideAnim: _slide2,
          ),
          const SizedBox(height: 12),
          // Sub 1: Create Room (middle)
          _buildSubFab(
            icon: Icons.add_home_work_rounded,
            tooltip: l10n.createRoom,
            onTap: () {
              _toggleFab();
              _showCreateRoomSheet();
            },
            fadeAnim: _fade1,
            slideAnim: _slide1,
          ),
          const SizedBox(height: 16),
          // Main FAB
          GestureDetector(
            onTap: _toggleFab,
            child: AnimatedBuilder(
              animation: _fabController,
              builder: (ctx, child) => Transform.rotate(
                angle: _fabController.value * 0.785398, // 45 degrees
                child: child,
              ),
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
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTitle(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    Color bgColor,
  ) {
    final statusBarH = MediaQuery.of(context).padding.top;
    const appBarH = kToolbarHeight;
    final heroTitleY = statusBarH + 12.0 + 8.0 + 14.0;
    final appBarTitleY = statusBarH + appBarH / 2.0 - 13.0;
    final travelDist = heroTitleY - appBarTitleY;

    final t = (_scrollOffset / travelDist.abs()).clamp(0.0, 1.0);
    var currentY = lerpDouble(heroTitleY, appBarTitleY, t)!;

    if (_scrollOffset < 0) {
      currentY -= _scrollOffset;
    }

    final heroSize = AppTypography.textTheme.headlineMedium?.fontSize ?? 28.0;
    final appBarSize = AppTypography.textTheme.titleLarge?.fontSize ?? 22.0;
    final currentSize = lerpDouble(heroSize, appBarSize, t)!;

    return Positioned(
      top: currentY,
      left: 24.0,
      right: 120.0,
      child: Row(
        children: [
          Expanded(
            child: IgnorePointer(
              child: Text(
                l10n.sharedSpace,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: currentSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTypography.textTheme.headlineMedium?.fontFamily,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


}

class _SharedHeroHeader extends StatelessWidget {
  const _SharedHeroHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: 0,
                    child: Text(
                      l10n.sharedSpace,
                      style: AppTypography.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.friendsInviteDescription,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right illustration
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Center main – people icon
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.people_rounded, color: Colors.purple, size: 26),
                    ),
                  ),
                  // Top-right – forum
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forum_rounded, color: Colors.blue, size: 16),
                    ),
                  ),
                  // Bottom-left – savings
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.savings_rounded, color: Colors.green, size: 15),
                    ),
                  ),
                  // Top-left – wallet
                  Positioned(
                    left: 2,
                    top: 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.orange, size: 13),
                    ),
                  ),
                  // Bottom-right – pie chart
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pie_chart_rounded, color: Colors.red, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _CreateRoomSheet extends ConsumerStatefulWidget {
  const _CreateRoomSheet();

  @override
  ConsumerState<_CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends ConsumerState<_CreateRoomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<String> _selectedFriendIds = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(sharedNotifierProvider.notifier);
    final error = await notifier.createRoom(
      _nameController.text.trim(),
      _selectedFriendIds,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.danger),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.createRoomSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(sharedNotifierProvider);
    final textTheme = AppTypography.textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.createRoom,
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.roomName,
                hintText: l10n.roomNameHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.roomNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              l10n.inviteFriends,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            state.friends.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          l10n.noFriendsInvite,
                          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/shared/friends');
                          },
                          child: Text(l10n.searchFriendsAction),
                        )
                      ],
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.friends.length,
                      itemBuilder: (context, index) {
                        final friend = state.friends[index];
                        final String friendId = friend['userId'];
                        final String name = friend['fullName'] ?? friend['username'] ?? friend['email'];
                        final bool isSelected = _selectedFriendIds.contains(friendId);

                        return CheckboxListTile(
                          title: Text(name),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedFriendIds.add(friendId);
                              } else {
                                _selectedFriendIds.remove(friendId);
                              }
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      l10n.createRoomButton,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
