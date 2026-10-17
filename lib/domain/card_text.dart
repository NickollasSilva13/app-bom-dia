import 'weather.dart';

/// Replaces `{nome}` in a greeting. With an empty name the comma goes too:
/// "Bom dia, {nome}!" becomes "Bom dia!".
String fillName(String pattern, String name) {
  final trimmed = name.trim();
  if (trimmed.isNotEmpty) return pattern.replaceAll('{nome}', trimmed);
  return pattern
      .replaceAll(RegExp(r'\s*,?\s*\{nome\}'), '')
      .replaceAll(RegExp(r'\s+([!?.,])'), r'$1')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}

/// Fills `{cidade}`, `{temp}` and `{icone}`. Without a city name the city
/// part and its separator are dropped.
String formatWeather(String pattern, Weather weather) {
  var text = pattern;
  if (weather.city.trim().isEmpty) {
    text = text.replaceAll(RegExp(r'\{cidade\}\s*[•·\-|,]?\s*'), '');
  }
  return text
      .replaceAll('{cidade}', weather.city.trim())
      .replaceAll('{temp}', '${weather.roundedTemperature}')
      .replaceAll('{icone}', weather.icon)
      .trim();
}

/// "quinta-feira, 16 de outubro" -> "Quinta-feira, 16 de outubro".
String capitalizeFirst(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
