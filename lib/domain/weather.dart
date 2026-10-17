/// Coarse weather buckets used by templates (`"weather": ["sol", "nublado"]`).
enum WeatherCondition {
  sol,
  nublado,
  chuva;

  static WeatherCondition? fromId(String id) {
    for (final c in WeatherCondition.values) {
      if (c.name == id) return c;
    }
    return null;
  }

  /// Maps a WMO weather code (as returned by Open-Meteo) to a bucket.
  static WeatherCondition fromWmoCode(int code) {
    if (code <= 1) return WeatherCondition.sol;
    if (code <= 48) return WeatherCondition.nublado;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95) {
      return WeatherCondition.chuva;
    }
    // Snow and anything unknown.
    return WeatherCondition.nublado;
  }
}

/// Emoji shown next to the temperature for a WMO weather code.
String weatherIconForCode(int code) {
  if (code == 0) return '☀️';
  if (code <= 2) return '🌤️';
  if (code == 3) return '☁️';
  if (code <= 48) return '🌫️';
  if (code >= 95) return '⛈️';
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) return '❄️';
  return '🌧️';
}

/// A place the user picked, used to ask Open-Meteo for the weather.
class CityLocation {
  const CityLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.region,
  });

  /// City name as shown on the card. May be empty when the device could not
  /// resolve a name for the user's coordinates.
  final String name;
  final String? region;
  final double latitude;
  final double longitude;

  /// Stable key used for the weather cache.
  String get cacheKey =>
      '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';

  String get displayName =>
      region == null || region!.isEmpty ? name : '$name, $region';

  factory CityLocation.fromJson(Map<String, dynamic> json) => CityLocation(
        name: json['name'] as String? ?? '',
        region: json['region'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'region': region,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class Weather {
  const Weather({
    required this.city,
    required this.temperature,
    required this.weatherCode,
    required this.fetchedAt,
  });

  final String city;

  /// Degrees Celsius.
  final double temperature;

  /// WMO weather interpretation code.
  final int weatherCode;
  final DateTime fetchedAt;

  WeatherCondition get condition => WeatherCondition.fromWmoCode(weatherCode);
  String get icon => weatherIconForCode(weatherCode);
  int get roundedTemperature => temperature.round();

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
        city: json['city'] as String? ?? '',
        temperature: (json['temperature'] as num).toDouble(),
        weatherCode: json['weatherCode'] as int,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'city': city,
        'temperature': temperature,
        'weatherCode': weatherCode,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is Weather &&
      other.city == city &&
      other.temperature == temperature &&
      other.weatherCode == weatherCode &&
      other.fetchedAt == fetchedAt;

  @override
  int get hashCode => Object.hash(city, temperature, weatherCode, fetchedAt);
}
