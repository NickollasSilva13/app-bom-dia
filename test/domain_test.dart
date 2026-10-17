import 'dart:convert';
import 'dart:io';

import 'package:bom_dia/domain/card_template.dart';
import 'package:bom_dia/domain/card_text.dart';
import 'package:bom_dia/domain/catalog.dart';
import 'package:bom_dia/domain/occasion.dart';
import 'package:bom_dia/domain/recipient.dart';
import 'package:bom_dia/domain/weather.dart';
import 'package:flutter_test/flutter_test.dart';

const _example = '''
{
  "id": "flores-domingo-01",
  "occasions": ["domingo", "generico", "ocasiao_do_futuro"],
  "weather": ["sol", "nublado"],
  "size": { "width": 1080, "height": 1350 },
  "background": { "type": "gradient", "colors": ["#FDE68A", "#F59E0B"], "angle": 135, "image": null },
  "overlay": { "color": "#000000", "opacity": 0.15 },
  "decorations": [ { "type": "emoji", "value": "🌻", "x": 0.85, "y": 0.1, "size": 0.12 } ],
  "slots": [
    { "type": "greeting", "text": "Bom dia, {nome}!", "font": "GreatVibes", "color": "#FFFFFF",
      "box": { "x": 0.08, "y": 0.12, "w": 0.84, "h": 0.18 }, "align": "center", "shadow": true, "maxFontSize": 120 },
    { "type": "watermark", "text": "Feito com o app Bom Dia", "font": "Montserrat", "color": "#FFFFFFAA",
      "box": { "x": 0.55, "y": 0.95, "w": 0.42, "h": 0.03 }, "align": "right", "maxFontSize": 24 }
  ]
}
''';

