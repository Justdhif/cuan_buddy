import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

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

    return StyleProvider(
      style: _CustomConvexStyle(Theme.of(context).textTheme.bodySmall!),
      child: ConvexAppBar(
        style: TabStyle.fixedCircle,
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : Theme.of(context).scaffoldBackgroundColor,
        color:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        activeColor: AppColors.primary,
        shadowColor:
            isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black12,
        cornerRadius: 0,
        elevation: isDark ? 8 : 4,
        height: 60 +
            (MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom * 0.6
                : 0),
        initialActiveIndex: currentIndex,
        onTap: onTap,
        items: [
          TabItem(icon: Icons.receipt_long_outlined, title: l10n.transactions),
          TabItem(icon: Icons.pie_chart_outline_rounded, title: l10n.budgets),
          TabItem(icon: Icons.home_rounded, title: l10n.home),
          TabItem(icon: Icons.savings_outlined, title: l10n.savingsGoals),
          TabItem(icon: Icons.group_outlined, title: l10n.shared),
        ],
      ),
    );
  }
}
