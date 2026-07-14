import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileSetupStep3 extends StatelessWidget {
  const ProfileSetupStep3({
    super.key,
    required this.walletNameController,
    required this.walletType,
    required this.walletCurrency,
    required this.walletBalance,
    required this.walletEmoji,
    required this.walletColor,
    required this.walletDecimalPrecision,
    required this.walletPresetColors,
    required this.isDark,
    required this.hintColor,
    required this.iconShape,
    required this.onWalletEmojiTap,
    required this.onWalletColorTap,
    required this.onWalletColorSelected,
    required this.onWalletTypeChanged,
    required this.onWalletDecimalPrecisionTap,
    required this.onWalletBalanceTap,
    required this.formatPreviewAmount,
    required this.getCountryForCurrency,
    required this.onWalletCurrencyChanged,
  });

  final TextEditingController walletNameController;
  final String walletType;
  final String walletCurrency;
  final double walletBalance;
  final String walletEmoji;
  final Color walletColor;
  final int walletDecimalPrecision;
  final List<Color> walletPresetColors;
  final bool isDark;
  final Color hintColor;
  final CategoryIconShape iconShape;
  final VoidCallback onWalletEmojiTap;
  final VoidCallback onWalletColorTap;
  final ValueChanged<Color> onWalletColorSelected;
  final ValueChanged<String?> onWalletTypeChanged;
  final VoidCallback onWalletDecimalPrecisionTap;
  final VoidCallback onWalletBalanceTap;
  final String Function(double) formatPreviewAmount;
  final String Function(String) getCountryForCurrency;
  final ValueChanged<String> onWalletCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Subtitle for Step 3
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.createMainWallet,
                style: AppTypography.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.createMainWalletSubtitle,
                style: AppTypography.textTheme.bodyLarge?.copyWith(color: hintColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row: Emoji Icon & Name Field
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onWalletEmojiTap,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: ShapeDecoration(
                        color: walletColor,
                        shape: iconShape.toShapeBorder(64),
                      ),
                      child: Center(
                        child: Text(
                          walletEmoji.isNotEmpty ? walletEmoji : '💼',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: l10n.walletName,
                      hint: l10n.walletNameHint,
                      controller: walletNameController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Palette Colors Selection
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onWalletColorTap,
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB3B9D6),
                          shape: BoxShape.circle,
                          border: !walletPresetColors.contains(walletColor)
                              ? Border.all(
                                  color: isDark ? Colors.white : AppColors.primary,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    ...walletPresetColors.map((color) {
                      final isSelected = walletColor == color;
                      return GestureDetector(
                        onTap: () => onWalletColorSelected(color),
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: isDark ? Colors.white : AppColors.primary,
                                    width: 3,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Wallet Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: walletType,
                dropdownColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: l10n.walletTypeLabel,
                  labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: [
                  DropdownMenuItem(value: 'cash', child: Text(l10n.walletTypeCash)),
                  DropdownMenuItem(value: 'bank', child: Text(l10n.walletTypeBank)),
                  DropdownMenuItem(value: 'e_wallet', child: Text(l10n.walletTypeEWallet)),
                  DropdownMenuItem(value: 'crypto', child: Text(l10n.walletTypeCrypto)),
                  DropdownMenuItem(value: 'other', child: Text(l10n.other)),
                ],
                onChanged: onWalletTypeChanged,
              ),
              const SizedBox(height: 24),

              // Precision & Balance Stack Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Column(
                  children: [
                    // Precision
                    InkWell(
                      onTap: onWalletDecimalPrecisionTap,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.walletDecimalPrecision,
                                style: AppTypography.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                l10n.walletDecimalBadge(walletDecimalPrecision),
                                style: AppTypography.textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    // Balance Calculator
                    InkWell(
                      onTap: onWalletBalanceTap,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.initialBalanceLabel,
                                    style: AppTypography.textTheme.labelMedium?.copyWith(
                                      color: isDark ? Colors.white54 : Colors.black45,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatPreviewAmount(walletBalance),
                                    style: AppTypography.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: isDark ? Colors.white30 : Colors.black26),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Supported Currencies Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemCount: AppConstants.supportedCurrencies.length,
                itemBuilder: (context, index) {
                  final c = AppConstants.supportedCurrencies[index];
                  final code = c['code']!;
                  final symbol = c['symbol']!;
                  final name = c['name']!;
                  final country = getCountryForCurrency(code);
                  final isSelected = walletCurrency == code;

                  return GestureDetector(
                    onTap: () => onWalletCurrencyChanged(code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.black12),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            code,
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            symbol,
                            style: AppTypography.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            country.isNotEmpty ? country : name,
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
