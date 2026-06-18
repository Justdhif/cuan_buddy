import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/providers/core_providers.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('id', null);
  await initializeDateFormatting('en', null);

  final sharedPreferences = await SharedPreferences.getInstance();
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const CuanBuddyApp(),
    ),
  );
}

class CuanBuddyApp extends ConsumerWidget {
  const CuanBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final languageCode = ref.watch(languageProvider);
    final l10n = AppLocalizations.forLocale(languageCode);

    return AppLocalizationsScope(
      localizations: l10n,
      child: MaterialApp.router(
        title: 'CuanBuddy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: Locale(languageCode),
        supportedLocales: const [Locale('en'), Locale('id')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
        builder: (context, child) {
          // Clamp text scale to prevent very large/small text from breaking layout
          final mediaQuery = MediaQuery.of(context);
          final clampedScale = mediaQuery.textScaler
              .scale(1.0)
              .clamp(0.85, 1.3);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(clampedScale),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
