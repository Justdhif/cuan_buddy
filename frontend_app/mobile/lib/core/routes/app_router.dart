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
import '../../features/auth/presentation/screens/forgot_password_otp_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';

// Profile Setup
import '../../features/profile/presentation/screens/profile_setup_screen.dart';
import '../../features/profile/presentation/screens/backup_settings_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/widget_settings_screen.dart';
import '../../features/profile/presentation/screens/theme_language_screen.dart';
import '../../features/profile/presentation/screens/account_screen.dart';
import '../../features/profile/presentation/screens/change_phone_screen.dart';
import '../../features/profile/presentation/screens/edit_name_screen.dart';
import '../../features/profile/presentation/screens/edit_bio_screen.dart';
import '../../features/profile/presentation/screens/edit_username_screen.dart';
import '../../features/profile/presentation/screens/edit_birthdate_screen.dart';
import '../../features/profile/presentation/screens/edit_gender_screen.dart';

// Main Features
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transaction_list_screen.dart';
import '../../features/transactions/presentation/screens/transaction_form_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/budgets/presentation/screens/budget_form_screen.dart';
import '../../features/savings/presentation/screens/savings_screen.dart';
import '../../features/savings/presentation/screens/savings_form_screen.dart';
import '../../features/savings/presentation/screens/saving_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/ai/presentation/screens/ai_chat_screen.dart';
import '../../features/categories/presentation/screens/category_list_screen.dart';
import '../../features/shared/presentation/screens/shared_screen.dart';
import '../../features/wallets/presentation/screens/manage_wallets_screen.dart';

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
        pageBuilder: (context, state) =>
            _buildPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _buildPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _buildPage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String?;
          final password = extra?['password'] as String?;
          return _buildPage(state, EmailVerificationScreen(email: email, password: password));
        },
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _buildPage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/forgot-password/otp',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return _buildPage(state, ForgotPasswordOtpScreen(email: email));
        },
      ),
      GoRoute(
        path: '/forgot-password/reset',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final otp = state.uri.queryParameters['otp'] ?? '';
          return _buildPage(state, ResetPasswordScreen(email: email, otp: otp));
        },
      ),
      GoRoute(
        path: '/profile-setup',
        pageBuilder: (context, state) =>
            _buildPage(state, const ProfileSetupScreen()),
        redirect: (context, state) {
          if (prefsService.profileComplete) return '/wallet-setup';
          return null;
        },
      ),
      GoRoute(
        path: '/wallet-setup',
        pageBuilder: (context, state) =>
            _buildPage(state, const ManageWalletsScreen(isOnboarding: true)),
      ),
      GoRoute(
        path: '/backup-settings',
        pageBuilder: (context, state) =>
            _buildPage(state, const BackupSettingsScreen(isOnboarding: true)),
        redirect: (context, state) {
          if (prefsService.backupSetupComplete) return '/home/dashboard';
          return null;
        },
      ),
      GoRoute(
        path: '/profile/backup',
        pageBuilder: (context, state) =>
            _buildPage(state, const BackupSettingsScreen(isOnboarding: false)),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) {
          final profile = state.extra as Map<String, dynamic>;
          return _buildPage(state, EditProfileScreen(profile: profile));
        },
      ),
      GoRoute(
        path: '/profile/widgets',
        pageBuilder: (context, state) =>
            _buildPage(state, const WidgetSettingsScreen()),
      ),
      GoRoute(
        path: '/profile/theme-language',
        pageBuilder: (context, state) =>
            _buildPage(state, const ThemeLanguageScreen()),
      ),
      GoRoute(
        path: '/profile/account',
        pageBuilder: (context, state) =>
            _buildPage(state, const AccountScreen()),
      ),
      GoRoute(
        path: '/profile/change-phone',
        pageBuilder: (context, state) =>
            _buildPage(state, const ChangePhoneScreen()),
      ),
      GoRoute(
        path: '/profile/edit-name',
        pageBuilder: (context, state) {
          final initialName = state.extra as String? ?? '';
          return _buildPage(state, EditNameScreen(initialName: initialName));
        },
      ),
      GoRoute(
        path: '/profile/edit-username',
        pageBuilder: (context, state) {
          final initialUsername = state.extra as String? ?? '';
          return _buildPage(state, EditUsernameScreen(initialUsername: initialUsername));
        },
      ),
      GoRoute(
        path: '/profile/edit-bio',
        pageBuilder: (context, state) {
          final initialBio = state.extra as String? ?? '';
          return _buildPage(state, EditBioScreen(initialBio: initialBio));
        },
      ),
      GoRoute(
        path: '/profile/edit-birthdate',
        pageBuilder: (context, state) {
          final initialBirthdate = state.extra as String? ?? '';
          return _buildPage(state, EditBirthdateScreen(initialBirthdate: initialBirthdate));
        },
      ),
      GoRoute(
        path: '/profile/edit-gender',
        pageBuilder: (context, state) {
          final initialGender = state.extra as String?;
          return _buildPage(state, EditGenderScreen(initialGender: initialGender));
        },
      ),
      GoRoute(
        path: '/change-password',
        pageBuilder: (context, state) =>
            _buildPage(state, const ChangePasswordScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            _buildPage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/ai-chat',
        pageBuilder: (context, state) =>
            _buildPage(state, const AiChatScreen()),
      ),
      GoRoute(
        path: '/transactions/form',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final initialType = extra['initialType'] as String? ?? 'expense';
          final initialTransaction =
              extra['initialTransaction'] as Map<String, dynamic>?;
          final initialSavingsGoalId = extra['initialSavingsGoalId'] as String?;
          final lockedSavingsGoal = extra['lockedSavingsGoal'] as bool? ?? false;
          return _buildPage(
            state,
            TransactionFormScreen(
              initialType: initialType,
              initialTransaction: initialTransaction,
              initialSavingsGoalId: initialSavingsGoalId,
              lockedSavingsGoal: lockedSavingsGoal,
            ),
          );
        },
      ),
      GoRoute(
        path: '/budgets/form',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _buildPage(
            state,
            BudgetFormScreen(
              budget: extra?['budget'] as Map<String, dynamic>?,
              initialCategoryId: extra?['initialCategoryId'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/savings/form',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _buildPage(
            state,
            SavingsFormScreen(
              goal: extra?['goal'] as Map<String, dynamic>?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/savings/detail',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _buildPage(
            state,
            SavingDetailScreen(
              goal: extra['goal'] as Map<String, dynamic>,
            ),
          );
        },
      ),
      GoRoute(
        path: '/budgets',
        pageBuilder: (context, state) =>
            _buildPage(state, const BudgetsScreen()),
      ),
      GoRoute(
        path: '/manage-categories',
        pageBuilder: (context, state) =>
            _buildPage(state, const CategoryListScreen()),
      ),
      GoRoute(
        path: '/manage-wallets',
        pageBuilder: (context, state) =>
            _buildPage(state, const ManageWalletsScreen()),
      ),
      GoRoute(
        path: '/home/profile',
        pageBuilder: (context, state) =>
            _buildPage(state, const ProfileScreen()),
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
              pageBuilder: (context, state) =>
                  _buildPage(state, const TransactionListScreen()),
            ),
          ]),
          // Branch 1 – Budgets
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/budgets',
              pageBuilder: (context, state) =>
                  _buildPage(state, const BudgetsScreen()),
            ),
          ]),
          // Branch 2 – Dashboard (Home)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/dashboard',
              pageBuilder: (context, state) =>
                  _buildPage(state, const DashboardScreen()),
            ),
          ]),
          // Branch 3 – Savings
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/savings',
              pageBuilder: (context, state) =>
                  _buildPage(state, const SavingsScreen()),
            ),
          ]),
          // Branch 4 – Shared
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/shared',
              pageBuilder: (context, state) =>
                  _buildPage(state, const SharedScreen()),
            ),
          ]),
        ],
      ),
    ],
  );
});
