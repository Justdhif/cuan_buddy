import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/bottom_nav_behavior_provider.dart';

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
  bool _isPageChangingFromSwipe = false;

  bool _isNavBarVisible = true;
  bool _isChevronVisible = false;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.navigationShell.currentIndex);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeController.forward(from: 1.0);
  }

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != oldWidget.navigationShell.currentIndex) {
      final targetIndex = widget.navigationShell.currentIndex;
      if (!_isPageChangingFromSwipe) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(targetIndex);
        }
        _fadeController.forward(from: 0.0);
      }
      _isPageChangingFromSwipe = false;
      setState(() {
        _isNavBarVisible = true;
        _isChevronVisible = false;
      });
    }
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScrollNotification(ScrollNotification notification, BottomNavBehavior behavior) {
    if (behavior == BottomNavBehavior.alwaysVisible) {
      if (!_isNavBarVisible || _isChevronVisible) {
        setState(() {
          _isNavBarVisible = true;
          _isChevronVisible = false;
        });
      }
      return;
    }

    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;

    final isAtEdge = metrics.atEdge ||
        metrics.pixels <= metrics.minScrollExtent ||
        metrics.pixels >= metrics.maxScrollExtent;

    if (isAtEdge) {
      _pauseTimer?.cancel();
      if (!_isNavBarVisible || _isChevronVisible) {
        setState(() {
          _isNavBarVisible = true;
          _isChevronVisible = false;
        });
      }
      return;
    }

    if (notification is ScrollUpdateNotification) {
      final scrollDelta = notification.scrollDelta ?? 0.0;
      if (scrollDelta.abs() > 2.0) {
        _pauseTimer?.cancel();

        if (behavior == BottomNavBehavior.autoShowOnPause) {
          if (_isNavBarVisible || _isChevronVisible) {
            setState(() {
              _isNavBarVisible = false;
              _isChevronVisible = false;
            });
          }

          _pauseTimer = Timer(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _isNavBarVisible = true;
                _isChevronVisible = false;
              });
            }
          });
        } else if (behavior == BottomNavBehavior.manualChevron) {
          if (_isNavBarVisible) {
            setState(() {
              _isNavBarVisible = false;
              _isChevronVisible = true;
            });
          } else if (!_isChevronVisible) {
            setState(() {
              _isChevronVisible = true;
            });
          }
        }
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle &&
          behavior == BottomNavBehavior.autoShowOnPause) {
        _pauseTimer?.cancel();
        _pauseTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _isNavBarVisible = true;
              _isChevronVisible = false;
            });
          }
        });
      }
    }
  }

  void _toggleChevron() {
    setState(() {
      _isNavBarVisible = !_isNavBarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navBehavior = ref.watch(bottomNavBehaviorProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double bottomMargin = bottomPadding > 0 ? bottomPadding : 12;

    final showNavBar = navBehavior == BottomNavBehavior.alwaysVisible || _isNavBarVisible;
    final showChevron = navBehavior == BottomNavBehavior.manualChevron && _isChevronVisible;

    return Scaffold(
      extendBody: true,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [

          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _onScrollNotification(notification, navBehavior);
              return false;
            },
            child: FadeTransition(
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
          ),

          if (navBehavior == BottomNavBehavior.manualChevron)
            Positioned(
              bottom: showNavBar ? (64 + bottomMargin + 12) : (bottomMargin + 12),
              child: IgnorePointer(
                ignoring: !showChevron,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  offset: showChevron ? Offset.zero : const Offset(0, 2.5),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: showChevron ? 1.0 : 0.0,
                    child: Material(
                      color: Colors.transparent,
                      elevation: 8,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _toggleChevron,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E2A38).withValues(alpha: 0.95)
                                : Colors.white.withValues(alpha: 0.98),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            showNavBar
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        offset: showNavBar ? Offset.zero : const Offset(0, 1.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: showNavBar ? 1.0 : 0.0,
          child: _CuanBuddyNavBar(
            currentIndex: widget.navigationShell.currentIndex,
            onTap: (index) {
              if (index != widget.navigationShell.currentIndex) {
                widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final navItems = [
      _NavItemData(
        index: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.home,
      ),
      _NavItemData(
        index: 1,
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: l10n.transactions,
      ),
      _NavItemData(
        index: 2,
        icon: Icons.group_outlined,
        activeIcon: Icons.group_rounded,
        label: l10n.shared,
      ),
      _NavItemData(
        index: 3,
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: l10n.languageCode == 'id' ? 'Pengaturan' : 'Settings',
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomPadding > 0 ? bottomPadding : 12,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2A38).withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: navItems.map((item) {
                  final isSelected = currentIndex == item.index;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(item.index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
