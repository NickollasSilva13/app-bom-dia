import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/recipient.dart';

/// Recipients live only on this device.
class RecipientRepository {
  RecipientRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'recipients';

  List<Recipient> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((r) => Recipient.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<Recipient> recipients) =>
      _prefs.setString(_key, jsonEncode([for (final r in recipients) r.toJson()]));
}
