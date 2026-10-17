import '../domain/occasion.dart';

/// A national holiday or commemorative date.
class CalendarEvent {
  const CalendarEvent({
    required this.date,
    required this.name,
    required this.occasion,
    this.isNationalHoliday = false,
  });

  final DateTime date;
  final String name;

  /// Which kind of card suits this date. Null for dates that should not get
  /// a festive card (Finados).
  final Occasion? occasion;
  final bool isNationalHoliday;
}

/// Brazilian national holidays and commemorative dates. Pure Dart.
class BrazilianCalendar {
  const BrazilianCalendar();

  /// Easter Sunday (Gregorian), anonymous Gregorian algorithm.
  static DateTime easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// Carnival Tuesday: 47 days before Easter.
  static DateTime carnival(int year) => _addDays(easterSunday(year), -47);

  static DateTime goodFriday(int year) => _addDays(easterSunday(year), -2);

  /// 60 days after Easter.
  static DateTime corpusChristi(int year) => _addDays(easterSunday(year), 60);

  /// The [n]th [weekday] (DateTime.monday..sunday) of [month].
  static DateTime nthWeekdayOfMonth(int year, int month, int weekday, int n) {
    final first = DateTime(year, month, 1);
    final offset = (weekday - first.weekday + 7) % 7;
    return DateTime(year, month, 1 + offset + 7 * (n - 1));
  }

  static DateTime mothersDay(int year) => nthWeekdayOfMonth(year, 5, DateTime.sunday, 2);

  static DateTime fathersDay(int year) => nthWeekdayOfMonth(year, 8, DateTime.sunday, 2);

  /// Every event of [year], sorted by date. On days with more than one event,
  /// the most specific card comes first (e.g. Dia das Crianças before the
  /// 12 October holiday).
  List<CalendarEvent> eventsOf(int year) {
    CalendarEvent holiday(int m, int d, String name, Occasion? o) => CalendarEvent(
          date: DateTime(year, m, d),
          name: name,
          occasion: o,
          isNationalHoliday: true,
        );
    CalendarEvent commemorative(DateTime date, String name, Occasion o) =>
        CalendarEvent(date: date, name: name, occasion: o);

    final carnivalTuesday = carnival(year);
    final events = <CalendarEvent>[
      holiday(1, 1, 'Confraternização Universal', Occasion.anoNovo),
      commemorative(_addDays(carnivalTuesday, -1), 'Segunda-feira de Carnaval', Occasion.carnaval),
      commemorative(carnivalTuesday, 'Carnaval', Occasion.carnaval),
      CalendarEvent(
        date: goodFriday(year),
        name: 'Sexta-feira Santa',
        occasion: Occasion.feriado,
        isNationalHoliday: true,
      ),
      holiday(4, 21, 'Tiradentes', Occasion.feriado),
      holiday(5, 1, 'Dia do Trabalho', Occasion.feriado),
      commemorative(mothersDay(year), 'Dia das Mães', Occasion.diaDasMaes),
      commemorative(DateTime(year, 6, 12), 'Dia dos Namorados', Occasion.diaDosNamorados),
      commemorative(corpusChristi(year), 'Corpus Christi', Occasion.feriado),
      commemorative(DateTime(year, 7, 26), 'Dia dos Avós', Occasion.diaDosAvos),
      commemorative(fathersDay(year), 'Dia dos Pais', Occasion.diaDosPais),
      holiday(9, 7, 'Independência do Brasil', Occasion.feriado),
      commemorative(DateTime(year, 10, 12), 'Dia das Crianças', Occasion.diaDasCriancas),
      holiday(10, 12, 'Nossa Senhora Aparecida', Occasion.feriado),
      // A day of remembrance: no festive card.
      holiday(11, 2, 'Finados', null),
      holiday(11, 15, 'Proclamação da República', Occasion.feriado),
      holiday(11, 20, 'Dia da Consciência Negra', Occasion.feriado),
      commemorative(DateTime(year, 12, 24), 'Véspera de Natal', Occasion.natal),
      holiday(12, 25, 'Natal', Occasion.natal),
      commemorative(DateTime(year, 12, 31), 'Véspera de Ano Novo', Occasion.anoNovo),
    ];
    // Stable sort keeps the hand-written order for same-day events.
    final indexed = events.asMap().entries.toList()
      ..sort((a, b) {
        final byDate = a.value.date.compareTo(b.value.date);
        return byDate != 0 ? byDate : a.key.compareTo(b.key);
      });
    return [for (final e in indexed) e.value];
  }

  List<CalendarEvent> eventsOn(DateTime day) => eventsOf(day.year)
      .where((e) => e.date.month == day.month && e.date.day == day.day)
      .toList();

  bool isNationalHoliday(DateTime day) => eventsOn(day).any((e) => e.isNationalHoliday);

  // Calendar arithmetic through the constructor, so DST changes never shift the day.
  static DateTime _addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);
}
