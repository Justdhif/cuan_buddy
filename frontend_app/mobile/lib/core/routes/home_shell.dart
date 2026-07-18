import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../../features/profile/presentation/providers/achievement_provider.dart';

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

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  bool _isNavClick = false;
  bool _isPageChangingFromSwipe = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.navigationShell.currentIndex);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeController.forward(from: 1.0); // Start fully visible
    
    // Preload data unlocked borders di background saat masuk dashboard utama
    ref.read(unlockedBordersProvider);
  }

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != oldWidget.navigationShell.currentIndex) {
      final targetIndex = widget.navigationShell.currentIndex;
      if (_isNavClick) {
        // Nav clicked: jump page immediately and trigger fade animation
        _pageController.jumpToPage(targetIndex);
        _fadeController.forward(from: 0.0);
        _isNavClick = false;
      } else if (!_isPageChangingFromSwipe) {
        // Page changed externally or programmatically without click/swipe
        if (_pageController.hasClients && _pageController.page?.round() != targetIndex) {
          _pageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
      _isPageChangingFromSwipe = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeController,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            if (index != widget.navigationShell.currentIndex) {
              _isPageChangingFromSwipe = true;
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            }
          },
          children: widget.children,
        ),
      ),
      bottomNavigationBar: _CuanBuddyNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          if (index != widget.navigationShell.currentIndex) {
            setState(() {
              _isNavClick = true;
            });
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          }
        },
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
        key: ValueKey(currentIndex),
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
