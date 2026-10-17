import 'dart:io';

import 'package:bom_dia/domain/card_template.dart';
import 'package:bom_dia/domain/occasion.dart';
import 'package:bom_dia/domain/weather.dart';
import 'package:bom_dia/render/card_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Fixed template for the golden test, independent of catalog.json.
final _template = CardTemplate(
  id: 'golden-01',
  occasions: const [Occasion.generico],
  background: TemplateBackground(
    type: BackgroundType.gradient,
    colors: [parseHexColor('#FDE68A'), parseHexColor('#F59E0B')],
    angle: 135,
  ),
  overlays: const [TemplateOverlay(color: 0xFF000000, opacity: 0.15)],
  decorations: const [
    TemplateDecoration(type: DecorationType.circle, x: 0.2, y: 0.25, size: 0.18, color: 0xFFFFFFFF, opacity: 0.35),
  ],
  slots: [
    TemplateSlot(type: SlotType.greeting, text: 'Bom dia, {nome}!', font: 'GreatVibes', color: 0xFFFFFFFF,
        box: const FractionBox(0.08, 0.12, 0.84, 0.18), shadow: true, maxFontSize: 120),
    const TemplateSlot(type: SlotType.phrase, font: 'PlayfairDisplay', color: 0xFFFFFFFF,
        box: FractionBox(0.1, 0.42, 0.8, 0.25), shadow: true, maxFontSize: 64),
    const TemplateSlot(type: SlotType.date, format: "EEEE, d 'de' MMMM", font: 'Montserrat', color: 0xFFFFFFFF,
        box: FractionBox(0.1, 0.78, 0.8, 0.06), maxFontSize: 44, weight: 600),
    const TemplateSlot(type: SlotType.weather, format: '{cidade} • {temp}°C', font: 'Montserrat', color: 0xFFFFFFFF,
        box: FractionBox(0.1, 0.85, 0.8, 0.05), maxFontSize: 40, weight: 600),
    TemplateSlot(type: SlotType.watermark, text: 'Feito com o app Bom Dia', font: 'Montserrat',
        color: parseHexColor('#FFFFFFAA'), box: const FractionBox(0.55, 0.95, 0.42, 0.03),
        align: SlotAlign.right, maxFontSize: 24),
  ],
);

final _content = CardContent(
  template: _template,
  recipientName: 'Dona Cida',
  phrase: 'Que seu dia seja leve e cheio de coisas boas.',
  date: DateTime(2026, 10, 16),
  weather: Weather(city: 'Recife', temperature: 28, weatherCode: 1, fetchedAt: DateTime(2026, 10, 16, 6)),
);

Future<void> _loadFont(String family, String file) async {
  final bytes = File('assets/fonts/$file').readAsBytesSync();
  final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    await _loadFont('GreatVibes', 'GreatVibes-Regular.ttf');
    await _loadFont('PlayfairDisplay', 'PlayfairDisplay.ttf');
    await _loadFont('Montserrat', 'Montserrat.ttf');
    await _loadFont('Pacifico', 'Pacifico-Regular.ttf');
  });

  const renderer = CardRenderer();

  test('textos dos slots', () {
    String? text(SlotType type, [CardContent? c]) =>
        renderer.textForSlot(_template.slots.firstWhere((s) => s.type == type), c ?? _content);

    expect(text(SlotType.greeting), 'Bom dia, Dona Cida!');
    expect(text(SlotType.date), 'Sexta-feira, 16 de outubro');
    expect(text(SlotType.weather), 'Recife • 28°C');
    expect(text(SlotType.watermark), 'Feito com o app Bom Dia');

    final bare = CardContent(
      template: _template,
      recipientName: '',
      phrase: 'x',
      date: DateTime(2026, 10, 16),
      showWatermark: false,
    );
    expect(text(SlotType.greeting, bare), 'Bom dia!');
    expect(text(SlotType.weather, bare), isNull);
    expect(text(SlotType.watermark, bare), isNull);
  });

  testWidgets('exporta PNG em 1080×1350', (tester) async {
    final bytes = await tester.runAsync(() => renderer.renderPng(_content));
    expect(bytes, isNotNull);
    // PNG signature, then IHDR width/height (big endian) at bytes 16..23.
    expect(bytes!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    final header = ByteData.sublistView(bytes, 16, 24);
    expect(header.getUint32(0), 1080);
    expect(header.getUint32(4), 1350);
  });

  testWidgets('golden: card fixo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(540, 675));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: const Key('card'),
          child: SizedBox(
            width: 540,
            height: 675,
            child: CustomPaint(painter: CardPainter(_content)),
          ),
        ),
      ),
    );
    await expectLater(find.byKey(const Key('card')), matchesGoldenFile('goldens/card_golden_01.png'));
  });
}
