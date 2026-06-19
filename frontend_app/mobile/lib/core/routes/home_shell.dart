import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

class _CustomConvexStyle extends StyleHook {
  final TextStyle baseStyle;
  _CustomConvexStyle(this.baseStyle);

  @override
  double get activeIconSize => 40;

  @override
  double get activeIconMargin => 10;

  @override
  double get iconSize => 24;

  @override
  TextStyle textStyle(Color color, String? fontFamily) {
    return baseStyle.copyWith(color: color, fontSize: 10);
  }
}

class HomeShell extends ConsumerWidget {
  const HomeShell({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: List.generate(children.length, (index) {
          final isActive = index == navigationShell.currentIndex;
          return IgnorePointer(
            ignoring: !isActive,
            child: AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: children[index],
            ),
          );
        }),
      ),
      bottomNavigationBar: _CuanBuddyNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ─── Custom Bottom Navigation Bar ─────────────────────────────────────────────
class _CuanBuddyNavBar extends ConsumerWidget {
  const _CuanBuddyNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Watch profile for avatar
    final profileAsync = ref.watch(profileProvider);

    return StyleProvider(
      style: _CustomConvexStyle(Theme.of(context).textTheme.bodySmall!),
      child: ConvexAppBar(
        style: TabStyle.fixedCircle,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        activeColor: AppColors.primary,
        cornerRadius: 0,
        elevation: 4,
        initialActiveIndex: currentIndex,
        onTap: onTap,
        items: [
          TabItem(icon: Icons.receipt_long_outlined, title: l10n.transactions),
          TabItem(icon: Icons.pie_chart_outline_rounded, title: l10n.budgets),
          TabItem(icon: Icons.home_rounded, title: l10n.home),
          TabItem(icon: Icons.savings_outlined, title: l10n.savingsGoals),
          TabItem(
            title: l10n.profile,
            icon: profileAsync.when(
              data: (profile) {
                final avatarUrl = profile['avatar'] as String?;
                if (avatarUrl != null && avatarUrl.isNotEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentIndex == 4 ? AppColors.primary : Colors.transparent, 
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person_outline_rounded,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  );
                }
                return Icon(
                  Icons.person_outline_rounded,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                );
              },
              loading: () => Shimmer.fromColors(
                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
              error: (_, __) => Icon(
                Icons.person_outline_rounded,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
