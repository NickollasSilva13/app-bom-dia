import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/provider_logger.dart';
import 'app/providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();
  try {
    await notifications.init();
  } catch (e) {
    debugPrint('[Notifications] init falhou: $e');
  }

  runApp(ProviderScope(
    observers: const [ProviderLogger()],
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
    child: const BomDiaApp(),
  ));
}
