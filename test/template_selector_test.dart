import 'package:bom_dia/domain/card_template.dart';
import 'package:bom_dia/domain/catalog.dart';
import 'package:bom_dia/domain/occasion.dart';
import 'package:bom_dia/domain/recipient.dart';
import 'package:bom_dia/domain/weather.dart';
import 'package:bom_dia/services/template_selector.dart';
import 'package:flutter_test/flutter_test.dart';

CardTemplate _template(String id, List<Occasion> occasions,
        {List<WeatherCondition> weather = const [], bool premium = false}) =>
    CardTemplate(
      id: id,
      occasions: occasions,
      weather: weather,
      premium: premium,
      background: const TemplateBackground(type: BackgroundType.solid, colors: [0xFFFFFFFF]),
      slots: const [],
    );

Weather _weather(double temp, {int code = 0}) =>
    Weather(city: 'Recife', temperature: temp, weatherCode: code, fetchedAt: DateTime(2026));

void main() {
  final phrases = PhraseBook({
    for (final o in Occasion.values) o: [for (var i = 0; i < 10; i++) '${o.id} $i'],
  });
  final selector = TemplateSelector(
    phrases: phrases,
    templates: [
      _template('gen-1', [Occasion.generico]),
      _template('gen-2', [Occasion.generico]),
      _template('gen-3', [Occasion.generico]),
      _template('gen-chuva', [Occasion.generico], weather: [WeatherCondition.chuva]),
      _template('gen-premium', [Occasion.generico], premium: true),
      _template('aniv-1', [Occasion.aniversario]),
      _template('aniv-2', [Occasion.aniversario]),
      _template('natal-1', [Occasion.natal]),
      _template('chuva-1', [Occasion.chuva]),
      _template('frio-1', [Occasion.frio]),
      _template('calor-1', [Occasion.calor]),
      _template('segunda-1', [Occasion.segunda]),
      _template('domingo-1', [Occasion.domingo]),
    ],
  );

  // 2026-10-14 is a Wednesday with nothing special.
  final plainWednesday = DateTime(2026, 10, 14);
  final christmas = DateTime(2026, 12, 25);
  final cida = Recipient(id: 'r1', name: 'Dona Cida', birthDate: DateTime(1950, 12, 25));

  group('prioridade da ocasião', () {
    test('aniversário vence feriado', () {
      expect(selector.occasionFor(date: christmas, recipient: cida), Occasion.aniversario);
    });

    test('feriado vence clima', () {
      expect(selector.occasionFor(date: christmas, weather: _weather(10, code: 61)), Occasion.natal);
    });

    test('clima vence dia da semana', () {
      final monday = DateTime(2026, 10, 19);
      expect(selector.occasionFor(date: monday, weather: _weather(22, code: 63)), Occasion.chuva);
      expect(selector.occasionFor(date: monday, weather: _weather(15)), Occasion.frio);
      expect(selector.occasionFor(date: monday, weather: _weather(32)), Occasion.calor);
      expect(selector.occasionFor(date: monday, weather: _weather(25)), Occasion.segunda);
    });

    test('dia da semana vence genérico', () {
      expect(selector.occasionFor(date: DateTime(2026, 10, 18)), Occasion.domingo);
      expect(selector.occasionFor(date: DateTime(2026, 10, 16)), Occasion.sexta);
      expect(selector.occasionFor(date: DateTime(2026, 10, 17)), Occasion.sabado);
    });

    test('genérico quando não há nada especial', () {
      expect(selector.occasionFor(date: plainWednesday, weather: _weather(24)), Occasion.generico);
    });

    test('aniversário só conta com data de nascimento', () {
      const semData = Recipient(id: 'r2', name: 'Grupo da família');
      expect(selector.occasionFor(date: christmas, recipient: semData), Occasion.natal);
    });

    test('nascido em 29/2 comemora em 28/2 nos anos não bissextos', () {
      final r = Recipient(id: 'r3', name: 'Zé', birthDate: DateTime(1960, 2, 29));
      expect(selector.occasionFor(date: DateTime(2027, 2, 28), recipient: r), Occasion.aniversario);
      expect(selector.occasionFor(date: DateTime(2028, 2, 28), recipient: r), isNot(Occasion.aniversario));
      expect(selector.occasionFor(date: DateTime(2028, 2, 29), recipient: r), Occasion.aniversario);
    });
  });

  group('escolha do template', () {
    test('ocasião sem template cai nos genéricos', () {
      final option = selector.select(date: DateTime(2026, 6, 12)); // namorados
      expect(option.occasion, Occasion.diaDosNamorados);
      expect(option.template.occasions, contains(Occasion.generico));
      expect(option.phrase, startsWith('dia_dos_namorados'));
    });

    test('premium só aparece para assinantes', () {
      for (var swap = 0; swap < 20; swap++) {
        final free = selector.select(date: plainWednesday, swap: swap);
        expect(free.template.premium, isFalse);
      }
      final seen = {
        for (var swap = 0; swap < 20; swap++)
          selector.select(date: plainWednesday, swap: swap, includePremium: true).template.id,
      };
      expect(seen, contains('gen-premium'));
    });

    test('prefere templates do clima atual', () {
      final rainy = _weather(22, code: 61);
      // Generic occasion on a rainy day only happens if no chuva template exists,
      // so ask the generic list directly.
      final list = selector.templatesFor(Occasion.generico, condition: rainy.condition);
      expect(list.map((t) => t.id), containsAll(['gen-1', 'gen-chuva']));
      final sunny = selector.templatesFor(Occasion.generico, condition: WeatherCondition.sol);
      expect(sunny.map((t) => t.id), isNot(contains('gen-chuva')));
    });
  });

  group('determinismo', () {
    test('mesmo dia e destinatário dão o mesmo card', () {
      final a = selector.select(date: plainWednesday, recipient: cida);
      final b = selector.select(date: DateTime(2026, 10, 14, 23, 59), recipient: cida);
      expect(a.template.id, b.template.id);
      expect(a.phrase, b.phrase);
    });

    test('não depende da ordem do catálogo', () {
      final reversed = TemplateSelector(
        phrases: phrases,
        templates: selector.templates.reversed.toList(),
      );
      final a = selector.select(date: plainWednesday, recipient: cida);
      final b = reversed.select(date: plainWednesday, recipient: cida);
      expect(a.template.id, b.template.id);
    });

    test('dias diferentes variam', () {
      final ids = {
        for (var d = 0; d < 30; d++)
          selector.select(date: DateTime(2026, 9, 1 + d)).phrase,
      };
      expect(ids.length, greaterThan(3));
    });

    test('Trocar avança para outra opção e é cíclico', () {
      final first = selector.select(date: plainWednesday);
      final second = selector.select(date: plainWednesday, swap: 1);
      expect(second.template.id, isNot(first.template.id));
      expect(second.phrase, isNot(first.phrase));
      // Templates cycle every `count` swaps and phrases every 10.
      final count = selector.templatesFor(Occasion.generico).length;
      final again = selector.select(date: plainWednesday, swap: count * 10);
      expect(again.template.id, first.template.id);
    });

    test('daySeed é estável', () {
      expect(TemplateSelector.daySeed(DateTime(2026, 1, 1), 'abc'),
          TemplateSelector.daySeed(DateTime(2026, 1, 1), 'abc'));
      expect(TemplateSelector.daySeed(DateTime(2026, 1, 1), 'abc'),
          isNot(TemplateSelector.daySeed(DateTime(2026, 1, 2), 'abc')));
    });
  });
}
