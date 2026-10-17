import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The daily "your card is ready" notification, in São Paulo time.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const _dailyId = 1;
  static const _channelId = 'bom_dia_diario';
  static const timeZone = 'America/Sao_Paulo';
  static const message = 'Seu bom dia de hoje está pronto ☀️';

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(timeZone));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Asks for POST_NOTIFICATIONS on Android 13+. True when allowed.
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? true;

  /// Replaces any previous schedule with one at [hour]:[minute] every day.
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await init();
    await _plugin.cancel(id: _dailyId);
    final now = tz.TZDateTime.now(tz.getLocation(timeZone));
    var next = tz.TZDateTime(now.location, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _dailyId,
      title: 'Bom Dia',
      body: message,
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Bom dia diário',
          channelDescription: 'Aviso de que o cartão do dia está pronto',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      // Inexact is enough for a morning reminder and needs no exact-alarm permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    await init();
    await _plugin.cancel(id: _dailyId);
  }
}
