import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../card_actions.dart';
import 'city_picker_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _time(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final premium = ref.watch(premiumProvider);
    final textTheme = Theme.of(context).textTheme;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
          child: Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          section('Clima'),
          ListTile(
            leading: const Icon(Icons.location_on_outlined, size: 30),
            title: const Text('Cidade'),
            subtitle: Text(settings.city == null
                ? 'Não definida (o clima não aparece)'
                : (settings.city!.name.isEmpty ? 'Minha localização' : settings.city!.displayName)),
            trailing: const Icon(Icons.chevron_right, size: 30),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CityPickerScreen()),
            ),
          ),
          section('Aviso diário'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, size: 30),
            title: const Text('Avisar todo dia'),
            subtitle: const Text('“Seu bom dia de hoje está pronto ☀️”'),
            value: settings.notificationsEnabled,
            onChanged: (on) async {
              if (on) await ref.read(notificationServiceProvider).requestPermission();
              await notifier.update(settings.copyWith(notificationsEnabled: on));
            },
          ),
          ListTile(
            enabled: settings.notificationsEnabled,
            leading: const Icon(Icons.schedule, size: 30),
            title: const Text('Horário'),
            subtitle: Text(_time(settings.notificationHour, settings.notificationMinute)),
            trailing: const Icon(Icons.chevron_right, size: 30),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: settings.notificationHour,
                  minute: settings.notificationMinute,
                ),
                helpText: 'Horário do aviso',
                initialEntryMode: TimePickerEntryMode.input,
              );
              if (picked == null) return;
              await notifier.update(settings.copyWith(
                notificationHour: picked.hour,
                notificationMinute: picked.minute,
              ));
            },
          ),
          section('Premium'),
          if (premium)
            const ListTile(
              leading: Icon(Icons.workspace_premium, size: 30),
              title: Text('Você é Premium ✓'),
              subtitle: Text('Cartões sem marca d\'água e modelos exclusivos.'),
            )
          else
            ListTile(
              leading: const Icon(Icons.auto_awesome, size: 30),
              title: const Text('Remover marca d\'água'),
              subtitle: const Text('E liberar os modelos exclusivos'),
              trailing: const Icon(Icons.chevron_right, size: 30),
              onTap: () => openPaywall(context, ref, source: 'settings'),
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Os nomes que você cadastra ficam guardados só neste celular.',
              style: textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
