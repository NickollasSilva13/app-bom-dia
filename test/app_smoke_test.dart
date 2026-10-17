import 'dart:convert';
import 'dart:io';

import 'package:bom_dia/app/app.dart';
import 'package:bom_dia/app/providers.dart';
import 'package:bom_dia/domain/catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _app(Map<String, Object> prefsValues) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 14, 7)),
      // Asset I/O does not complete under the test's fake clock; read the files directly.
      catalogProvider.overrideWith((ref) => TemplateCatalog(
            templates: TemplateCatalog.parseTemplates(
                jsonDecode(File('assets/templates/catalog.json').readAsStringSync())),
            phrases: PhraseBook.fromJson(jsonDecode(File('assets/templates/phrases.json').readAsStringSync())
                as Map<String, dynamic>),
          )),
    ],
    child: const BomDiaApp(),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('primeira abertura pergunta a cidade', (tester) async {
    await tester.pumpWidget(await _app({}));
    await tester.pumpAndSettle();
    expect(find.text('Qual é a sua cidade?'), findsOneWidget);
    expect(find.text('Agora não'), findsOneWidget);
  });

  testWidgets('tela Hoje mostra o card e os botões', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(await _app({
      'settings.onboardingDone': true,
      'recipients': '[{"id":"1","name":"Dona Cida","birthDate":null}]',
    }));
    await tester.pumpAndSettle();

    expect(find.text('Enviar no WhatsApp'), findsOneWidget);
    expect(find.text('Trocar'), findsOneWidget);
    expect(find.text('Dona Cida'), findsOneWidget);
    expect(find.text('Adicionar'), findsOneWidget);

    await tester.tap(find.text('Dona Cida'));
    await tester.pump();
    await tester.tap(find.text('Trocar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
