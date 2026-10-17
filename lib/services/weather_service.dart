import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/weather.dart';

/// Open-Meteo forecast and geocoding. No API key needed.
class OpenMeteoApi {
  OpenMeteoApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  /// Short: the first card waits for this before showing.
  static const _timeout = Duration(seconds: 5);

  Future<Weather> currentWeather(CityLocation city, {DateTime? now}) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': city.latitude.toStringAsFixed(4),
      'longitude': city.longitude.toStringAsFixed(4),
      'current': 'temperature_2m,weather_code',
      'timezone': 'America/Sao_Paulo',
    });
    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('Open-Meteo respondeu ${response.statusCode}', uri);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    return Weather(
      city: city.name,
      temperature: (current['temperature_2m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      fetchedAt: now ?? DateTime.now(),
    );
  }

  /// Cities matching [query], Brazilian ones first.
  Future<List<CityLocation>> searchCity(String query) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query.trim(),
      'count': '10',
      'language': 'pt',
      'format': 'json',
    });
    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('Geocodificação respondeu ${response.statusCode}', uri);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (json['results'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) {
        final aBr = a['country_code'] == 'BR' ? 0 : 1;
        final bBr = b['country_code'] == 'BR' ? 0 : 1;
        return aBr.compareTo(bBr);
      });
    return [
      for (final r in results)
        CityLocation(
          name: r['name'] as String,
          region: r['country_code'] == 'BR'
              ? r['admin1'] as String?
              : [r['admin1'], r['country']].whereType<String>().join(', '),
          latitude: (r['latitude'] as num).toDouble(),
          longitude: (r['longitude'] as num).toDouble(),
        ),
    ];
  }
}

/// Current weather with a 3-hour cache in SharedPreferences.
/// When the network fails, an older cached reading (up to 12 h) is used;
/// otherwise there is no weather and the card simply hides that line.
class WeatherRepository {
  WeatherRepository(this._prefs, this._api, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final OpenMeteoApi _api;
  final DateTime Function() _clock;

  static const cacheTtl = Duration(hours: 3);
  static const staleLimit = Duration(hours: 12);
  static const _cacheKey = 'weather.cache';

  Future<Weather?> current(CityLocation? city, {bool forceRefresh = false}) async {
    if (city == null) return null;
    final now = _clock();
    final cached = _readCache(city);
    if (!forceRefresh && cached != null && now.difference(cached.fetchedAt) < cacheTtl) {
      return cached;
    }
    try {
      final fresh = await _api.currentWeather(city, now: now);
      await _prefs.setString(
        _cacheKey,
        jsonEncode({'key': city.cacheKey, 'weather': fresh.toJson()}),
      );
      return fresh;
    } catch (e) {
      debugPrint('[Weather] falhou: $e');
      if (cached != null && now.difference(cached.fetchedAt) < staleLimit) return cached;
      return null;
    }
  }

  Weather? _readCache(CityLocation city) {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['key'] != city.cacheKey) return null;
      final w = Weather.fromJson(json['weather'] as Map<String, dynamic>);
      // The user may have renamed the city; keep the label current.
      return Weather(city: city.name, temperature: w.temperature, weatherCode: w.weatherCode, fetchedAt: w.fetchedAt);
    } catch (_) {
      return null;
    }
  }
}
