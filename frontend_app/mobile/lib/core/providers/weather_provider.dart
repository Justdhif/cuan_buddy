import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/weather_service.dart';
import '../l10n/app_localizations.dart';
import 'language_provider.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final weatherProvider = FutureProvider.autoDispose<WeatherData?>((ref) async {
  final languageCode = ref.watch(languageProvider);
  final service = ref.watch(weatherServiceProvider);
  return service.getWeather(languageCode: languageCode);
});
