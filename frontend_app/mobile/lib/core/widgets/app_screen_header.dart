import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';

class AppScreenHeader extends ConsumerWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    required this.isScrolled,
    this.showBackButton = true,
    this.showActions = false,
    this.onBackTap,
  });

  final String title;
  final bool isScrolled;
  final bool showBackButton;
  final bool showActions;
  final VoidCallback? onBackTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final notificationsState = ref.watch(notificationsNotifierProvider);
    final unreadCount = notificationsState.notifications
        .where((n) => !(n['isRead'] as bool? ?? false))
        .length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        showBackButton ? 12 : 20,
        MediaQuery.of(context).padding.top + 8,
        20,
        10,
      ),
      decoration: BoxDecoration(
        color: isScrolled ? appBgColor : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isScrolled
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06))
                : Colors.transparent,
            width: 1,
          ),
        ),
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            GestureDetector(
              onTap: onBackTap ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home/dashboard');
                    }
                  },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (showActions) ...[
            const SizedBox(width: 8),
            // Profile Icon Button
            GestureDetector(
              onTap: () => context.push('/home/profile'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Notification Bell Icon Button
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
