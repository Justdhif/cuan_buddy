import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../providers/shared_provider.dart';

class FriendManagementScreen extends ConsumerStatefulWidget {
  const FriendManagementScreen({super.key});

  @override
  ConsumerState<FriendManagementScreen> createState() => _FriendManagementScreenState();
}

class _FriendManagementScreenState extends ConsumerState<FriendManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inviteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedNotifierProvider.notifier).fetchLobbyData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  void _sendFriendRequest(String target) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(sharedNotifierProvider.notifier);
    final error = await notifier.sendFriendRequest(target);
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.danger),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.friendRequestSentSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        _inviteController.clear();
        _searchController.clear();
        notifier.clearSearch();
        setState(() {});
      }
    }
  }

  void _respondRequest(String friendshipId, String action) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(sharedNotifierProvider.notifier);
    final error = await notifier.respondFriendRequest(friendshipId, action);
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.danger),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accept'
                ? l10n.friendRequestAccepted
                : l10n.friendRequestDeclined),
            backgroundColor: action == 'accept' ? AppColors.success : AppColors.textSecondaryDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(sharedNotifierProvider);
    final textTheme = AppTypography.textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(l10n.manageFriends, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          dividerColor: Colors.transparent, // Hapus garis putih di bawah TabBar
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.friends),
                  if (state.friends.isNotEmpty && _searchController.text.isEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.friends.length}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.requests),
                  if (state.pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${state.pendingRequests.length}',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Teman & Pencarian (digabung)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(sharedNotifierProvider.notifier).searchUsers(val);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: l10n.searchFriendsPlaceholder,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(sharedNotifierProvider.notifier).clearSearch();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.dividerLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchController.text.isEmpty
                        ? (state.friends.isEmpty
                            ? AppEmptyState(
                                icon: Icons.people_outline,
                                title: l10n.noFriendsYet,
                                subtitle: l10n.friendsInviteDescription,
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: state.friends.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final friend = state.friends[index];
                                  final String avatar = friend['avatar'] ?? '';
                                  final String name = friend['fullName'] ?? friend['username'] ?? friend['email'];
                                  final String username = friend['username'] != null ? '@${friend['username']}' : friend['email'];

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDark : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                          child: avatar.isEmpty
                                              ? Text(
                                                  name.substring(0, 1).toUpperCase(),
                                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
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
                                              const SizedBox(height: 2),
                                              Text(
                                                username,
                                                style: textTheme.bodySmall?.copyWith(
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ))
                        : (state.searchResults.isEmpty
                            ? AppEmptyState(
                                icon: Icons.search_off_outlined,
                                title: l10n.languageCode == 'id' ? 'Pengguna tidak ditemukan' : 'No users found',
                                subtitle: l10n.languageCode == 'id'
                                    ? 'Coba cari dengan username atau email lain.'
                                    : 'Try searching for a different username or email.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: state.searchResults.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final match = state.searchResults[index];
                                  final String avatar = match['avatar'] ?? '';
                                  final String name = match['fullName'] ?? match['username'] ?? match['email'];
                                  final String username = match['username'] != null ? '@${match['username']}' : match['email'];
                                  final String status = match['friendshipStatus'] ?? 'none';
                                  final bool isSender = match['isSender'] ?? false;

                                  Widget actionBtn;
                                  if (status == 'accepted') {
                                    actionBtn = Text(l10n.friend, style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold));
                                  } else if (status == 'pending') {
                                    actionBtn = isSender
                                        ? Text(l10n.pending, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              minimumSize: Size.zero,
                                            ),
                                            onPressed: () => _respondRequest(match['friendshipId'], 'accept'),
                                            child: Text(l10n.accept, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                          );
                                  } else {
                                    actionBtn = ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _sendFriendRequest(match['email']),
                                      child: Text(l10n.invite, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    );
                                  }

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDark : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                          child: avatar.isEmpty
                                              ? Text(
                                                  name.substring(0, 1).toUpperCase(),
                                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
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
                                              const SizedBox(height: 2),
                                              Text(
                                                username,
                                                style: textTheme.bodySmall?.copyWith(
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actionBtn,
                                      ],
                                    ),
                                  );
                                },
                              )),
              )
            ],
          ),

          // TAB 2: Permintaan Masuk
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.pendingRequests.isEmpty
                  ? AppEmptyState(
                      icon: Icons.mail_outline,
                      title: l10n.noRequestsYet,
                      subtitle: l10n.incomingRequestsDescription,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.pendingRequests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final reqItem = state.pendingRequests[index];
                        final String avatar = reqItem['avatar'] ?? '';
                        final String name = reqItem['fullName'] ?? reqItem['username'] ?? reqItem['email'];
                        final String username = reqItem['username'] != null ? '@${reqItem['username']}' : reqItem['email'];
                        final String friendshipId = reqItem['friendshipId'];

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: avatar.isEmpty
                                    ? Text(
                                        name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
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
                                    const SizedBox(height: 2),
                                    Text(
                                      username,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              side: BorderSide(color: AppColors.danger),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () => _respondRequest(friendshipId, 'decline'),
                                            child: Text(l10n.decline, style: TextStyle(color: AppColors.danger)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              backgroundColor: AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () => _respondRequest(friendshipId, 'accept'),
                                            child: Text(l10n.accept, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

}
