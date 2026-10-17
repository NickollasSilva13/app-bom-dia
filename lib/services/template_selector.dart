import 'dart:math';

import '../domain/card_template.dart';
import '../domain/catalog.dart';
import '../domain/occasion.dart';
import '../domain/recipient.dart';
import '../domain/weather.dart';
import 'brazilian_calendar.dart';

/// One card that can be shown: a template plus the phrase to put in it.
class CardOption {
  const CardOption({required this.occasion, required this.template, required this.phrase});

  final Occasion occasion;
  final CardTemplate template;
  final String phrase;
}

/// Picks the card of the day. Pure Dart, no Flutter, so it is easy to test.
///
/// Priority: recipient's birthday > holiday or commemorative date >
/// notable weather (rain, cold, heat) > day of the week > generic.
/// Choices are deterministic for a given day and recipient.
class TemplateSelector {
  TemplateSelector({
    required List<CardTemplate> templates,
    required this.phrases,
    this.calendar = const BrazilianCalendar(),
  }) : templates = [...templates]..sort((a, b) => a.id.compareTo(b.id));

  static const coldMaxCelsius = 15.0;
  static const hotMinCelsius = 32.0;

  /// Sorted by id so the result does not depend on catalog order.
  final List<CardTemplate> templates;
  final PhraseBook phrases;
  final BrazilianCalendar calendar;

  /// Every occasion that applies to [date], highest priority first.
  /// Always ends with [Occasion.generico].
  List<Occasion> applicableOccasions({
    required DateTime date,
    Weather? weather,
    Recipient? recipient,
  }) {
    final result = <Occasion>[];
    void add(Occasion o) {
      if (!result.contains(o)) result.add(o);
    }

    if (recipient != null && recipient.isBirthday(date)) add(Occasion.aniversario);
    for (final event in calendar.eventsOn(date)) {
      if (event.occasion != null) add(event.occasion!);
    }
    if (weather != null) {
      if (weather.condition == WeatherCondition.chuva) add(Occasion.chuva);
      if (weather.temperature <= coldMaxCelsius) add(Occasion.frio);
      if (weather.temperature >= hotMinCelsius) add(Occasion.calor);
    }
    final weekday = switch (date.weekday) {
      DateTime.monday => Occasion.segunda,
      DateTime.friday => Occasion.sexta,
      DateTime.saturday => Occasion.sabado,
      DateTime.sunday => Occasion.domingo,
      _ => null,
    };
    if (weekday != null) add(weekday);
    add(Occasion.generico);
    return result;
  }

  Occasion occasionFor({required DateTime date, Weather? weather, Recipient? recipient}) =>
      applicableOccasions(date: date, weather: weather, recipient: recipient).first;

  /// Templates usable for [occasion]: those that list it, falling back to the
  /// generic ones. Templates that suit the current weather are preferred.
  List<CardTemplate> templatesFor(
    Occasion occasion, {
    WeatherCondition? condition,
    bool includePremium = false,
  }) {
    List<CardTemplate> matching(Occasion o) => templates
        .where((t) => t.occasions.contains(o) && (includePremium || !t.premium))
        .toList();

    var list = matching(occasion);
    if (list.isEmpty) list = matching(Occasion.generico);
    final byWeather = list.where((t) => t.suitsWeather(condition)).toList();
    return byWeather.isNotEmpty ? byWeather : list;
  }

  /// The card of the day. [swap] is how many times the user tapped "Trocar";
  /// each tap moves to the next option of the same occasion.
  CardOption select({
    required DateTime date,
    Weather? weather,
    Recipient? recipient,
    int swap = 0,
    bool includePremium = false,
  }) {
    final occasion = occasionFor(date: date, weather: weather, recipient: recipient);
    final options = templatesFor(
      occasion,
      condition: weather?.condition,
      includePremium: includePremium,
    );
    if (options.isEmpty) {
      throw StateError('Catálogo sem templates para ${occasion.id} nem genéricos.');
    }
    final phraseList = phrases.phrasesFor(occasion);
    final seed = daySeed(date, recipient?.id);
    final shuffledTemplates = _shuffled(options, seed);
    final shuffledPhrases = _shuffled(phraseList, seed ^ 0x5bd1e995);
    final i = swap < 0 ? 0 : swap;
    return CardOption(
      occasion: occasion,
      template: shuffledTemplates[i % shuffledTemplates.length],
      phrase: shuffledPhrases.isEmpty ? '' : shuffledPhrases[i % shuffledPhrases.length],
    );
  }

  /// One option per template for a gallery tab covering [occasions].
  /// Each template keeps the first of its occasions that belongs to the tab.
  List<CardOption> galleryOptions(
    List<Occasion> occasions, {
    required DateTime date,
    String? recipientId,
  }) {
    final result = <CardOption>[];
    for (final template in templates) {
      final occasion = template.occasions.where(occasions.contains).firstOrNull;
      if (occasion == null) continue;
      final list = phrases.phrasesFor(occasion);
      final seed = daySeed(date, '${recipientId ?? ''}|${template.id}');
      result.add(CardOption(
        occasion: occasion,
        template: template,
        phrase: list.isEmpty ? '' : list[seed % list.length],
      ));
    }
    return result;
  }

  /// Stable across runs and platforms (unlike String.hashCode): FNV-1a of
  /// "yyyy-mm-dd|recipientId".
  static int daySeed(DateTime date, String? recipientId) {
    final key = '${date.year}-${date.month}-${date.day}|${recipientId ?? ''}';
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  static List<T> _shuffled<T>(List<T> items, int seed) {
    final list = [...items];
    final random = Random(seed);
    for (var i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}
