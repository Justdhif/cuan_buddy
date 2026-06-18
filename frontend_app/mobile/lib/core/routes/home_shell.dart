import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../l10n/app_localizations.dart';

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
    final profileAsync = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final shadowColor = Colors.transparent;

    // Branches: 0=Dashboard, 1=Transactions, 2=Budgets, 3=Savings, 4=Profile
    // Visual:   Trans | Budgets | [HOME] | Savings | Profile
    final items = [
      _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: l10n.transactions, branch: 1),
      _NavItem(icon: Icons.pie_chart_outline_rounded, activeIcon: Icons.pie_chart_rounded, label: l10n.budgets, branch: 2),
      _NavItem(icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: l10n.home, branch: 0), // CENTER
      _NavItem(icon: Icons.savings_outlined, activeIcon: Icons.savings_rounded, label: l10n.savingsGoals, branch: 3),
      _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: l10n.profile, branch: 4),
    ];

    return SafeArea(
      top: false,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 68,
            decoration: BoxDecoration(
              color: bgColor,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isCenter = i == 2;
                final isActive = currentIndex == item.branch;

                if (isCenter) {
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: currentIndex == 0 ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            fontSize: 10,
                            fontWeight: currentIndex == 0 ? FontWeight.w700 : FontWeight.w400,
                          ),
                          child: Text(l10n.home),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                }
                return _buildNavItem(item, isActive, isDark, i, profileAsync);
              }),
            ),
          ),
          Positioned(
            top: -32,
            child: _buildCenterButton(currentIndex == 0),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton(bool isActive) {
    return GestureDetector(
      onTap: () => onTap(0),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 3,
          ),
        ),
        child: Icon(
          Icons.home_rounded,
          color: Colors.white,
          size: isActive ? 32 : 28,
        ),
      ),
    );
  }

  Widget _buildNavItem(
      _NavItem item, bool isActive, bool isDark, int visualIndex, AsyncValue<Map<String, dynamic>> profileAsync) {
    final activeColor = AppColors.primary;
    final inactiveColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(item.branch),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: item.branch == 4
                    ? _buildAvatarIcon(profileAsync, isActive)
                    : Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? activeColor : inactiveColor,
                        size: 22,
                      ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarIcon(AsyncValue<Map<String, dynamic>> profileAsync, bool isActive) {
    final profile = profileAsync.value ?? {};
    final avatar = profile['avatar'] as String?;
    final name = profile['fullName'] as String? ?? 'You';
    final validAvatar = avatar;
    
    if (profileAsync.isLoading && profile.isEmpty) {
      return const _AvatarSkeletonLoader();
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isActive ? Border.all(color: AppColors.primary, width: 1.5) : null,
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        child: validAvatar != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: validAvatar,
                  fit: BoxFit.cover,
                  width: 24,
                  height: 24,
                  placeholder: (context, url) => const _AvatarSkeletonLoader(),
                  errorWidget: (context, url, error) => Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
            : Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
      ),
    );
  }
}

// ─── Avatar Skeleton Loader ───────────────────────────────────────────────────
class _AvatarSkeletonLoader extends StatefulWidget {
  const _AvatarSkeletonLoader();

  @override
  State<_AvatarSkeletonLoader> createState() => _AvatarSkeletonLoaderState();
}

class _AvatarSkeletonLoaderState extends State<_AvatarSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: baseColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.branch,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int branch;
}
