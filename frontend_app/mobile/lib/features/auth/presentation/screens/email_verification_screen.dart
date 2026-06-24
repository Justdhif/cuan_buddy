import '../../../../core/utils/app_snackbar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, this.email});
  final String? email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isWaiting = false;
  bool _isLoading = false;
  bool _isVerified = false;
  Timer? _redirectTimer;

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    if (widget.email == null || widget.email!.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      final msg = await ref
          .read(authNotifierProvider.notifier)
          .sendVerificationEmail(widget.email!);
      if (!mounted) return;
      AppSnackbar.show(context,
          title: l10n.success, message: msg, type: SnackbarType.success);
      setState(() {
        _isWaiting = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.show(context,
          title: l10n.info, message: e.toString(), type: SnackbarType.error);
    }
  }

  Future<void> _checkStatus() async {
    if (widget.email == null || widget.email!.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      final isActive = await ref
          .read(authNotifierProvider.notifier)
          .checkVerificationStatus(widget.email!);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (isActive) {
        setState(() => _isVerified = true);
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: l10n.accountVerifiedRedirecting,
          type: SnackbarType.success,
        );
        _redirectTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) context.go('/login');
        });
      } else {
        AppSnackbar.show(
          context,
          title: l10n.info,
          message: l10n.accountNotYetVerified,
          type: SnackbarType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.show(context,
          title: l10n.info, message: e.toString(), type: SnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerified) return _buildSuccessState(context);
    if (_isWaiting) return _buildWaitingState(context);
    return _buildRequestState(context);
  }

  Widget _buildRequestState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyEmail)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text('📧', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text(
                l10n.verificationRequired,
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.email != null
                    ? l10n.verificationLinkSentTo(widget.email!)
                    : l10n.verificationLinkSent,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: l10n.sendVerificationEmail,
                onPressed: _sendVerificationEmail,
                isLoading: _isLoading,
                type: AppButtonType.primary,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  l10n.backToLogin,
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.waitingForActivation)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text('⏳', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text(
                l10n.checkYourEmail,
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.weHaveSentVerificationTo(widget.email ?? ''),
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: l10n.checkUserStatus,
                onPressed: _checkStatus,
                isLoading: _isLoading,
                type: AppButtonType.secondary,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  l10n.goToLogin,
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                l10n.didNotReceiveEmail,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textHintLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text(
                l10n.accountVerified,
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.successDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.redirectingToLogin,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: l10n.goToLoginNow,
                onPressed: () {
                  _redirectTimer?.cancel();
                  context.go('/login');
                },
                type: AppButtonType.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