void main() {
  group('parseHexColor', () {
    test('RRGGBB vira opaco', () => expect(parseHexColor('#FDE68A'), 0xFFFDE68A));
    test('RRGGBBAA tem alfa no fim', () => expect(parseHexColor('#FFFFFFAA'), 0xAAFFFFFF));
    test('RGB curto', () => expect(parseHexColor('#fa0'), 0xFFFFAA00));
    test('inválida', () => expect(() => parseHexColor('#12'), throwsFormatException));
  });

  test('CardTemplate.fromJson lê o exemplo do formato', () {
    final t = CardTemplate.fromJson(jsonDecode(_example) as Map<String, dynamic>);
    expect(t.id, 'flores-domingo-01');
    expect(t.occasions, [Occasion.domingo, Occasion.generico]);
    expect(t.weather, [WeatherCondition.sol, WeatherCondition.nublado]);
    expect(t.background.type, BackgroundType.gradient);
    expect(t.background.colors, [0xFFFDE68A, 0xFFF59E0B]);
    expect(t.background.angle, 135);
    expect(t.background.image, isNull);
    expect(t.overlays.single.opacity, 0.15);
    expect(t.overlays.single.isGradient, isFalse);
    expect(t.decorations.single.value, '🌻');
    expect(t.slots.first.type, SlotType.greeting);
    expect(t.slots.first.box.w, 0.84);
    expect(t.slots.last.align, SlotAlign.right);
    expect(t.slots.last.color, 0xAAFFFFFF);
    expect(t.premium, isFalse);
  });

  test('campos para fotos: foco, véu em degradê, contorno e brilho', () {
    final t = CardTemplate.fromJson(jsonDecode('''
      {
        "id": "foto-01",
        "occasions": ["generico"],
        "background": { "type": "image", "image": "assets/photos/x.jpg", "colors": ["#333333"],
                        "focus": { "x": 0.3, "y": 0.2 } },
        "overlay": [
          { "type": "gradient", "colors": ["#00000000", "#000000B3"], "stops": [0.4, 1], "angle": 180 },
          { "color": "#000000", "opacity": 0.1 }
        ],
        "decorations": [ { "type": "sparkle", "x": 0.8, "y": 0.1, "size": 0.05 } ],
        "slots": [
          { "type": "greeting", "font": "GreatVibes", "box": { "x": 0, "y": 0, "w": 1, "h": 0.2 },
            "stroke": { "color": "#00000066", "width": 0.05 } }
        ]
      }
    ''') as Map<String, dynamic>);
    expect(t.background.type, BackgroundType.image);
    expect(t.background.focusX, 0.3);
    expect(t.background.focusY, 0.2);
    expect(t.overlays, hasLength(2));
    expect(t.overlays.first.isGradient, isTrue);
    expect(t.overlays.first.colors, [0x00000000, 0xB3000000]);
    expect(t.overlays.first.stops, [0.4, 1.0]);
    expect(t.decorations.single.type, DecorationType.sparkle);
    expect(t.slots.single.strokeColor, 0x66000000);
    expect(t.slots.single.strokeWidth, 0.05);
  });

  group('fillName', () {
    test('com nome', () => expect(fillName('Bom dia, {nome}!', 'Dona Cida'), 'Bom dia, Dona Cida!'));
    test('sem nome tira a vírgula', () => expect(fillName('Bom dia, {nome}!', ''), 'Bom dia!'));
    test('só espaços conta como vazio', () => expect(fillName('Feliz aniversário, {nome}!', '  '), 'Feliz aniversário!'));
  });

  group('formatWeather', () {
    final w = Weather(city: 'Recife', temperature: 27.6, weatherCode: 0, fetchedAt: DateTime(2026));
    test('completo', () => expect(formatWeather('{cidade} • {temp}°C {icone}', w), 'Recife • 28°C ☀️'));
    test('sem cidade', () {
      final noCity = Weather(city: '', temperature: 14.2, weatherCode: 61, fetchedAt: DateTime(2026));
      expect(formatWeather('{cidade} • {temp}°C {icone}', noCity), '14°C 🌧️');
    });
  });

  test('WMO para condição', () {
    expect(WeatherCondition.fromWmoCode(0), WeatherCondition.sol);
    expect(WeatherCondition.fromWmoCode(3), WeatherCondition.nublado);
    expect(WeatherCondition.fromWmoCode(63), WeatherCondition.chuva);
    expect(WeatherCondition.fromWmoCode(81), WeatherCondition.chuva);
    expect(WeatherCondition.fromWmoCode(95), WeatherCondition.chuva);
  });

  test('Recipient ida e volta em JSON', () {
    final r = Recipient(id: 'x', name: 'Dona Cida', birthDate: DateTime(1950, 3, 7));
    final back = Recipient.fromJson(jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>);
    expect(back.name, 'Dona Cida');
    expect(back.birthDate, DateTime(1950, 3, 7));
  });

  group('catálogo empacotado', () {
    final templates = TemplateCatalog.parseTemplates(
      jsonDecode(File('assets/templates/catalog.json').readAsStringSync()),
    );
    final phrases = PhraseBook.fromJson(
      jsonDecode(File('assets/templates/phrases.json').readAsStringSync()) as Map<String, dynamic>,
    );

    test('tem pelo menos 40 templates com ids únicos', () {
      expect(templates.length, greaterThanOrEqualTo(40));
      expect(templates.map((t) => t.id).toSet().length, templates.length);
    });

    test('toda ocasião tem template gratuito e 10+ frases', () {
      for (final o in Occasion.values) {
        expect(
          templates.any((t) => t.occasions.contains(o) && !t.premium),
          isTrue,
          reason: 'sem template para ${o.id}',
        );
        expect(phrases.phrasesFor(o).length, greaterThanOrEqualTo(10), reason: o.id);
        expect(phrases.occasions, contains(o), reason: 'frases de ${o.id}');
      }
    });

    test('todo template tem saudação e usa fontes empacotadas', () {
      const fonts = {'GreatVibes', 'PlayfairDisplay', 'Montserrat', 'Pacifico'};
      for (final t in templates) {
        expect(t.slots.any((s) => s.type == SlotType.greeting), isTrue, reason: t.id);
        for (final s in t.slots) {
          expect(fonts, contains(s.font), reason: '${t.id}: ${s.font}');
        }
      }
    });
  });
}
