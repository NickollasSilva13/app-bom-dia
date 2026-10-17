import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/weather.dart';
import '../../services/location_service.dart';

/// Asks for the city, by location or by name. On first launch it is the only
/// onboarding screen and can be skipped.
class CityPickerScreen extends ConsumerStatefulWidget {
  const CityPickerScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends ConsumerState<CityPickerScreen> {
  final _query = TextEditingController();
  final _queryFocus = FocusNode();
  Timer? _debounce;
  bool _locating = false;
  bool _searching = false;
  String? _message;
  List<CityLocation> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  Future<void> _useLocation() async {
    setState(() {
      _locating = true;
      _message = null;
    });
    final result = await ref.read(locationServiceProvider).currentCity();
    if (!mounted) return;
    setState(() => _locating = false);
    final city = result.city;
    if (city != null) {
      await _choose(city);
      return;
    }
    setState(() {
      _message = switch (result.failure!) {
        LocationFailure.serviceDisabled =>
          'A localização do celular está desligada. Digite sua cidade abaixo.',
        LocationFailure.denied ||
        LocationFailure.deniedForever =>
          'Sem permissão de localização. Tudo bem: digite sua cidade abaixo.',
        LocationFailure.unavailable =>
          'Não conseguimos achar sua localização. Digite sua cidade abaixo.',
      };
    });
    _queryFocus.requestFocus();
  }

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 600), _search);
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.length < 2) return;
    setState(() {
      _searching = true;
      _message = null;
    });
    try {
      final results = await ref.read(openMeteoApiProvider).searchCity(q);
      if (!mounted || _query.text.trim() != q) return;
      setState(() {
        _results = results;
        if (results.isEmpty) _message = 'Nenhuma cidade encontrada com esse nome.';
      });
    } catch (_) {
      if (mounted) setState(() => _message = 'Sem internet no momento. Tente de novo mais tarde.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _choose(CityLocation? city) async {
    // Read everything up front: finishing onboarding swaps this screen for
    // the home screen, after which `ref` and `context` are no longer usable.
    final notifier = ref.read(settingsProvider.notifier);
    final notifications = ref.read(notificationServiceProvider);
    final navigator = Navigator.of(context);
    final onboarding = widget.onboarding;
    await notifier.update(ref.read(settingsProvider).copyWith(
      city: city,
      onboardingDone: true,
    ));
    if (onboarding) {
      // First launch: ask for notifications once the city question is done.
      await notifications.requestPermission();
      await notifier.resync();
    } else {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.onboarding ? 'Bom Dia ☀️' : 'Sua cidade'),
        automaticallyImplyLeading: !widget.onboarding,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Qual é a sua cidade?', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Usamos só para mostrar o clima no cartão. Ninguém mais vê.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _locating ? null : _useLocation,
            icon: _locating
                ? const SizedBox(
                    width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : const Icon(Icons.my_location, size: 26),
            label: const Text('Usar minha localização'),
          ),
          const SizedBox(height: 24),
          Text('Ou digite o nome da cidade', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _query,
            focusNode: _queryFocus,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 22),
            decoration: InputDecoration(
              hintText: 'Ex.: Campinas',
              suffixIcon: IconButton(
                iconSize: 30,
                tooltip: 'Buscar',
                icon: const Icon(Icons.search),
                onPressed: _search,
              ),
            ),
            onChanged: _onQueryChanged,
            onSubmitted: (_) => _search(),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ],
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          for (final city in _results)
            Card(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 10),
              child: ListTile(
                leading: const Icon(Icons.location_city, size: 30),
                title: Text(city.name),
                subtitle: city.region == null ? null : Text(city.region!),
                onTap: () => _choose(city),
              ),
            ),
          if (widget.onboarding) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => _choose(null),
              child: const Text('Agora não'),
            ),
          ],
        ],
      ),
    );
  }
}
