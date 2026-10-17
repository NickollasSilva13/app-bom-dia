import 'package:shared_preferences/shared_preferences.dart';

/// Premium removes the watermark and unlocks templates with `"premium": true`.
abstract class SubscriptionService {
  bool get isPremium;

  /// Price label shown on the paywall.
  String get priceLabel;

  /// Starts the purchase. Returns the new premium state.
  Future<bool> purchase();

  Future<bool> restore();

  /// Test-only: drop premium again (shown in the fake paywall).
  Future<void> reset();
}

/// Stores the flag locally; no store involved.
// TODO(subscription): Replace with a RevenueCat-backed service
// (purchases_flutter): configure the API key, fetch the "premium"
// entitlement on startup and listen to CustomerInfo updates.
class FakeSubscriptionService implements SubscriptionService {
  FakeSubscriptionService(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'subscription.isPremium';

  @override
  bool get isPremium => _prefs.getBool(_key) ?? false;

  @override
  String get priceLabel => 'R\$ 4,90 por mês';

  @override
  Future<bool> purchase() async {
    await _prefs.setBool(_key, true);
    return true;
  }

  @override
  Future<bool> restore() async => isPremium;

  @override
  Future<void> reset() => _prefs.setBool(_key, false);
}
