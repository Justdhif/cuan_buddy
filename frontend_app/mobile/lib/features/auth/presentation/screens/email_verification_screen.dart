import '../../../../core/utils/app_snackbar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, this.email});
  final String? email;

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
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

    setState(() => _isLoading = true);
    try {
      final msg = await ref.read(authNotifierProvider.notifier).sendVerificationEmail(widget.email!);
      if (!mounted) return;
      AppSnackbar.show(context, title: 'Success', message: msg, type: SnackbarType.success);
      setState(() {
        _isWaiting = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.show(context, title: 'Info', message: e.toString(), type: SnackbarType.error);
    }
  }

  Future<void> _checkStatus() async {
    if (widget.email == null || widget.email!.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final isActive = await ref.read(authNotifierProvider.notifier).checkVerificationStatus(widget.email!);
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (isActive) {
        setState(() => _isVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account verified! Redirecting to login...'),
            backgroundColor: AppColors.success,
          ),
        );
        _redirectTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) context.go('/login');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account is not yet verified. Please check your email and click the link.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.show(context, title: 'Info', message: e.toString(), type: SnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerified) return _buildSuccessState(context);
    if (_isWaiting) return _buildWaitingState(context);
    return _buildRequestState(context);
  }

  Widget _buildRequestState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
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
                'Verification Required',
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.email != null
                    ? 'Click the button below to receive a verification link at\n${widget.email}'
                    : 'Click the button below to receive a verification link.',
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Send Verification Email',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Back to Login',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Waiting for Activation')),
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
                'Check Your Email',
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We have sent a verification link to ${widget.email}.\n\nPlease check your inbox and click the link to activate your account. Then return here to check your status.',
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Check User Status',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Go to Login',
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Didn\'t receive the email? Check your spam folder 📬',
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
                'Account Verified!',
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.successDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your email has been successfully verified.\nYou will be redirected to the login screen in 5 seconds...',
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _redirectTimer?.cancel();
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Go to Login Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
