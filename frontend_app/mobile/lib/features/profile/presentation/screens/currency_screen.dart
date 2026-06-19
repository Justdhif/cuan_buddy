import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../providers/profile_provider.dart';

class CurrencyScreen extends ConsumerStatefulWidget {
  const CurrencyScreen({super.key});

  @override
  ConsumerState<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends ConsumerState<CurrencyScreen> {
  bool _isSavingCurrency = false;

  // Calculator states
  final _amountController = TextEditingController(text: '1');
  String _calcFromCurrency = 'USD';
  String _calcToCurrency = 'IDR';
  double? _calcResult;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).value;
      if (profile != null) {
        final currentBase = profile['currency'] as String? ?? 'IDR';
        setState(() {
          _calcFromCurrency = currentBase;
          _calcToCurrency = currentBase == 'USD' ? 'IDR' : 'USD';
        });
        _calculateConversion();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _updateBaseCurrency(String newCurrency) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSavingCurrency = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(currency: newCurrency);
      await ref.read(preferencesServiceProvider).setCurrencyCode(newCurrency);
      ref.invalidate(profileProvider);
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: l10n.currencyUpdatedTo(newCurrency),
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.failed,
          message: l10n.failedToUpdateCurrency,
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingCurrency = false);
    }
  }

  Future<void> _calculateConversion() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      setState(() => _calcResult = 0.0);
      return;
    }
    
    setState(() => _isCalculating = true);
    final currencyService = ref.read(currencyServiceProvider);
    final result = await currencyService.convert(amount, _calcFromCurrency, _calcToCurrency);
    if (mounted) {
      setState(() {
        _calcResult = result;
        _isCalculating = false;
      });
    }
  }

  Future<void> _showCurrencyPicker({
    required String currentCurrency,
    required Function(String) onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencyPickerSheet(currentCurrency: currentCurrency),
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final baseCurrency = profileAsync.value?['currency'] as String? ?? 'IDR';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.currency, style: AppTypography.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Base Currency Setting ──
            _buildSectionHeader('Base Currency'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isSavingCurrency
                  ? null
                  : () => _showCurrencyPicker(
                        currentCurrency: baseCurrency,
                        onSelected: _updateBaseCurrency,
                      ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Primary Currency', style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Used for dashboard & analytics', style: AppTypography.textTheme.bodySmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                        ],
                      ),
                    ),
                    _isSavingCurrency
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(
                            children: [
                              Text(baseCurrency, style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // ── Currency Calculator ──
            _buildSectionHeader('Currency Calculator'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _calculateConversion(),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            filled: true,
                            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () => _showCurrencyPicker(
                            currentCurrency: _calcFromCurrency,
                            onSelected: (val) {
                              setState(() => _calcFromCurrency = val);
                              _calculateConversion();
                            },
                          ),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(_calcFromCurrency, style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.swap_vert_rounded, color: AppColors.primary),
                      onPressed: () {
                        setState(() {
                          final temp = _calcFromCurrency;
                          _calcFromCurrency = _calcToCurrency;
                          _calcToCurrency = temp;
                        });
                        _calculateConversion();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          alignment: Alignment.centerLeft,
                          child: _isCalculating
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                                  _calcResult?.toStringAsFixed(2) ?? '0.00',
                                  style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () => _showCurrencyPicker(
                            currentCurrency: _calcToCurrency,
                            onSelected: (val) {
                              setState(() => _calcToCurrency = val);
                              _calculateConversion();
                            },
                          ),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(_calcToCurrency, style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // ── Live Monitoring ──
            _buildSectionHeader('Live Exchange Rates'),
            const SizedBox(height: 12),
            _buildLiveRatesSection(baseCurrency, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildLiveRatesSection(String baseCurrency, Color cardColor) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(currencyServiceProvider).getRates(baseCurrency),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rates = snapshot.data;
        if (rates == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('Failed to load exchange rates.')),
          );
        }

        final popularCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'SGD', 'AUD', 'CAD', 'CHF', 'CNY'];
        final displayCurrencies = popularCurrencies.where((c) => c != baseCurrency).take(6).toList();

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayCurrencies.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final code = displayCurrencies[index];
              final rate = rates[code] as num?;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(code.substring(0, 1), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                title: Text('1 $baseCurrency =', style: AppTypography.textTheme.bodyMedium),
                trailing: Text(
                  rate != null ? '${rate.toStringAsFixed(4)} $code' : 'N/A',
                  style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Currency Picker Sheet ────────────────────────────────────────────────────
class _CurrencyPickerSheet extends StatelessWidget {
  const _CurrencyPickerSheet({required this.currentCurrency});
  final String currentCurrency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.selectCurrency,
            style: AppTypography.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: AppConstants.supportedCurrencies.length,
              itemBuilder: (context, index) {
                final currency = AppConstants.supportedCurrencies[index];
                final isSelected = currency['code'] == currentCurrency;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, currency['code']),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              currency['symbol']!,
                              style: AppTypography.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency['code']!,
                                  style: AppTypography.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currency['name']!,
                                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
