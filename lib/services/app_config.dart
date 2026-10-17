/// Build-time switches for services that are still fakes in the MVP.
/// Flip them with `--dart-define`, e.g. `--dart-define=USE_FAKE_ADS=false`.
class AppConfig {
  static const useFakeAds = bool.fromEnvironment('USE_FAKE_ADS', defaultValue: true);
  static const useFakeSubscription =
      bool.fromEnvironment('USE_FAKE_SUBSCRIPTION', defaultValue: true);
  static const adsEnabled = bool.fromEnvironment('ADS_ENABLED', defaultValue: true);

  /// Remote catalog (Supabase). Off until the backend exists.
  static const remoteCatalogEnabled =
      bool.fromEnvironment('REMOTE_CATALOG', defaultValue: false);

  /// Show an interstitial at most once every this many shares.
  static const sharesPerInterstitial = 3;
}
