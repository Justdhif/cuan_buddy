import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../providers/shared_provider.dart';

class SharedScreen extends ConsumerStatefulWidget {
  const SharedScreen({super.key});

  @override
  ConsumerState<SharedScreen> createState() => _SharedScreenState();
}

class _SharedScreenState extends ConsumerState<SharedScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedNotifierProvider.notifier).fetchLobbyData();
    });

    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCreateRoomScreen() {
    context.push('/shared/room-form');
  }

  /// Builds the Hero Net Balance Card across all shared rooms
  Widget _buildNetBalanceBanner(bool isDark, TextTheme textTheme, bool isId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E38), const Color(0xFF121324)]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isId ? 'Ringkasan Ruangan' : 'Room Summary',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatAmount(0, symbol: 'Rp', decimalPrecision: 0),
                      style: textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF64FFDA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatAmount(0, symbol: 'Rp', decimalPrecision: 0),
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFFF8A80),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds Quick Actions row (New Room, Friends)
  Widget _buildQuickActionsRow(bool isDark, AppLocalizations l10n, bool isId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              isDark: isDark,
              icon: Icons.add_home_work_rounded,
              label: isId ? 'Room Baru' : 'New Room',
              color: AppColors.primary,
              onTap: _showCreateRoomScreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(
              isDark: isDark,
              icon: Icons.people_alt_rounded,
              label: l10n.manageFriends,
              color: const Color(0xFF00B4D8),
              onTap: () => context.push('/shared/friends'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds member avatar stack snippet for each room card
  Widget _buildMemberAvatarStack(List<dynamic> members) {
    if (members.isEmpty) return const SizedBox.shrink();

    final displayMembers = members.take(3).toList();
    final remainingCount = members.length > 3 ? members.length - 3 : 0;

    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: (displayMembers.length * 18.0) + 12,
            child: Stack(
              children: [
                for (int i = 0; i < displayMembers.length; i++)
                  Positioned(
                    left: i * 18.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: UserAvatar(
                        size: 24,
                        fallbackName: displayMembers[i]['name'] ?? displayMembers[i]['username'] ?? 'U',
                        avatarUrl: displayMembers[i]['avatar'],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (remainingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+$remainingCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(sharedNotifierProvider);
    final textTheme = AppTypography.textTheme;
    final l10n = AppLocalizations.of(context);
    final isId = l10n.languageCode == 'id';

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
                // ── Top spacing for AppScreenHeader ─────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.top + 54),
                ),

                // ── Hero Net Balance Summary Banner ─────────────────────────────
                SliverToBoxAdapter(
                  child: _buildNetBalanceBanner(isDark, textTheme, isId),
                ),

                // ── Quick Actions Row ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildQuickActionsRow(isDark, l10n, isId),
                ),

                // ── Section Title ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isId ? 'Daftar Ruangan' : 'Room List',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          '${state.rooms.length} ${isId ? 'Ruangan' : 'Rooms'}',
                          style: textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (state.isLoading)
                  const _SharedRoomListSkeleton()
                else if (state.rooms.isEmpty)
                  SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: viewportHeight * 0.5),
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
                          onPressed: _showCreateRoomScreen,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(
                            isId ? 'Room Baru' : 'New Room',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final room = state.rooms[index];
                          final String name = room['name'] ?? 'Room';
                          final int membersCount = room['membersCount'] ?? 1;
                          final String role = room['role'] ?? 'member';
                          final String emoji = room['emojiIcon'] ?? '📁';
                          final String colorHex = room['colorCode'] ?? '#6C63FF';
                          final List members = room['members'] is List ? room['members'] : [];
                          final Color roomColor = AppColors.colorFromHex(colorHex, fallback: AppColors.primary);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                context.push('/shared/room/${room['id']}');
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Squircle Emoji Container with soft glow
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: ShapeDecoration(
                                            color: roomColor.withValues(alpha: 0.15),
                                            shape: ref.read(categoryIconShapeProvider).toShapeBorder(52),
                                          ),
                                          child: Center(
                                            child: Text(
                                              emoji,
                                              style: const TextStyle(fontSize: 26),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: role == 'owner'
                                                          ? AppColors.warning.withValues(alpha: 0.18)
                                                          : AppColors.primary.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      role == 'owner' ? 'Owner' : (isId ? 'Anggota' : 'Member'),
                                                      style: TextStyle(
                                                        color: role == 'owner' ? AppColors.warningDark : AppColors.primary,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.people_outline_rounded,
                                                    size: 14,
                                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$membersCount ${isId ? 'Anggota' : 'Members'}',
                                                    style: textTheme.bodySmall?.copyWith(
                                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Avatar Stack or Member summary
                                        members.isNotEmpty
                                            ? _buildMemberAvatarStack(members)
                                            : Row(
                                                children: [
                                                  Icon(Icons.group, size: 16, color: AppColors.primary),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    isId ? 'Ruangan Bersama' : 'Shared Room',
                                                    style: textTheme.bodySmall?.copyWith(
                                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppColors.surfaceDark
                                                    : AppColors.backgroundLight,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                                ),
                                              ),
                                              child: Text(
                                                isId ? 'Aktif' : 'Active',
                                                style: textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                                            ),
                                          ],
                                        ),
                                      ],
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
                    child: SizedBox(height: 32),
                  ),
                ],
              ],
            ),
          ),
          // ── Fixed AppScreenHeader ──────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppScreenHeader(
              title: l10n.sharedSpace,
              isScrolled: _scrollOffset > 15,
              showBackButton: false,
              showActions: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedRoomListSkeleton extends StatelessWidget {
  const _SharedRoomListSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.8)
        : const Color(0xFFF8FAFC);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: 16,
                                      width: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    Container(
                                      height: 16,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 12,
                                  width: 84,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 1,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 24,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: 3,
        ),
      ),
    );
  }
}




