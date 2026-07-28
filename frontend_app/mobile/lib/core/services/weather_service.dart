import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class WeatherData {
  final double temp;
  final String description;
  final String iconCode;
  final String cityName;

  const WeatherData({
    required this.temp,
    required this.description,
    required this.iconCode,
    required this.cityName,
  });

  String get weatherEmoji {
    final code = iconCode;
    if (code.startsWith('01')) return '\u2600\ufe0f';
    if (code.startsWith('02')) return '\ud83c\udf24\ufe0f';
    if (code.startsWith('03')) return '\u26c5';
    if (code.startsWith('04')) return '\u2601\ufe0f';
    if (code.startsWith('09')) return '\ud83c\udf27\ufe0f';
    if (code.startsWith('10')) return '\ud83c\udf26\ufe0f';
    if (code.startsWith('11')) return '\u26c8\ufe0f';
    if (code.startsWith('13')) return '\u2744\ufe0f';
    if (code.startsWith('50')) return '\ud83c\udf2b\ufe0f';
    return '\ud83c\udf21\ufe0f';
  }

  Map<String, dynamic> toJson() => {
        'temp': temp,
        'description': description,
        'iconCode': iconCode,
        'cityName': cityName,
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        temp: (json['temp'] as num).toDouble(),
        description: json['description'] as String,
        iconCode: json['iconCode'] as String,
        cityName: json['cityName'] as String,
      );
}

class WeatherService {
  static const String _cacheKey = 'weather_cache';
  static const String _cacheTimestampKey = 'weather_cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 1);

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<WeatherData?> getWeather({required String languageCode}) async {
    try {
      final cached = await _getFromCache();
      if (cached != null) return cached;

      final permission = await _checkAndRequestPermission();
      if (!permission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final lang = languageCode == 'id' ? 'id' : 'en';
      final response = await _dio.get(
        '${AppConstants.weatherApiBaseUrl}/weather',
        queryParameters: {
          'lat': position.latitude,
          'lon': position.longitude,
          'appid': AppConstants.weatherApiKey,
          'units': 'metric',
          'lang': lang,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final weather = WeatherData(
          temp: (data['main']['temp'] as num).toDouble(),
          description: _capitalizeFirst(
              (data['weather'][0]['description'] as String)),
          iconCode: data['weather'][0]['icon'] as String,
          cityName: data['name'] as String? ?? '',
        );
        await _saveToCache(weather);
        return weather;
      }
    } catch (e) {
      debugPrint('[WeatherService] Error fetching weather: $e');
    }
    return null;
  }

  Future<bool> _checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<WeatherData?> _getFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheTimestampKey);
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        await prefs.remove(_cacheKey);
        await prefs.remove(_cacheTimestampKey);
        return null;
      }

      final cacheStr = prefs.getString(_cacheKey);
      if (cacheStr == null) return null;

      return WeatherData.fromJson(jsonDecode(cacheStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data.toJson()));
      await prefs.setString(
          _cacheTimestampKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (_) {}
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
