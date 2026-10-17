import 'package:flutter/foundation.dart';

abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object> parameters = const {}]);

  Future<void> appOpen() => logEvent('app_open');

  Future<void> cardGenerated({required String occasion, required String templateId}) =>
      logEvent('card_generated', {'occasion': occasion, 'template_id': templateId});

  Future<void> cardShared({
    required String occasion,
    required String templateId,
    required String target,
  }) =>
      logEvent('card_shared', {'occasion': occasion, 'template_id': templateId, 'target': target});

  Future<void> cardSwapped({required String occasion}) =>
      logEvent('card_swapped', {'occasion': occasion});

  Future<void> recipientAdded({required bool hasBirthDate}) =>
      logEvent('recipient_added', {'has_birth_date': hasBirthDate ? 1 : 0});

  Future<void> paywallViewed({required String source}) =>
      logEvent('paywall_viewed', {'source': source});
}

/// Prints events to the log. Never sends names or other personal data.
// TODO(analytics): Add FirebaseAnalyticsService (firebase_core +
// firebase_analytics) implementing logEvent with
// FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters).
class LogAnalyticsService extends AnalyticsService {
  @override
  Future<void> logEvent(String name, [Map<String, Object> parameters = const {}]) async {
    debugPrint('[Analytics] $name $parameters');
  }
}
