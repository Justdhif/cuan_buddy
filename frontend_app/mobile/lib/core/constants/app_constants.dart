class AppConstants {
  AppConstants._();

  // ─── API ─────────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://cuan-buddy-api.vercel.app/api';
  static const String verifyEmailBaseUrl = 'https://cuan-buddy-verify-email.vercel.app';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ─── Secure Storage Keys ─────────────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // ─── SharedPreferences Keys ──────────────────────────────────────────────────
  static const String themeModeKey = 'theme_mode';
  static const String currencyCodeKey = 'currency_code';
  static const String languageKey = 'language_code';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String profileCompleteKey = 'profile_complete';
  static const String backupSetupCompleteKey = 'backup_setup_complete';
  static const String onboardingCompleteKey = 'onboarding_complete';

  // ─── Defaults ────────────────────────────────────────────────────────────────
  static const String defaultCurrency = 'IDR';
  static const String defaultCurrencySymbol = 'Rp';
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'id'];

  static const List<Map<String, String>> supportedCurrencies = [
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
  ];

  static String getCurrencySymbol(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'symbol': defaultCurrencySymbol},
    )['symbol']!;
  }

  // ─── Pagination ──────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int dashboardRecentCount = 5;

  // ─── Animation Durations ─────────────────────────────────────────────────────
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 600);
  static const Duration counterAnimation = Duration(milliseconds: 1200);

  // ─── Category Emojis ─────────────────────────────────────────────────────────
  static const Map<String, String> categoryEmojis = {
    'food': '🍔',
    'transport': '🚕',
    'entertainment': '🎮',
    'shopping': '🛍',
    'salary': '💼',
    'bonus': '🎁',
    'investment': '📈',
    'health': '💊',
    'education': '📚',
    'utilities': '⚡',
    'housing': '🏠',
    'travel': '✈️',
    'other': '💰',
  };
}
