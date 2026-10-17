import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

abstract class AdsService {
  /// Called only after the card was handed to WhatsApp or the share sheet,
  /// never before. Shows an interstitial at most once every
  /// [AppConfig.sharesPerInterstitial] shares.
  Future<void> onCardShared({required bool isPremium});
}

/// Logs instead of showing ads.
// TODO(ads): Add AdMob (google_mobile_ads) with an AdMobAdsService that
// preloads an InterstitialAd and shows it when the app returns to the
// foreground after sharing. Keep the same frequency rule.
class FakeAdsService implements AdsService {
  FakeAdsService(this._prefs, {this.enabled = AppConfig.adsEnabled});

  final SharedPreferences _prefs;
  final bool enabled;
  static const _countKey = 'ads.sharesSinceInterstitial';

  @override
  Future<void> onCardShared({required bool isPremium}) async {
    if (!enabled || isPremium) return;
    final count = (_prefs.getInt(_countKey) ?? 0) + 1;
    if (count >= AppConfig.sharesPerInterstitial) {
      debugPrint('[Ads] mostraria intersticial');
      await _prefs.setInt(_countKey, 0);
    } else {
      await _prefs.setInt(_countKey, count);
    }
  }
}
