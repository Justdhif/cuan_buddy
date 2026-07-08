import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../providers/wallet_provider.dart';
import '../widgets/wallet_form_sheet.dart';
import '../../../../core/constants/app_constants.dart';

class ManageWalletsScreen extends ConsumerStatefulWidget {
  const ManageWalletsScreen({super.key, this.isOnboarding = false});
  final bool isOnboarding;

  @override
  ConsumerState<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends ConsumerState<ManageWalletsScreen> {
  void _showWalletForm(BuildContext context, {Map<String, dynamic>? wallet}) {
    AppBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (context) => WalletFormSheet(initialWallet: wallet),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteWallet),
        content: Text(l10n.deleteWalletConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(walletsProvider.notifier).deleteWallet(id);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(walletsProvider);
    final wallets = state.valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconShape = ref.watch(categoryIconShapeProvider);

    return Scaffold(
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              title: Text(l10n.manageWallets),
              actions: [
                IconButton(
                  onPressed: () => _showWalletForm(context),
                  icon: const Icon(Icons.add_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isOnboarding)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.step2of2,
                      style: AppTypography.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.addWallet,
                      style: AppTypography.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your initial wallets or bank accounts.',
                      style: AppTypography.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: state.isLoading && wallets.isEmpty
                  ? const _WalletSkeletonLoader()
                  : wallets.isEmpty
                      ? Center(
                          child: Text('No wallets found.',
                              style: AppTypography.textTheme.bodyMedium),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              top: 16, left: 16, right: 16, bottom: 80),
                          itemCount: wallets.length,
                          itemBuilder: (context, index) {
                            final wallet = wallets[index];
                            final emoji = wallet['emojiIcon'] ?? '💼';
                            final colorCode = wallet['colorCode'] as String?;
                            final backgroundColor = AppColors.colorFromHex(colorCode, fallback: AppColors.primary);

                                final currencyCode = wallet['currency'] as String? ?? 'USD';
                                final symbol = AppConstants.supportedCurrencies.firstWhere((c) => c['code'] == currencyCode, orElse: () => {'symbol': currencyCode})['symbol'];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.cardDark
                                        : AppColors.cardLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: ShapeDecoration(
                                        color: backgroundColor.withValues(alpha: 0.15),
                                        shape: iconShape == CategoryIconShape.circle
                                            ? const CircleBorder()
                                            : iconShape == CategoryIconShape.squircle
                                                ? ContinuousRectangleBorder(borderRadius: BorderRadius.circular(20))
                                                : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    title: Text(wallet['name'] ?? '',
                                        style: AppTypography.textTheme.labelLarge),
                                    subtitle: Text(
                                      '$symbol${wallet['balance'] ?? '0.00'}',
                                      style: AppTypography.textTheme.bodySmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _showWalletForm(context,
                                          wallet: wallet),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20, color: Colors.red),
                                      onPressed: () =>
                                          _confirmDelete(context, ref, wallet['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (widget.isOnboarding)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: AppButton(
                  label: l10n.finishAndStart,
                  onPressed: () {
                    context.go('/dashboard');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WalletSkeletonLoader extends StatefulWidget {
  const _WalletSkeletonLoader();

  @override
  State<_WalletSkeletonLoader> createState() => _WalletSkeletonLoaderState();
}

class _WalletSkeletonLoaderState extends State<_WalletSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.85)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
      itemCount: 4,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Opacity(
            opacity: _anim.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: baseColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.5),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                              color: baseColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 8),
                      Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                              color: baseColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6))),
                    ],
                  ),
                  const Spacer(),
                  Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.5),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 16),
                  Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.5),
                          shape: BoxShape.circle)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
