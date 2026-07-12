import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/shared_provider.dart';
import '../../widgets/transaction_card.dart' as shared_tx;

class SharedRoomDashboardScreen extends ConsumerStatefulWidget {
  final String roomId;
  const SharedRoomDashboardScreen({super.key, required this.roomId});

  @override
  ConsumerState<SharedRoomDashboardScreen> createState() => _SharedRoomDashboardScreenState();
}

class _SharedRoomDashboardScreenState extends ConsumerState<SharedRoomDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB action
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedNotifierProvider.notifier).fetchRoomDetails(widget.roomId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    final Map<String, dynamic> summary = room['summary'] ?? {};
    final double balance = summary['balance'] is num ? (summary['balance'] as num).toDouble() : 0.0;

    final profile = ref.watch(profileProvider).valueOrNull;
    final baseCurrency = profile?['currency'] as String? ?? AppConstants.defaultCurrency;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.dividerLight,
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
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(24, 76, 24, 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.balanceGradient,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        roomName,
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.totalRoomBalance,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatAmount(balance, symbol: AppConstants.getCurrencySymbol(baseCurrency)),
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            height: 28,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              itemCount: members.length > 5 ? 5 : members.length,
                              itemBuilder: (context, idx) {
                                final m = members[idx];
                                final String avatar = m['avatar'] ?? '';
                                final String init = (m['fullName'] ?? m['email']).substring(0, 1).toUpperCase();
                                return Align(
                                  widthFactor: 0.7,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.secondary,
                                    backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                    child: avatar.isEmpty
                                        ? Text(
                                            init,
                                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (members.length > 5) ...[
                            const SizedBox(width: 12),
                            Text(
                              l10n.othersCount(members.length - 5),
                              style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                            ),
                          ]
                        ],
                      )
                    ],
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
