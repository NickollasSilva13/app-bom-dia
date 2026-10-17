import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/screens/city_picker_screen.dart';
import '../ui/screens/home_shell.dart';
import 'providers.dart';
import 'theme.dart';

class BomDiaApp extends ConsumerStatefulWidget {
  const BomDiaApp({super.key});

  @override
  ConsumerState<BomDiaApp> createState() => _BomDiaAppState();
}

class _BomDiaAppState extends ConsumerState<BomDiaApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back in the foreground: re-read the weather (served from the 3-hour
    // cache when fresh) so a failed lookup or a new day gets picked up.
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(weatherProvider));
    ref.read(analyticsProvider).appOpen();
    // Keep the daily schedule in sync with the saved settings.
    if (ref.read(settingsProvider).onboardingDone) {
      ref.read(settingsProvider.notifier).resync();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingDone = ref.watch(settingsProvider.select((s) => s.onboardingDone));
    return MaterialApp(
      title: 'Bom Dia',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Never shrink text below the 18 sp minimum; allow larger system sizes.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.6),
          ),
          child: child!,
        );
      },
      home: onboardingDone ? const HomeShell() : const CityPickerScreen(onboarding: true),
    );
  }
}
