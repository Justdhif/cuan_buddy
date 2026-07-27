import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/shared_provider.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/color_picker_sheet.dart';
import '../../../../core/widgets/custom_emoji_picker_sheet.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/user_list_tile.dart';
import 'shared_room_dashboard_screen.dart' show DiscordChannel;

class SharedScreen extends ConsumerStatefulWidget {
  const SharedScreen({super.key});

  @override
  ConsumerState<SharedScreen> createState() => _SharedScreenState();
}

class _SharedScreenState extends ConsumerState<SharedScreen> {
  // _selectedRoomId == null represents Manage Friends mode (Initial Active View)
  String? _selectedRoomId;
  final TextEditingController _friendSearchCtrl = TextEditingController();
  String _friendSearchQuery = '';

  // Category collapsed states
  bool _infoExpanded = true;
  bool _txExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedNotifierProvider.notifier).fetchLobbyData();
    });

    _friendSearchCtrl.addListener(() {
      setState(() {
        _friendSearchQuery = _friendSearchCtrl.text.trim();
      });
      ref
          .read(sharedNotifierProvider.notifier)
          .searchUsers(_friendSearchQuery);
    });
  }

  @override
  void dispose() {
    _friendSearchCtrl.dispose();
    super.dispose();
  }

  void _selectRoom(String? roomId) {
    if (_selectedRoomId == roomId) return;
    setState(() {
      _selectedRoomId = roomId;
    });
    if (roomId != null) {
      ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(roomId, silent: false);
    }
  }

  void _navigateToChannel(String roomId, DiscordChannel channel) {
    context.push(
      '/shared/room/$roomId',
      extra: {'initialChannel': channel},
    ).then((_) {
      ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(roomId, silent: true);
    });
  }

  void _deleteOrLeaveRoom(String roomId) async {
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
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final error = await ref
                  .read(sharedNotifierProvider.notifier)
                  .leaveOrDeleteRoom(roomId);
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
                      role == 'owner'
                          ? l10n.deleteRoomSuccess
                          : l10n.leaveRoomSuccess,
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                setState(() => _selectedRoomId = null);
                ref.read(sharedNotifierProvider.notifier).fetchLobbyData();
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

  void _showEditRoomBottomSheet(Map<String, dynamic> activeRoom) {
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

  void _showInviteMemberBottomSheet(Map<String, dynamic> activeRoom) {
    final state = ref.read(sharedNotifierProvider);
    final List members = activeRoom['members'] ?? [];
    final memberUserIds = members.map((m) => m['userId'] as String).toSet();

    final inviteableFriends = state.friends
        .where((f) => !memberUserIds.contains(f['userId'] as String))
        .toList();

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeRoom['onlyOwnerCanInvite'] == true && activeRoom['role'] != 'owner') {
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
                                    .inviteMember(
                                        activeRoom['id'], friendId);

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

  void _showRoomOptionsSheet(
      BuildContext context, bool isDark, AppLocalizations l10n) {
    AppBottomSheet.show(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.languageCode == 'id' ? 'Opsi Ruangan' : 'Room Options',
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Option 1: Buat Room Baru
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/shared/room-form');
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.languageCode == 'id'
                                  ? 'Buat Room Baru'
                                  : 'Create New Room',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.languageCode == 'id'
                                  ? 'Buat grup keuangan bersama teman'
                                  : 'Create a shared financial room',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Option 2: Gabung Room
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showJoinRoomSheet(context, isDark, l10n);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.meeting_room_rounded,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.languageCode == 'id'
                                  ? 'Gabung Room'
                                  : 'Join Room',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.languageCode == 'id'
                                  ? 'Masukkan UUID / kode akses ruangan'
                                  : 'Enter room UUID to join',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showJoinRoomSheet(
      BuildContext context, bool isDark, AppLocalizations l10n) {
    final codeCtrl = TextEditingController();

    AppBottomSheet.show(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.joinRoomCode,
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.joinRoomCodeSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: codeCtrl,
                hint: l10n.joinRoomCodeHint,
                prefixIcon: const Icon(Icons.key_rounded, size: 20),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final String code = codeCtrl.text.trim();
                  if (code.isEmpty) {
                    AppSnackbar.show(
                      context,
                      title: l10n.error,
                      message: l10n.inviteCodeInvalid,
                      type: SnackbarType.error,
                    );
                    return;
                  }

                  Navigator.pop(context);

                  final error = await ref
                      .read(sharedNotifierProvider.notifier)
                      .joinRoomByCode(code);

                  if (error != null) {
                    if (context.mounted) {
                      AppSnackbar.show(
                        context,
                        title: l10n.error,
                        message: error,
                        type: SnackbarType.error,
                      );
                    }
                  } else {
                    if (context.mounted) {
                      AppSnackbar.show(
                        context,
                        title: l10n.success,
                        message: l10n.languageCode == 'id'
                            ? 'Berhasil bergabung ke ruangan!'
                            : 'Successfully joined room!',
                        type: SnackbarType.success,
                      );
                    }
                  }
                },
                child: Text(
                  l10n.joinRoomCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider);
    final state = ref.watch(sharedNotifierProvider);
    final l10n = AppLocalizations.of(context);

    final activeRoom = state.activeRoom;
    final bool isFriendsMode = _selectedRoomId == null;

    return Scaffold(
      body: Column(
        children: [
          // Header with Profile & Notification icons removed as requested (showActions: false)
          AppScreenHeader(
            title: l10n.sharedSpace,
            isScrolled: false,
            showBackButton: false,
            showActions: false,
          ),
          Expanded(
            child: Row(
              children: [
                // 1. Column 1: Left Room Icon Sidebar Rail
                _buildIconSidebar(context, state, isDark),

                // 2. Column 2: Active View (Manage Friends by default OR Room Channel Navigation)
                Expanded(
                  child: (state.isLoading && state.rooms.isEmpty) ||
                          (state.isRoomLoading && !isFriendsMode)
                      ? _SharedNavigationSkeleton(isDark: isDark)
                      : isFriendsMode
                          ? _buildFriendManagementPanel(context, state, isDark, l10n)
                          : activeRoom != null
                              ? _buildChannelDrawer(context, state, activeRoom, isDark, l10n)
                              : _buildEmptyDrawer(isDark, l10n, state),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: isFriendsMode
          ? Padding(
              padding: const EdgeInsets.only(bottom: 68),
              child: GestureDetector(
                onTap: () => context.push('/shared/friends'),
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
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ─── 1. Left Icon Sidebar Rail (Room Icons & Friends Active Button) ───────────
  Widget _buildIconSidebar(
      BuildContext context, SharedState state, bool isDark) {
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFEEF2F6);
    final activeIndicatorBg = isDark ? Colors.white : AppColors.primary;
    final bool isFriendsSelected = _selectedRoomId == null;

    return Container(
      width: 64,
      color: bg,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Add Room Icon Button at top above Manage Friends
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: InkWell(
                onTap: () => _showRoomOptionsSheet(context, isDark, AppLocalizations.of(context)),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF313338) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Manage Friends Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 4,
                    height: isFriendsSelected ? 32 : 0,
                    decoration: BoxDecoration(
                      color: activeIndicatorBg,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectRoom(null),
                  child: Tooltip(
                    message: AppLocalizations.of(context).manageFriends,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isFriendsSelected
                            ? AppColors.primary
                            : (isDark ? const Color(0xFF313338) : Colors.white),
                        borderRadius: BorderRadius.circular(
                          isFriendsSelected ? 14 : 22,
                        ),
                        boxShadow: isFriendsSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        color: isFriendsSelected ? Colors.white : AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),

          // Rooms List Icons
          if (state.isLoading && state.rooms.isEmpty)
            ...List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Center(
                  child: Shimmer.fromColors(
                    baseColor: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                        : const Color(0xFFE2E8F0),
                    highlightColor: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.8)
                        : const Color(0xFFF8FAFC),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
              );
            })
          else
            ...List.generate(state.rooms.length, (index) {
            final r = state.rooms[index];
            final String id = r['id'] ?? '';
            final String name = r['name'] ?? 'Room';
            final String emoji = r['emojiIcon'] ?? '📁';
            final Color roomColor = AppColors.colorFromHex(
              r['colorCode'],
              fallback: AppColors.primary,
            );
            final bool isSelected = id == _selectedRoomId;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 4,
                      height: isSelected ? 32 : 0,
                      decoration: BoxDecoration(
                        color: activeIndicatorBg,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectRoom(id),
                    child: Tooltip(
                      message: name,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: roomColor,
                          borderRadius: BorderRadius.circular(
                            isSelected ? 14 : 22,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: roomColor.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── 2. Initial Active Panel: Manage Friends ────────────────────────────────
  Widget _buildFriendManagementPanel(
    BuildContext context,
    SharedState state,
    bool isDark,
    AppLocalizations l10n,
  ) {
    // Seamless matching background color
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    final String query = _friendSearchQuery.toLowerCase();
    final filteredFriends = state.friends.where((friend) {
      if (query.isEmpty) return true;
      final String name = (friend['fullName'] ?? friend['username'] ?? friend['email'] ?? '').toString().toLowerCase();
      final String username = (friend['username'] ?? '').toString().toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title & Total Friends Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  l10n.friends,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filteredFriends.length} ${l10n.friends}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar for Friends List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _friendSearchCtrl,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: l10n.languageCode == 'id' ? 'Cari teman...' : 'Search friends...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  suffixIcon: _friendSearchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _friendSearchCtrl.clear();
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Pending Friend Requests Badge if any
          if (state.pendingRequests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${state.pendingRequests.length} ${l10n.languageCode == 'id' ? 'Permintaan Pertemanan' : 'Pending Requests'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/shared/friends'),
                      child: Text(
                        l10n.languageCode == 'id' ? 'Lihat Semua' : 'View All',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Friends List View matching RoomFormScreen UserListTile design
          Expanded(
            child: filteredFriends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          _friendSearchQuery.isNotEmpty
                              ? (l10n.languageCode == 'id'
                                  ? 'Tidak ada teman yang cocok'
                                  : 'No matching friends found')
                              : l10n.noFriendsYet,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _friendSearchQuery.isNotEmpty
                              ? (l10n.languageCode == 'id'
                                  ? 'Coba gunakan kata kunci pencarian yang lain.'
                                  : 'Try using a different search keyword.')
                              : (l10n.languageCode == 'id'
                                  ? 'Tambahkan teman untuk berbagi ruangan transaksi dan budget bersama.'
                                  : 'Add friends to share room transactions and budgets together.'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: filteredFriends.length,
                    itemBuilder: (context, idx) {
                      final friend = filteredFriends[idx];
                      final String name = friend['fullName'] ??
                          friend['username'] ??
                          friend['email'] ??
                          'Friend';
                      final String? username = friend['username'];
                      final avatarUrl = friend['avatar'];

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UserListTile(
                            name: name,
                            username: username,
                            avatarUrl: avatarUrl,
                            listBackground: friend['listBackground'] as String?,
                            isDark: isDark,
                            onTap: () {},
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Room Channel Navigation Drawer ─────────────────────────────────────
  Widget _buildChannelDrawer(
    BuildContext context,
    SharedState state,
    Map<String, dynamic> room,
    bool isDark,
    AppLocalizations l10n,
  ) {
    // Seamless background matching main app background
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final String roomId = room['id'];
    final String rawRoomName = room['name'] ?? 'Room';
    final String cleanRoomName = rawRoomName
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1F9FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1F1E0}-\u{1F1FF}]',
            unicode: true,
          ),
          '',
        )
        .trim();

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Title Header (Clean Title Only, Full Width Border)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanRoomName.isNotEmpty ? cleanRoomName : rawRoomName,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: roomId));
                    AppSnackbar.show(
                      context,
                      title: l10n.languageCode == 'id' ? 'Berhasil' : 'Success',
                      message: l10n.languageCode == 'id'
                          ? 'UUID Room berhasil disalin'
                          : 'Room UUID copied to clipboard',
                      type: SnackbarType.success,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'UUID: $roomId',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.copy_rounded,
                        size: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Clean Channel Navigation List under Categories
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: [
                // ── Circular Quick Action Buttons (Invite Friend, Edit Room, Delete/Leave Room) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
                  child: Row(
                    children: [
                      // 1. Add / Invite Friend Button
                      Tooltip(
                        message: l10n.inviteFriendToRoom,
                        child: InkWell(
                          onTap: () => _showInviteMemberBottomSheet(room),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_add_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 2. Edit Room Button (Owner only)
                      if (room['role'] == 'owner') ...[
                        Tooltip(
                          message: l10n.languageCode == 'id'
                              ? 'Ubah Detail Ruangan'
                              : 'Edit Room Details',
                          child: InkWell(
                            onTap: () => _showEditRoomBottomSheet(room),
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: isDark ? Colors.white70 : Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],

                      // 3. Delete / Leave Room Button
                      Tooltip(
                        message: room['role'] == 'owner'
                            ? (l10n.languageCode == 'id'
                                ? 'Hapus Ruangan'
                                : 'Delete Room')
                            : (l10n.languageCode == 'id'
                                ? 'Keluar dari Ruangan'
                                : 'Leave Room'),
                        child: InkWell(
                          onTap: () => _deleteOrLeaveRoom(roomId),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              room['role'] == 'owner'
                                  ? Icons.delete_outline_rounded
                                  : Icons.exit_to_app_rounded,
                              color: AppColors.danger,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Invite Code Card (Owner: manage | Member: info only) ─────
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
                  child: _buildInviteCodeCard(room, isDark, l10n),
                ),

                // ── Category 1: INFORMASI & SYNC ──────────────────────────
                _buildCategoryHeader(
                  title: l10n.categoryInformation,
                  isExpanded: _infoExpanded,
                  onToggle: () => setState(() => _infoExpanded = !_infoExpanded),
                  isDark: isDark,
                ),
                if (_infoExpanded) ...[
                  _buildChannelNavigationTile(
                    roomId: roomId,
                    channel: DiscordChannel.overview,
                    name: l10n.channelOverviewTitle,
                    isDark: isDark,
                  ),
                  _buildChannelNavigationTile(
                    roomId: roomId,
                    channel: DiscordChannel.members,
                    name: l10n.channelMembersTitle,
                    customTrailing: _ShadcnAvatarGroup(
                      members: (room['members'] as List?) ?? [],
                      isDark: isDark,
                    ),
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 12),

                // ── Category 2: TRANSAKSI & PERENCANAAN ───────────────────────
                _buildCategoryHeader(
                  title: l10n.categoryTransactions,
                  isExpanded: _txExpanded,
                  onToggle: () => setState(() => _txExpanded = !_txExpanded),
                  isDark: isDark,
                ),
                if (_txExpanded) ...[
                  _buildChannelNavigationTile(
                    roomId: roomId,
                    channel: DiscordChannel.transactions,
                    name: l10n.channelTransactionsTitle,
                    badgeCount: state.roomTransactions.length,
                    isDark: isDark,
                  ),
                  _buildChannelNavigationTile(
                    roomId: roomId,
                    channel: DiscordChannel.budget,
                    name: l10n.channelBudgetTitle,
                    badgeCount: state.roomBudgets.length,
                    isDark: isDark,
                  ),
                  _buildChannelNavigationTile(
                    roomId: roomId,
                    channel: DiscordChannel.savings,
                    name: l10n.channelSavingsTitle,
                    badgeCount: state.roomSavings.length,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDrawer(bool isDark, AppLocalizations l10n, SharedState state) {
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Container(
      color: bg,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 56, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Text(
            l10n.noRoomsYet,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.noRoomsYetSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => context.push('/shared/room-form'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.createRoom, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    final color = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: color,
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

  Widget _buildChannelNavigationTile({
    required String roomId,
    required DiscordChannel channel,
    required String name,
    int? badgeCount,
    Widget? customTrailing,
    required bool isDark,
  }) {
    // Soft secondary text color (NOT harsh glaring stark white)
    final textCol = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: InkWell(
        onTap: () => _navigateToChannel(roomId, channel),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.tag_rounded,
                size: 16,
                color: textCol.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textCol,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (customTrailing != null) ...[
                customTrailing,
                const SizedBox(width: 4),
              ] else if (badgeCount != null && badgeCount > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shadcn-Style Overlapping Avatar Group Component ──────────────────────────
class _ShadcnAvatarGroup extends StatelessWidget {
  final List members;
  final bool isDark;

  const _ShadcnAvatarGroup({
    required this.members,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    const int maxVisible = 3;
    const double avatarSize = 22.0;

    final bgBorderColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final int total = members.length;
    final int displayCount = total > maxVisible ? maxVisible : total;
    final int extraCount = total - displayCount;

    final List<Widget> avatarItems = [];

    for (int i = 0; i < displayCount; i++) {
      final m = members[i];
      final String? avatarUrl = m['avatar'];
      final String name =
          (m['fullName'] ?? m['username'] ?? m['email'] ?? 'U').toString();

      avatarItems.add(
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: bgBorderColor, width: 1.5),
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
          child: ClipOval(
            child: UserAvatar(
              size: avatarSize,
              avatarUrl: avatarUrl,
              fallbackName: name,
            ),
          ),
        ),
      );
    }

    if (extraCount > 0) {
      avatarItems.add(
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: bgBorderColor, width: 1.5),
            color: AppColors.primary,
          ),
          child: Center(
            child: Text(
              '+$extraCount',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: avatarSize + 3,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(avatarItems.length, (index) {
          return Align(
            widthFactor: 0.65,
            child: avatarItems[index],
          );
        }),
      ),
    );
  }
}

// ─── Pure Shimmer Skeleton Loader ─────────────────────────────────────────────
class _SharedNavigationSkeleton extends StatelessWidget {
  final bool isDark;
  const _SharedNavigationSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.8)
        : const Color(0xFFF8FAFC);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 24,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 14,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 14,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              2,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCodeCard(Map<String, dynamic> room, bool isDark, AppLocalizations l10n) {
    final String? inviteCode = room['inviteCode'];
    final String? expiresAtStr = room['inviteCodeExpiresAt'];
    final bool isOwner = room['role'] == 'owner';

    DateTime? expiresAt;
    if (expiresAtStr != null) {
      try {
        expiresAt = DateTime.parse(expiresAtStr);
      } catch (_) {}
    }

    final bool isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);
    final String displayCode = inviteCode != null
        ? '${inviteCode.substring(0, 4)}-${inviteCode.substring(4)}'
        : '';

    // Calculate days remaining
    int daysRemaining = 0;
    if (expiresAt != null) {
      daysRemaining = expiresAt.difference(DateTime.now()).inDays;
      if (daysRemaining < 0) daysRemaining = 0;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF3F5FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E4E) : const Color(0xFFE2E8FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                inviteCode == null ? Icons.lock_rounded : Icons.public_rounded,
                size: 14,
                color: inviteCode == null ? Colors.amber : Colors.green,
              ),
              const SizedBox(width: 6),
              Text(
                inviteCode == null ? l10n.roomPrivate : l10n.roomPublic,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            inviteCode == null ? l10n.roomPrivateDesc : l10n.roomPublicDesc,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          if (inviteCode != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Text(
                      isExpired ? 'EXPIRED' : displayCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1.5,
                        color: isExpired
                            ? AppColors.danger
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isExpired)
                  IconButton(
                    onPressed: () {
                      Navigator.of(context); // dummy to ensure context is safe
                      Clipboard.setData(
                        ClipboardData(text: displayCode),
                      );
                      AppSnackbar.show(
                        context,
                        title: l10n.success,
                        message: l10n.inviteCodeCopied,
                        type: SnackbarType.success,
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            if (!isExpired && expiresAt != null) ...[
              const SizedBox(height: 6),
              Text(
                '${l10n.inviteCodeExpiry}: $daysRemaining ${l10n.languageCode == 'id' ? 'hari' : 'days'}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
          if (isOwner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (inviteCode == null || isExpired)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(sharedNotifierProvider.notifier)
                            .generateInviteCode(room['id']);
                      },
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: Text(
                        l10n.generateInviteCode,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  )
                else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.regenerateConfirmTitle),
                            content: Text(l10n.regenerateConfirmMessage),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.languageCode == 'id' ? 'Batal' : 'Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(l10n.languageCode == 'id' ? 'Ya' : 'Yes'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(sharedNotifierProvider.notifier)
                              .generateInviteCode(room['id']);
                        }
                      },
                      icon: const Icon(Icons.sync_rounded, size: 14),
                      label: Text(
                        l10n.regenerateInviteCode,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.deleteInviteCode),
                          content: Text(l10n.deleteInviteCodeConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.languageCode == 'id' ? 'Batal' : 'Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.languageCode == 'id' ? 'Hapus' : 'Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(sharedNotifierProvider.notifier)
                            .deleteInviteCode(room['id']);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                      foregroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

