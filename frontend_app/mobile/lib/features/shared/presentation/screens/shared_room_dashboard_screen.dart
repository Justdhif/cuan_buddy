import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/shared_provider.dart';
import '../../widgets/transaction_card.dart' as shared_tx;
import '../../widgets/budget_card.dart';
import '../../widgets/savings_goal_card.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/user_list_tile.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/color_picker_sheet.dart';
import '../../../../core/widgets/custom_emoji_picker_sheet.dart';

enum DiscordChannel {
  overview,
  transactions,
  expense,
  income,
  budget,
  savings,
  members,
}

class SharedRoomDashboardScreen extends ConsumerStatefulWidget {
  final String roomId;
  final DiscordChannel initialChannel;
  const SharedRoomDashboardScreen({
    super.key,
    required this.roomId,
    this.initialChannel = DiscordChannel.overview,
  });

  @override
  ConsumerState<SharedRoomDashboardScreen> createState() =>
      _SharedRoomDashboardScreenState();
}

class _SharedRoomDashboardScreenState
    extends ConsumerState<SharedRoomDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(widget.roomId);
      ref.read(sharedNotifierProvider.notifier).fetchFriends(silent: true);
    });
  }

  void _deleteOrLeaveRoom() async {
    final activeRoom = ref.read(sharedNotifierProvider).activeRoom;
    if (activeRoom == null) return;

    final l10n = AppLocalizations.of(context);
    final String role = activeRoom['role'] ?? 'member';
    final String title = role == 'owner' ? l10n.deleteRoom : l10n.leaveRoom;
    final String message = role == 'owner'
        ? l10n.deleteRoomConfirm
        : l10n.leaveRoomConfirm;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final goRouter = GoRouter.of(context);
              Navigator.pop(context);
              final error = await ref
                  .read(sharedNotifierProvider.notifier)
                  .leaveOrDeleteRoom(widget.roomId);
              if (error != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.danger,
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      role == 'owner'
                          ? l10n.deleteRoomSuccess
                          : l10n.leaveRoomSuccess,
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                goRouter.pop();
              }
            },
            child: Text(
              role == 'owner' ? l10n.delete : l10n.logOut,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditRoomBottomSheet() {
    final activeRoom = ref.read(sharedNotifierProvider).activeRoom;
    if (activeRoom == null) return;

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeRoom['role'] != 'owner') {
      AppSnackbar.show(
        context,
        title: l10n.error,
        message: isDark
            ? 'Only the owner can edit room details'
            : 'Hanya pemilik yang dapat mengubah detail ruangan',
        type: SnackbarType.error,
      );
      return;
    }

    final nameCtrl = TextEditingController(text: activeRoom['name'] ?? '');
    final emojiCtrl = TextEditingController(text: activeRoom['emojiIcon'] ?? '📁');
    Color selectedColor = AppColors.colorFromHex(
      activeRoom['colorCode'],
      fallback: AppColors.primary,
    );
    final iconShape = ref.read(categoryIconShapeProvider);
    bool modalOnlyOwnerCanInvite = activeRoom['onlyOwnerCanInvite'] ?? true;

    final presetColors = [
      const Color(0xFF66BB6A),
      const Color(0xFF26A69A),
      const Color(0xFF26C6DA),
      const Color(0xFF42A5F5),
      const Color(0xFF3949AB),
      const Color(0xFF7E57C2),
    ];

    AppBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isDark ? 'Edit Room Details' : 'Ubah Detail Ruangan',
                        style: AppTypography.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              CustomEmojiPickerSheet.show(
                                context: context,
                                onEmojiSelected: (emoji) {
                                  setModalState(() {
                                    emojiCtrl.text = emoji;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: ShapeDecoration(
                                color: selectedColor,
                                shape: iconShape.toShapeBorder(64),
                              ),
                              child: Center(
                                child: Text(
                                  emojiCtrl.text,
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
                              controller: nameCtrl,
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
                              onTap: () async {
                                final newColor = await showCustomColorPicker(
                                  context: context,
                                  initialColor: selectedColor,
                                );
                                if (newColor != null) {
                                  setModalState(() => selectedColor = newColor);
                                }
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB3B9D6),
                                  shape: BoxShape.circle,
                                  border: !presetColors.contains(selectedColor)
                                      ? Border.all(
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.primary,
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
                            ...presetColors.map((color) {
                              final isSelected = selectedColor == color;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() => selectedColor = color);
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
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.primary,
                                            width: 3,
                                          )
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ─── Invite Permission Toggle ─────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E2E)
                              : const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2E2E4E)
                                : const Color(0xFFE2E8FF),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: modalOnlyOwnerCanInvite
                                      ? AppColors.primary
                                          .withValues(alpha: 0.15)
                                      : (isDark
                                          ? const Color(0xFF2C2C3E)
                                          : const Color(0xFFEEF0FF)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  modalOnlyOwnerCanInvite
                                      ? Icons.lock_rounded
                                      : Icons.group_add_rounded,
                                  size: 20,
                                  color: modalOnlyOwnerCanInvite
                                      ? AppColors.primary
                                      : (isDark
                                          ? Colors.white54
                                          : Colors.black45),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.onlyOwnerCanInvite,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      modalOnlyOwnerCanInvite
                                          ? l10n.onlyOwnerCanInviteSubtitle
                                          : l10n.anyMemberCanInviteSubtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch.adaptive(
                                value: modalOnlyOwnerCanInvite,
                                onChanged: (val) {
                                  setModalState(
                                      () => modalOnlyOwnerCanInvite = val);
                                },
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final String newName = nameCtrl.text.trim();
                          if (newName.isEmpty) return;

                          final String hexColor =
                              '#${selectedColor.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';

                          final error = await ref
                              .read(sharedNotifierProvider.notifier)
                              .updateRoom(
                                activeRoom['id'],
                                name: newName,
                                emojiIcon: emojiCtrl.text,
                                colorCode: hexColor,
                                onlyOwnerCanInvite: modalOnlyOwnerCanInvite,
                              );

                          if (context.mounted) {
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
                                message: isDark
                                    ? 'Room updated successfully'
                                    : 'Detail ruangan berhasil diperbarui',
                                type: SnackbarType.success,
                              );
                              Navigator.pop(ctx);
                            }
                          }
                        },
                        child: Text(
                          isDark ? 'Save Changes' : 'Simpan Perubahan',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showInviteMemberBottomSheet() {
    final state = ref.read(sharedNotifierProvider);
    final room = state.activeRoom;
    if (room == null) return;

    final List members = room['members'] ?? [];
    final memberUserIds = members.map((m) => m['userId'] as String).toSet();

    final inviteableFriends = state.friends
        .where((f) => !memberUserIds.contains(f['userId'] as String))
        .toList();

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (room['onlyOwnerCanInvite'] == true && room['role'] != 'owner') {
      AppSnackbar.show(
        context,
        title: l10n.error,
        message: l10n.onlyOwnerCanInviteError,
        type: SnackbarType.error,
      );
      return;
    }

    AppBottomSheet.show(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.inviteFriendToRoom,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (inviteableFriends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        l10n.allFriendsAlreadyInRoom,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: inviteableFriends.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final friend = inviteableFriends[idx];
                          final String friendId = friend['userId'];
                          final String name = friend['fullName'] ??
                              friend['username'] ??
                              friend['email'];
                          final String? username = friend['username'];
                          final avatarUrl = friend['avatar'];
                          final listBackground = friend['listBackground'];

                          return UserListTile(
                            name: name,
                            username: username,
                            avatarUrl: avatarUrl,
                            listBackground: listBackground,
                            isDark: isDark,
                            actionWidget: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () async {
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                final localizations =
                                    Localizations.localeOf(context);
                                Navigator.pop(context);

                                final error = await ref
                                    .read(sharedNotifierProvider.notifier)
                                    .inviteMember(widget.roomId, friendId);

                                if (!mounted) return;
                                if (error != null) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                } else {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations.languageCode == 'id'
                                            ? 'Berhasil mengundang $name'
                                            : 'Successfully invited $name',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                l10n.invite,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addTransaction() {
    context.push(
      '/transactions/form',
      extra: {
        'initialType': 'expense',
        'initialTransaction': {
          'roomId': widget.roomId,
        }
      },
    ).then((_) => ref
        .read(sharedNotifierProvider.notifier)
        .fetchRoomDetails(widget.roomId));
  }

  void _addBudget() {
    context.push(
      '/budgets/form',
      extra: {
        'budget': {
          'roomId': widget.roomId,
        }
      },
    ).then((_) => ref
        .read(sharedNotifierProvider.notifier)
        .fetchRoomDetails(widget.roomId));
  }

  void _addSavingsGoal() {
    context.push(
      '/savings/form',
      extra: {
        'goal': {
          'roomId': widget.roomId,
        }
      },
    ).then((_) => ref
        .read(sharedNotifierProvider.notifier)
        .fetchRoomDetails(widget.roomId));
  }

  Widget? _buildFab() {
    VoidCallback? onTap;
    if (widget.initialChannel == DiscordChannel.transactions ||
        widget.initialChannel == DiscordChannel.expense ||
        widget.initialChannel == DiscordChannel.income) {
      onTap = _addTransaction;
    } else if (widget.initialChannel == DiscordChannel.budget) {
      onTap = _addBudget;
    } else if (widget.initialChannel == DiscordChannel.savings) {
      onTap = _addSavingsGoal;
    }

    if (onTap == null) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 68),
      child: GestureDetector(
        onTap: onTap,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(accentColorProvider);
    final state = ref.watch(sharedNotifierProvider);
    final l10n = AppLocalizations.of(context);

    if (state.isRoomLoading && state.activeRoom == null) {
      return _SharedRoomDashboardSkeleton(isDark: isDark);
    }

    final room = state.activeRoom;
    if (room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.roomNotFound)),
      );
    }

    final profile = ref.watch(profileProvider).valueOrNull;
    final baseCurrency =
        profile?['currency'] as String? ?? AppConstants.defaultCurrency;

    // Dynamic title matching clicked navigation item
    String pageTitle;
    switch (widget.initialChannel) {
      case DiscordChannel.overview:
        pageTitle = l10n.channelOverviewTitle;
        break;
      case DiscordChannel.transactions:
      case DiscordChannel.expense:
      case DiscordChannel.income:
        pageTitle = l10n.channelTransactionsTitle;
        break;
      case DiscordChannel.budget:
        pageTitle = l10n.channelBudgetTitle;
        break;
      case DiscordChannel.savings:
        pageTitle = l10n.channelSavingsTitle;
        break;
      case DiscordChannel.members:
        pageTitle = l10n.channelMembersTitle;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          pageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(sharedNotifierProvider.notifier)
            .fetchRoomDetails(widget.roomId),
        color: AppColors.primary,
        child: _buildChannelBody(
            context, state, room, isDark, l10n, baseCurrency),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildChannelBody(
    BuildContext context,
    SharedState state,
    Map<String, dynamic> room,
    bool isDark,
    AppLocalizations l10n,
    String baseCurrency,
  ) {
    switch (widget.initialChannel) {
      case DiscordChannel.overview:
        return _buildOverviewTab(context, state, room, isDark, l10n, baseCurrency);
      case DiscordChannel.transactions:
      case DiscordChannel.expense:
      case DiscordChannel.income:
        return _buildTransactionsTab(state, isDark, l10n);
      case DiscordChannel.budget:
        return _buildBudgetsTab(state, isDark, l10n, baseCurrency);
      case DiscordChannel.savings:
        return _buildSavingsTab(state, isDark, l10n, baseCurrency);
      case DiscordChannel.members:
        return _buildMembersTab(context, state, room, isDark, l10n);
    }
  }

  // ─── TAB 1: Overview ───────────────────────────────────────────────────────
  Widget _buildOverviewTab(
    BuildContext context,
    SharedState state,
    Map<String, dynamic> room,
    bool isDark,
    AppLocalizations l10n,
    String baseCurrency,
  ) {
    final List members = room['members'] ?? [];
    final Color roomColor =
        AppColors.colorFromHex(room['colorCode'], fallback: AppColors.primary);
    final iconShape = ref.watch(categoryIconShapeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero Room Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                roomColor.withValues(alpha: isDark ? 0.35 : 0.2),
                roomColor.withValues(alpha: isDark ? 0.12 : 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: roomColor.withValues(alpha: isDark ? 0.45 : 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: roomColor.withValues(alpha: 0.25),
                      shape: iconShape.toShapeBorder(54),
                    ),
                    child: Text(
                      room['emojiIcon'] ?? '📁',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room['name'] ?? 'Room',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${members.length} ${l10n.members} • ${room['role'] == 'owner' ? 'Owner' : 'Member'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Members Section
        Text(
          l10n.members,
          style: AppTypography.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 10),
        _buildMemberChipsStack(members, state, room, l10n, isDark),
        const SizedBox(height: 20),

        // Summary Statistics Cards
        _buildSummaryOverviewCards(state, l10n, isDark, baseCurrency),
      ],
    );
  }

  Widget _buildMemberChipsStack(
    List<dynamic> members,
    SharedState state,
    Map<String, dynamic> room,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final bool isOwner = room['role'] == 'owner';

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: members.length + (isOwner ? 1 : 0),
        itemBuilder: (context, index) {
          if (isOwner && index == 0) {
            return GestureDetector(
              onTap: _showInviteMemberBottomSheet,
              child: Container(
                width: 64,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Icon(Icons.person_add_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.addMember,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          }

          final mIndex = isOwner ? index - 1 : index;
          final m = members[mIndex];
          final String name = m['fullName'] ?? m['username'] ?? m['email'] ?? '';
          final avatarUrl = m['avatar'];

          return Container(
            width: 64,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                UserAvatar(
                  size: 50,
                  avatarUrl: avatarUrl,
                  fallbackName: name,
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryOverviewCards(
      SharedState state, AppLocalizations l10n, bool isDark, String baseCurrency) {
    final symbol = AppConstants.getCurrencySymbol(baseCurrency);
    final txCount = state.roomTransactions.length;

    double totalBudgetSpent = 0;
    for (var b in state.roomBudgets) {
      final spent = b['spentAmount'] is num
          ? (b['spentAmount'] as num).toDouble()
          : double.tryParse(b['spentAmount']?.toString() ?? '0') ?? 0.0;
      totalBudgetSpent += spent;
    }

    double totalSavingCurrent = 0;
    for (var s in state.roomSavings) {
      final current = s['currentAmount'] is num
          ? (s['currentAmount'] as num).toDouble()
          : double.tryParse(s['currentAmount']?.toString() ?? '0') ?? 0.0;
      totalSavingCurrent += current;
    }

    return Column(
      children: [
        _buildSummaryRowCard(
          title: l10n.channelTransactionsTitle,
          value: '$txCount',
          icon: Icons.receipt_long_outlined,
          color: AppColors.primary,
          onTap: () => context.pushReplacement(
            '/shared/room/${widget.roomId}',
            extra: {'initialChannel': DiscordChannel.transactions},
          ),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildSummaryRowCard(
          title: l10n.channelBudgetTitle,
          value: CurrencyFormatter.formatAmount(totalBudgetSpent, symbol: symbol),
          icon: Icons.pie_chart_outline_rounded,
          color: const Color(0xFF64FFDA),
          onTap: () => context.pushReplacement(
            '/shared/room/${widget.roomId}',
            extra: {'initialChannel': DiscordChannel.budget},
          ),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildSummaryRowCard(
          title: l10n.channelSavingsTitle,
          value: CurrencyFormatter.formatAmount(totalSavingCurrent, symbol: symbol),
          icon: Icons.savings_outlined,
          color: const Color(0xFFFFB74D),
          onTap: () => context.pushReplacement(
            '/shared/room/${widget.roomId}',
            extra: {'initialChannel': DiscordChannel.savings},
          ),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSummaryRowCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B2D31) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: isDark ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: Transactions ───────────────────────────────────────────────────
  Widget _buildTransactionsTab(
      SharedState state, bool isDark, AppLocalizations l10n) {
    final list = state.roomTransactions;

    if (list.isEmpty) {
      return _buildEmptyState(
        Icons.receipt_long_outlined,
        l10n.noTransactionsYetRoom,
        l10n.noTransactionsYetRoomSubtitle,
        isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final tx = list[idx];
        return shared_tx.TransactionCard(transaction: tx);
      },
    );
  }

  // ─── TAB 3: Budgets ────────────────────────────────────────────────────────
  Widget _buildBudgetsTab(SharedState state, bool isDark,
      AppLocalizations l10n, String baseCurrency) {
    final list = state.roomBudgets;

    if (list.isEmpty) {
      return _buildEmptyState(
        Icons.pie_chart_outline_rounded,
        l10n.noBudgetsYetRoom,
        l10n.noBudgetsYetRoomSubtitle,
        isDark,
      );
    }

    final symbol = AppConstants.getCurrencySymbol(baseCurrency);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final budget = list[idx];
        return BudgetCard(
          budget: budget,
          isDark: isDark,
          currencySymbol: symbol,
          onTap: () => context.push('/budgets/form', extra: {'budget': budget}),
        );
      },
    );
  }

  // ─── TAB 4: Savings Goals ──────────────────────────────────────────────────
  Widget _buildSavingsTab(SharedState state, bool isDark,
      AppLocalizations l10n, String baseCurrency) {
    final list = state.roomSavings;

    if (list.isEmpty) {
      return _buildEmptyState(
        Icons.savings_outlined,
        l10n.noSavingsYetRoom,
        l10n.noSavingsYetRoomSubtitle,
        isDark,
      );
    }

    final symbol = AppConstants.getCurrencySymbol(baseCurrency);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final goal = list[idx];
        return SavingsGoalCard(
          goal: goal,
          isDark: isDark,
          currencySymbol: symbol,
          onTap: () => context.push('/savings/detail', extra: {'goal': goal}),
        );
      },
    );
  }

  // ─── TAB 5: Members ────────────────────────────────────────────────────────
  Widget _buildMembersTab(
    BuildContext context,
    SharedState state,
    Map<String, dynamic> room,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final List members = room['members'] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${members.length} ${l10n.members}',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (room['role'] == 'owner')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showInviteMemberBottomSheet,
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: Text(l10n.addMember),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ...members.map((m) {
          final String name = m['fullName'] ?? m['username'] ?? m['email'] ?? '';
          final String? username = m['username'];
          final String role = m['role'] ?? 'member';
          final avatarUrl = m['avatar'];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B2D31) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                UserAvatar(
                  size: 46,
                  avatarUrl: avatarUrl,
                  fallbackName: name,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (username != null && username.isNotEmpty)
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == 'owner'
                        ? AppColors.warning.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role == 'owner' ? 'Owner' : 'Member',
                    style: TextStyle(
                      color: role == 'owner'
                          ? AppColors.warningDark
                          : AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _deleteOrLeaveRoom,
          icon: const Icon(Icons.exit_to_app_rounded, size: 18),
          label: Text(room['role'] == 'owner' ? l10n.deleteRoom : l10n.leaveRoom),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
      IconData icon, String title, String subtitle, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _SharedRoomDashboardSkeleton extends StatelessWidget {
  final bool isDark;
  const _SharedRoomDashboardSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.8)
        : const Color(0xFFF8FAFC);

    return Scaffold(
      appBar: AppBar(),
      body: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
