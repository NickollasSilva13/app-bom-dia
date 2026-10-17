import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/recipient_repository.dart';
import '../data/settings_repository.dart';
import '../data/template_repository.dart';
import '../domain/catalog.dart';
import '../domain/recipient.dart';
import '../domain/weather.dart';
import '../render/card_renderer.dart';
import '../services/ads_service.dart';
import '../services/analytics_service.dart';
import '../services/app_config.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/share_service.dart';
import '../services/subscription_service.dart';
import '../services/template_selector.dart';
import '../services/weather_service.dart';

// ---------------------------------------------------------------- services

/// Overridden in main() with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider precisa de override'),
);

/// Overridden in main() with an initialized instance.
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final analyticsProvider = Provider<AnalyticsService>((ref) => LogAnalyticsService());

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  // TODO(subscription): return the RevenueCat service when !AppConfig.useFakeSubscription.
  return FakeSubscriptionService(ref.watch(sharedPreferencesProvider));
});

final adsServiceProvider = Provider<AdsService>((ref) {
  // TODO(ads): return the AdMob service when !AppConfig.useFakeAds.
  return FakeAdsService(ref.watch(sharedPreferencesProvider));
});

final shareServiceProvider = Provider<ShareService>((ref) => const ShareService());

final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());

final openMeteoApiProvider = Provider<OpenMeteoApi>((ref) => OpenMeteoApi());

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) => WeatherRepository(
      ref.watch(sharedPreferencesProvider),
      ref.watch(openMeteoApiProvider),
      clock: ref.watch(clockProvider),
    ));

final templateRepositoryProvider = Provider<TemplateRepository>((ref) => TemplateRepository(
      local: AssetTemplateSource(),
      remote: AppConfig.remoteCatalogEnabled ? RemoteTemplateSource() : null,
    ));

const cardRenderer = CardRenderer();

// ---------------------------------------------------------------- state

class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(subscriptionServiceProvider).isPremium;

  Future<bool> purchase() async => state = await ref.read(subscriptionServiceProvider).purchase();

  Future<void> reset() async {
    await ref.read(subscriptionServiceProvider).reset();
    state = false;
  }
}

final premiumProvider = NotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  late SettingsRepository _repo;

  @override
  AppSettings build() {
    _repo = SettingsRepository(ref.watch(sharedPreferencesProvider));
    return _repo.load();
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    await _repo.save(settings);
    await _syncNotification();
  }

  Future<void> _syncNotification() async {
    final service = ref.read(notificationServiceProvider);
    try {
      if (state.notificationsEnabled) {
        await service.scheduleDaily(hour: state.notificationHour, minute: state.notificationMinute);
      } else {
        await service.cancelDaily();
      }
    } catch (_) {
      // Notifications are a nice-to-have; never block the settings change.
    }
  }

  Future<void> resync() => _syncNotification();
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class RecipientsNotifier extends Notifier<List<Recipient>> {
  late RecipientRepository _repo;

  @override
  List<Recipient> build() {
    _repo = RecipientRepository(ref.watch(sharedPreferencesProvider));
    return _repo.load();
  }

  Future<Recipient> add({required String name, DateTime? birthDate}) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(1 << 16)}';
    final recipient = Recipient(id: id, name: name.trim(), birthDate: birthDate);
    state = [...state, recipient];
    await _repo.save(state);
    return recipient;
  }

  Future<void> edit(Recipient updated) async {
    state = [for (final r in state) r.id == updated.id ? updated : r];
    await _repo.save(state);
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _repo.save(state);
  }
}

final recipientsProvider =
    NotifierProvider<RecipientsNotifier, List<Recipient>>(RecipientsNotifier.new);

/// Which chip is selected on the home screen. Null means no name on the card.
class SelectedRecipientNotifier extends Notifier<String?> {
  static const _key = 'home.selectedRecipient';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_key);

  void select(String? id) {
    state = id;
    final prefs = ref.read(sharedPreferencesProvider);
    if (id == null) {
      prefs.remove(_key);
    } else {
      prefs.setString(_key, id);
    }
  }
}

final selectedRecipientIdProvider =
    NotifierProvider<SelectedRecipientNotifier, String?>(SelectedRecipientNotifier.new);

final selectedRecipientProvider = Provider<Recipient?>((ref) {
  final id = ref.watch(selectedRecipientIdProvider);
  if (id == null) return null;
  return ref.watch(recipientsProvider).where((r) => r.id == id).firstOrNull;
});

final catalogProvider = FutureProvider<TemplateCatalog>(
  (ref) => ref.watch(templateRepositoryProvider).load(),
);

final selectorProvider = FutureProvider<TemplateSelector>((ref) async {
  final catalog = await ref.watch(catalogProvider.future);
  return TemplateSelector(templates: catalog.templates, phrases: catalog.phrases);
});

class WeatherNotifier extends AsyncNotifier<Weather?> {
  @override
  Future<Weather?> build() {
    final city = ref.watch(settingsProvider.select((s) => s.city));
    return ref.read(weatherRepositoryProvider).current(city);
  }

  Future<void> refresh() async {
    final city = ref.read(settingsProvider).city;
    state = AsyncData(await ref.read(weatherRepositoryProvider).current(city, forceRefresh: true));
  }
}

final weatherProvider = AsyncNotifierProvider<WeatherNotifier, Weather?>(WeatherNotifier.new);

/// How many times "Trocar" was tapped. Resets when the recipient changes.
class SwapNotifier extends Notifier<int> {
  @override
  int build() {
    ref.watch(selectedRecipientIdProvider);
    return 0;
  }

  void next() => state++;
}

final swapProvider = NotifierProvider<SwapNotifier, int>(SwapNotifier.new);

/// Today's card. Waits for the first weather reading (cached, or a network
/// call capped by [OpenMeteoApi]'s timeout) so the card does not change in
/// front of the user when rain or heat arrives a moment later.
final todayCardProvider = Provider<AsyncValue<CardOption>>((ref) {
  final weather = ref.watch(weatherProvider);
  if (weather.isLoading && !weather.hasValue) return const AsyncLoading();
  final selector = ref.watch(selectorProvider);
  return selector.whenData((s) {
    return s.select(
      date: ref.watch(clockProvider)(),
      weather: ref.watch(weatherProvider).value,
      recipient: ref.watch(selectedRecipientProvider),
      swap: ref.watch(swapProvider),
      includePremium: ref.watch(premiumProvider),
    );
  });
});

/// Decodes a `background.image` asset. [width] downsamples it (null keeps the
/// full size, used only for the exported PNG).
Future<ui.Image> decodeAssetImage(String path, {int? width}) async {
  final data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

/// Photo backgrounds for on-screen previews, decoded at [width] pixels to keep
/// memory low in the gallery. Released when no card shows them.
final backgroundImageProvider =
    FutureProvider.autoDispose.family<ui.Image, ({String path, int width})>((ref, key) async {
  final image = await decodeAssetImage(key.path, width: key.width);
  ref.onDispose(image.dispose);
  return image;
});
