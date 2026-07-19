import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/shared_provider.dart';
import '../../widgets/transaction_card.dart' as shared_tx;
import '../../../profile/presentation/widgets/avatar_border_helper.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/color_picker_sheet.dart';
import '../../../../core/widgets/custom_emoji_picker_sheet.dart';

class SharedRoomDashboardScreen extends ConsumerStatefulWidget {
  final String roomId;
  const SharedRoomDashboardScreen({super.key, required this.roomId});

  @override
  ConsumerState<SharedRoomDashboardScreen> createState() => _SharedRoomDashboardScreenState();
}

class _SharedRoomDashboardScreenState extends ConsumerState<SharedRoomDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _summaryPageController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB action
    });
    _summaryPageController = PageController(viewportFraction: 0.92);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(widget.roomId);
      ref.read(sharedNotifierProvider.notifier).fetchFriends(silent: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _summaryPageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
              final error = await ref.read(sharedNotifierProvider.notifier).leaveOrDeleteRoom(widget.roomId);
              if (error != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: AppColors.danger),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(role == 'owner' ? l10n.deleteRoomSuccess : l10n.leaveRoomSuccess),
                    backgroundColor: AppColors.success,
                  ),
                );
                goRouter.pop(); // Return to lobby
              }
            },
            child: Text(role == 'owner' ? l10n.delete : l10n.logOut, style: const TextStyle(color: Colors.white)),
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
    Color selectedColor = AppColors.colorFromHex(activeRoom['colorCode'], fallback: AppColors.primary);
    final iconShape = ref.read(categoryIconShapeProvider);

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

                          final String hexColor = '#${selectedColor.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';

                          final error = await ref.read(sharedNotifierProvider.notifier).updateRoom(
                            activeRoom['id'],
                            name: newName,
                            emojiIcon: emojiCtrl.text,
                            colorCode: hexColor,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  void _onFabPressed() {
    final activeRoom = ref.read(sharedNotifierProvider).activeRoom;
    if (activeRoom == null) return;

    if (_tabController.index == 0) {
      // Add Shared Transaction
      context.push(
        '/transactions/form',
        extra: {
          'initialType': 'expense',
          'initialTransaction': {
            'roomId': widget.roomId,
          }
        },
      ).then((_) => ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(widget.roomId));
    } else if (_tabController.index == 1) {
      // Add Shared Budget
      context.push(
        '/budgets/form',
        extra: {
          'budget': {
            'roomId': widget.roomId,
          }
        },
      ).then((_) => ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(widget.roomId));
    } else if (_tabController.index == 2) {
      // Add Shared Saving Goal
      context.push(
        '/savings/form',
        extra: {
          'goal': {
            'roomId': widget.roomId,
          }
        },
      ).then((_) => ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(widget.roomId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(sharedNotifierProvider);
    final textTheme = AppTypography.textTheme;
    final l10n = AppLocalizations.of(context);

    if (state.isRoomLoading && state.activeRoom == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final room = state.activeRoom;
    if (room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.roomNotFound)),
      );
    }

    final String roomName = room['name'] ?? 'Room';
    final List members = room['members'] ?? [];
    for (var m in members) {
      debugPrint('MEMBER DEBUG: ${m['username']} - avatarBorder: ${m['avatarBorder']}');
    }


    final profile = ref.watch(profileProvider).valueOrNull;
    final baseCurrency = profile?['currency'] as String? ?? AppConstants.defaultCurrency;
    final iconShape = ref.watch(categoryIconShapeProvider);


    final roomColor = AppColors.colorFromHex(room['colorCode'], fallback: AppColors.primary);

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: false,
              pinned: true,
              titleSpacing: Navigator.of(context).canPop() ? 0 : 24,
              leading: Navigator.of(context).canPop()
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
              title: GestureDetector(
                onTap: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: Text(
                  roomName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'leave') {
                      _deleteOrLeaveRoom();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Text(room['role'] == 'owner' ? l10n.deleteRoom : l10n.leaveRoom,
                              style: TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Info Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              roomColor.withValues(alpha: isDark ? 0.25 : 0.15),
                              roomColor.withValues(alpha: isDark ? 0.08 : 0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: roomColor.withValues(alpha: isDark ? 0.35 : 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Room emoji with shape from profile setting
                            Container(
                              width: 64,
                              height: 64,
                              alignment: Alignment.center,
                              decoration: ShapeDecoration(
                                color: roomColor.withValues(alpha: 0.2),
                                shape: iconShape.toShapeBorder(64),
                              ),
                              child: Text(
                                room['emojiIcon'] ?? '📁',
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          roomName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _showEditRoomBottomSheet,
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                          color: isDark ? Colors.white70 : AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Pill showing only the number of members
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.group_outlined,
                                          size: 12,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${members.length} ${l10n.members}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        l10n.members,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMemberChips(members, state, l10n, isDark, profile?['userId'] ?? ''),
                    const SizedBox(height: 16),
                    _buildSummaryCards(state, l10n, isDark, baseCurrency),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  indicatorColor: AppColors.primary,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: l10n.transactions),
                    Tab(text: l10n.budgets),
                    Tab(text: l10n.savingsGoals),
                  ],
                ),
              ),
            )
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: Transactions List
            RefreshIndicator(
              onRefresh: () => ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(widget.roomId),
              child: state.roomTransactions.isEmpty
                  ? _buildEmptyTab(Icons.receipt_long_outlined, l10n.noTransactionsYetRoom, l10n.noTransactionsYetRoomSubtitle)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.roomTransactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final tx = state.roomTransactions[idx];
                        return shared_tx.TransactionCard(transaction: tx);
                      },
                    ),
            ),

            // TAB 2: Budgets
            RefreshIndicator(
              onRefresh: () => ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(widget.roomId),
              child: state.roomBudgets.isEmpty
                  ? _buildEmptyTab(Icons.pie_chart_outline_rounded, l10n.noBudgetsYetRoom, l10n.noBudgetsYetRoomSubtitle)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.roomBudgets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final budget = state.roomBudgets[idx];
                        final String name = budget['name'] ?? budget['category']?['name'] ?? 'Budget';
                        final double limit = budget['limitAmount'] is num ? (budget['limitAmount'] as num).toDouble() : double.parse(budget['limitAmount'] ?? '0');
                        final double spent = budget['spentAmount'] is num ? (budget['spentAmount'] as num).toDouble() : 0.0;
                        final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                        final color = AppColors.colorFromHex(budget['colorCode'], fallback: AppColors.primary);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${(percent * 100).toInt()}%',
                                    style: textTheme.bodySmall?.copyWith(color: percent >= 0.9 ? AppColors.danger : AppColors.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: percent,
                                backgroundColor: isDark ? AppColors.borderDark : AppColors.dividerLight,
                                valueColor: AlwaysStoppedAnimation(percent >= 0.9 ? AppColors.danger : color),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${l10n.usedAmount}: ${CurrencyFormatter.formatAmount(spent, symbol: AppConstants.getCurrencySymbol(baseCurrency))}',
                                    style: textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${l10n.limitAmountLabel}: ${CurrencyFormatter.formatAmount(limit, symbol: AppConstants.getCurrencySymbol(baseCurrency))}',
                                    style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // TAB 3: Savings Goals
            RefreshIndicator(
              onRefresh: () => ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(widget.roomId),
              child: state.roomSavings.isEmpty
                  ? _buildEmptyTab(Icons.savings_outlined, l10n.noSavingsYetRoom, l10n.noSavingsYetRoomSubtitle)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.roomSavings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final goal = state.roomSavings[idx];
                        final String name = goal['name'] ?? 'Savings Goal';
                        final double target = goal['targetAmount'] is num ? (goal['targetAmount'] as num).toDouble() : double.parse(goal['targetAmount'] ?? '0');
                        final double current = goal['currentAmount'] is num ? (goal['currentAmount'] as num).toDouble() : double.parse(goal['currentAmount'] ?? '0');
                        final percent = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
                        final color = AppColors.colorFromHex(goal['colorCode'], fallback: AppColors.success);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: percent,
                                backgroundColor: isDark ? AppColors.borderDark : AppColors.dividerLight,
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${l10n.collectedAmount}: ${CurrencyFormatter.formatAmount(current, symbol: AppConstants.getCurrencySymbol(baseCurrency))}',
                                    style: textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${l10n.targetAmountLabel}: ${CurrencyFormatter.formatAmount(target, symbol: AppConstants.getCurrencySymbol(baseCurrency))}',
                                    style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyTab(IconData icon, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = AppTypography.textTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberChips(List<dynamic> members, SharedState state, AppLocalizations l10n, bool isDark, String currentUserId) {
    if (state.isRoomLoading) {
      return _MemberChipSkeleton(isDark: isDark);
    }

    final profile = ref.read(profileProvider).value;

    // Order members: Put "you" (currentUserId) first among the member chips
    final orderedMembers = List<dynamic>.from(members);
    final youIndex = orderedMembers.indexWhere((m) => m['userId'] == currentUserId);
    dynamic youMember;
    if (youIndex != -1) {
      youMember = orderedMembers.removeAt(youIndex);
    }

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        clipBehavior: Clip.none,
        children: [
          // 1. Add Member Chip
          _buildAddMemberChip(l10n, isDark),
          
          // 2. You Chip
          if (youMember != null)
            _buildMemberChip(
              name: l10n.you,
              avatarUrl: profile?['avatar'] ?? youMember['avatar'],
              borderAsset: borderAssetFromId(profile?['avatarBorder'] ?? youMember['avatarBorder']),
              isDark: isDark,
              onTap: () {
                context.push('/shared/public-profile', extra: youMember);
              },
            ),
            
          // 3. Other Members Chips
          ...orderedMembers.map((m) {
            final String? username = m['username'];
            final String name = (username != null && username.isNotEmpty)
                ? '@$username'
                : (m['fullName'] ?? m['email'] ?? '');
            return _buildMemberChip(
              name: name,
              avatarUrl: m['avatar'],
              borderAsset: borderAssetFromId(m['avatarBorder']),
              isDark: isDark,
              onTap: () {
                context.push('/shared/public-profile', extra: m);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddMemberChip(AppLocalizations l10n, bool isDark) {
    return GestureDetector(
      onTap: _showInviteMemberBottomSheet,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.person_add_outlined,
                  color: isDark ? Colors.white70 : AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.addMember,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberChip({
    required String name,
    required String? avatarUrl,
    required String borderAsset,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              size: 68,
              borderAsset: borderAsset,
              avatarUrl: avatarUrl,
              fallbackName: name,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteMemberBottomSheet() {
    final state = ref.read(sharedNotifierProvider);
    final room = state.activeRoom;
    if (room == null) return;

    final List members = room['members'] ?? [];
    final memberUserIds = members.map((m) => m['userId'] as String).toSet();

    // Friends who are not yet members
    final inviteableFriends = state.friends
        .where((f) => !memberUserIds.contains(f['userId'] as String))
        .toList();

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                          final String name = friend['fullName'] ?? friend['username'] ?? friend['email'];
                          final String? username = friend['username'];
                          final avatarUrl = friend['avatar'];
                          final avatarBorderId = friend['avatarBorder'] as String?;
                          final borderAsset = borderAssetFromId(avatarBorderId);

                          return Row(
                            children: [
                              UserAvatar(
                                size: 44,
                                borderAsset: borderAsset,
                                avatarUrl: avatarUrl,
                                fallbackName: name,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (username != null && username.isNotEmpty) ...[
                                      Text(
                                        '@$username',
                                        style: AppTypography.textTheme.bodySmall?.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      name,
                                      style: AppTypography.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final localizations = Localizations.localeOf(context);
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
                            ],
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

  Widget _buildSummaryCards(SharedState state, AppLocalizations l10n, bool isDark, String baseCurrency) {
    final txCount = state.roomTransactions.length;

    double totalBudgetLimit = 0;
    double totalBudgetSpent = 0;
    for (var b in state.roomBudgets) {
      final limit = b['limitAmount'] is num ? (b['limitAmount'] as num).toDouble() : double.tryParse(b['limitAmount']?.toString() ?? '0') ?? 0.0;
      final spent = b['spentAmount'] is num ? (b['spentAmount'] as num).toDouble() : double.tryParse(b['spentAmount']?.toString() ?? '0') ?? 0.0;
      totalBudgetLimit += limit;
      totalBudgetSpent += spent;
    }
    final budgetPercent = totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit).clamp(0.0, 1.0) : 0.0;

    double totalSavingTarget = 0;
    double totalSavingCurrent = 0;
    for (var s in state.roomSavings) {
      final target = s['targetAmount'] is num ? (s['targetAmount'] as num).toDouble() : double.tryParse(s['targetAmount']?.toString() ?? '0') ?? 0.0;
      final current = s['currentAmount'] is num ? (s['currentAmount'] as num).toDouble() : double.tryParse(s['currentAmount']?.toString() ?? '0') ?? 0.0;
      totalSavingTarget += target;
      totalSavingCurrent += current;
    }
    final savingPercent = totalSavingTarget > 0 ? (totalSavingCurrent / totalSavingTarget).clamp(0.0, 1.0) : 0.0;

    final symbol = AppConstants.getCurrencySymbol(baseCurrency);
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _summaryPageController,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          Widget card;
          if (index == 0) {
            card = _buildSummaryCard(
              title: isId ? 'Transaksi' : 'Transactions',
              value: '$txCount',
              subLabel: isId ? 'Transaksi' : 'Transactions',
              icon: Icons.receipt_long_outlined,
              bgColor: isDark ? const Color(0xFF27213C) : const Color(0xFFF3E8FF),
              textColor: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE),
              iconBgColor: isDark ? const Color(0xFF3B2F5F) : const Color(0xFFE9D5FF),
            );
          } else if (index == 1) {
            card = _buildSummaryCard(
              title: 'Budget',
              value: CurrencyFormatter.formatAmount(totalBudgetSpent, symbol: symbol),
              subLabel: l10n.of_(CurrencyFormatter.formatAmount(totalBudgetLimit, symbol: symbol)),
              icon: Icons.pie_chart_outline_rounded,
              bgColor: isDark ? const Color(0xFF1B2E24) : const Color(0xFFECFDF5),
              textColor: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
              iconBgColor: isDark ? const Color(0xFF244432) : const Color(0xFFD1FAE5),
              progress: budgetPercent,
            );
          } else {
            card = _buildSummaryCard(
              title: isId ? 'Tabungan' : 'Savings',
              value: CurrencyFormatter.formatAmount(totalSavingCurrent, symbol: symbol),
              subLabel: l10n.of_(CurrencyFormatter.formatAmount(totalSavingTarget, symbol: symbol)),
              icon: Icons.savings_outlined,
              bgColor: isDark ? const Color(0xFF2E2216) : const Color(0xFFFFF7ED),
              textColor: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
              iconBgColor: isDark ? const Color(0xFF43301F) : const Color(0xFFFFEDD5),
              progress: savingPercent,
            );
          }
          return Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: card,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subLabel,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color iconBgColor,
    double? progress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBgColor,
                ),
                child: Icon(
                  icon,
                  color: textColor,
                  size: 20,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: iconBgColor,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 13),
          ],
        ],
      ),
    );
  }
}

class _MemberChipSkeleton extends StatefulWidget {
  const _MemberChipSkeleton({required this.isDark});
  final bool isDark;

  @override
  State<_MemberChipSkeleton> createState() => _MemberChipSkeletonState();
}

class _MemberChipSkeletonState extends State<_MemberChipSkeleton>
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

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 76,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 50,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
