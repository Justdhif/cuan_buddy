import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../providers/shared_provider.dart';
import '../../../profile/presentation/widgets/avatar_border_helper.dart';

class FriendManagementScreen extends ConsumerStatefulWidget {
  const FriendManagementScreen({super.key});

  @override
  ConsumerState<FriendManagementScreen> createState() => _FriendManagementScreenState();
}

class _FriendManagementScreenState extends ConsumerState<FriendManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inviteController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
        title: Text(
          Localizations.localeOf(context).languageCode == 'id' ? 'Cari Teman' : 'Find Friends',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
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
                hintText: Localizations.localeOf(context).languageCode == 'id'
                    ? 'Cari nama atau username...'
                    : 'Search name or username...',
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
            child: state.isSearchLoading
                ? _FriendListSkeleton(isDark: isDark)
                : _searchController.text.isEmpty
                    ? AppEmptyState(
                        icon: Icons.person_search_rounded,
                        title: Localizations.localeOf(context).languageCode == 'id'
                            ? 'Cari Teman Baru'
                            : 'Search New Friends',
                        subtitle: Localizations.localeOf(context).languageCode == 'id'
                            ? 'Masukkan nama pengguna atau email mereka untuk mulai berteman.'
                            : 'Enter their username or email address to start adding them.',
                      )
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
                              final String avatarUrl = match['avatar'] ?? '';
                              final String name = match['fullName'] ?? match['username'] ?? match['email'];
                              final String? rawUsername = match['username'];
                              final String? borderId = match['avatarBorder'];
                              final borderAsset = borderAssetFromId(borderId);
                              
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

                              return Padding(
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
                                          if (rawUsername != null && rawUsername.isNotEmpty) ...[
                                            Text(
                                              '@$rawUsername',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                          ],
                                          Text(
                                            name,
                                            style: textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    actionBtn,
                                  ],
                                ),
                              );
                            },
                          )),
          )
        ],
      ),
    );
  }
}

// ─── Friend List Skeleton ──────────────────────────────────────────────────────
/// Shimmer-style placeholder rows while search results are loading.
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: 8,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
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
                  // Action button placeholder
                  Container(
                    width: 72,
                    height: 32,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(8),
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
