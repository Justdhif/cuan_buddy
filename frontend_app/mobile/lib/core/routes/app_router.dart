import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_shell.dart';
import '../providers/core_providers.dart';

// Auth
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';

// Profile Setup
import '../../features/profile/presentation/screens/profile_setup_screen.dart';
import '../../features/profile/presentation/screens/backup_settings_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';

import '../../features/profile/presentation/screens/currency_screen.dart';

// Main Features
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transaction_list_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/savings/presentation/screens/savings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/ai/presentation/screens/ai_chat_screen.dart';
import '../../features/categories/presentation/screens/category_list_screen.dart';


CustomTransitionPage _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildPage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) {
          final email = state.extra as String?;
          return _buildPage(state, EmailVerificationScreen(email: email));
        },
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _buildPage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/profile-setup',
        pageBuilder: (context, state) => _buildPage(state, const ProfileSetupScreen()),
        redirect: (context, state) {
          if (prefsService.profileComplete) return '/backup-settings';
          return null;
        },
      ),
      GoRoute(
        path: '/backup-settings',
        pageBuilder: (context, state) => _buildPage(state, const BackupSettingsScreen(isOnboarding: true)),
        redirect: (context, state) {
          if (prefsService.backupSetupComplete) return '/home/dashboard';
          return null;
        },
      ),
      GoRoute(
        path: '/profile/backup',
        pageBuilder: (context, state) => _buildPage(state, const BackupSettingsScreen(isOnboarding: false)),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) {
          final profile = state.extra as Map<String, dynamic>;
          return _buildPage(state, EditProfileScreen(profile: profile));
        },
      ),
      GoRoute(
        path: '/currency',
        pageBuilder: (context, state) => _buildPage(state, const CurrencyScreen()),
      ),
      GoRoute(
        path: '/change-password',
        pageBuilder: (context, state) => _buildPage(state, const ChangePasswordScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _buildPage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/ai-chat',
        pageBuilder: (context, state) => _buildPage(state, const AiChatScreen()),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (context, navigationShell, children) {
          return HomeShell(
            navigationShell: navigationShell,
            children: children,
          );
        },
        branches: [
          // Branch 0 – Transactions
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/transactions',
              pageBuilder: (context, state) => _buildPage(state, const TransactionListScreen()),
            ),
          ]),
          // Branch 1 – Budgets
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/budgets',
              pageBuilder: (context, state) => _buildPage(state, const BudgetsScreen()),
            ),
            GoRoute(
              path: '/home/manage-categories',
              pageBuilder: (context, state) => _buildPage(state, const CategoryListScreen()),
            ),
          ]),
          // Branch 2 – Dashboard (Home)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/dashboard',
              pageBuilder: (context, state) => _buildPage(state, const DashboardScreen()),
            ),
          ]),
          // Branch 3 – Savings
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/savings',
              pageBuilder: (context, state) => _buildPage(state, const SavingsScreen()),
            ),
          ]),
          // Branch 4 – Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/profile',
              pageBuilder: (context, state) => _buildPage(state, const ProfileScreen()),
            ),
          ]),
        ],
      ),
    ],
  );
});
