import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/weather.dart';

class AppSettings {
  const AppSettings({
    this.city,
    this.notificationsEnabled = true,
    this.notificationHour = 6,
    this.notificationMinute = 0,
    this.onboardingDone = false,
  });

  final CityLocation? city;
  final bool notificationsEnabled;
  final int notificationHour;
  final int notificationMinute;

  /// The city question was answered (or skipped) on first launch.
  final bool onboardingDone;

  AppSettings copyWith({
    CityLocation? city,
    bool clearCity = false,
    bool? notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
    bool? onboardingDone,
  }) =>
      AppSettings(
        city: clearCity ? null : (city ?? this.city),
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        notificationHour: notificationHour ?? this.notificationHour,
        notificationMinute: notificationMinute ?? this.notificationMinute,
        onboardingDone: onboardingDone ?? this.onboardingDone,
      );
}

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  AppSettings load() {
    CityLocation? city;
    final rawCity = _prefs.getString('settings.city');
    if (rawCity != null) {
      try {
        city = CityLocation.fromJson(jsonDecode(rawCity) as Map<String, dynamic>);
      } catch (_) {}
    }
    return AppSettings(
      city: city,
      notificationsEnabled: _prefs.getBool('settings.notificationsEnabled') ?? true,
      notificationHour: _prefs.getInt('settings.notificationHour') ?? 6,
      notificationMinute: _prefs.getInt('settings.notificationMinute') ?? 0,
      onboardingDone: _prefs.getBool('settings.onboardingDone') ?? false,
    );
  }

  Future<void> save(AppSettings s) async {
    if (s.city == null) {
      await _prefs.remove('settings.city');
    } else {
      await _prefs.setString('settings.city', jsonEncode(s.city!.toJson()));
    }
    await _prefs.setBool('settings.notificationsEnabled', s.notificationsEnabled);
    await _prefs.setInt('settings.notificationHour', s.notificationHour);
    await _prefs.setInt('settings.notificationMinute', s.notificationMinute);
    await _prefs.setBool('settings.onboardingDone', s.onboardingDone);
  }
}
