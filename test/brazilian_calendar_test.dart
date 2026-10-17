import 'package:bom_dia/domain/occasion.dart';
import 'package:bom_dia/services/brazilian_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calendar = BrazilianCalendar();

  group('datas móveis 2025–2030', () {
    // year: [Páscoa, Carnaval (terça), Corpus Christi]
    final expected = <int, List<DateTime>>{
      2025: [DateTime(2025, 4, 20), DateTime(2025, 3, 4), DateTime(2025, 6, 19)],
      2026: [DateTime(2026, 4, 5), DateTime(2026, 2, 17), DateTime(2026, 6, 4)],
      2027: [DateTime(2027, 3, 28), DateTime(2027, 2, 9), DateTime(2027, 5, 27)],
      2028: [DateTime(2028, 4, 16), DateTime(2028, 2, 29), DateTime(2028, 6, 15)],
      2029: [DateTime(2029, 4, 1), DateTime(2029, 2, 13), DateTime(2029, 5, 31)],
      2030: [DateTime(2030, 4, 21), DateTime(2030, 3, 5), DateTime(2030, 6, 20)],
    };

    expected.forEach((year, dates) {
      test('$year', () {
        expect(BrazilianCalendar.easterSunday(year), dates[0]);
        expect(BrazilianCalendar.carnival(year), dates[1]);
        expect(BrazilianCalendar.carnival(year).weekday, DateTime.tuesday);
        expect(BrazilianCalendar.corpusChristi(year), dates[2]);
        expect(BrazilianCalendar.corpusChristi(year).weekday, DateTime.thursday);
        expect(BrazilianCalendar.goodFriday(year).weekday, DateTime.friday);
      });
    });
  });

  test('Dia das Mães é o 2º domingo de maio', () {
    expect(BrazilianCalendar.mothersDay(2025), DateTime(2025, 5, 11));
    expect(BrazilianCalendar.mothersDay(2026), DateTime(2026, 5, 10));
    expect(BrazilianCalendar.mothersDay(2027), DateTime(2027, 5, 9));
    expect(BrazilianCalendar.mothersDay(2028), DateTime(2028, 5, 14));
    expect(BrazilianCalendar.mothersDay(2029), DateTime(2029, 5, 13));
    expect(BrazilianCalendar.mothersDay(2030), DateTime(2030, 5, 12));
  });

  test('Dia dos Pais é o 2º domingo de agosto', () {
    expect(BrazilianCalendar.fathersDay(2025), DateTime(2025, 8, 10));
    expect(BrazilianCalendar.fathersDay(2026), DateTime(2026, 8, 9));
    expect(BrazilianCalendar.fathersDay(2027), DateTime(2027, 8, 8));
    expect(BrazilianCalendar.fathersDay(2028), DateTime(2028, 8, 13));
    expect(BrazilianCalendar.fathersDay(2029), DateTime(2029, 8, 12));
    expect(BrazilianCalendar.fathersDay(2030), DateTime(2030, 8, 11));
  });

  test('feriados nacionais fixos', () {
    for (final (m, d) in [(1, 1), (4, 21), (5, 1), (9, 7), (10, 12), (11, 2), (11, 15), (11, 20), (12, 25)]) {
      expect(calendar.isNationalHoliday(DateTime(2026, m, d)), isTrue, reason: '$d/$m');
    }
    expect(calendar.isNationalHoliday(DateTime(2026, 3, 10)), isFalse);
  });

  test('12/10: Dia das Crianças vem antes do feriado', () {
    final events = calendar.eventsOn(DateTime(2026, 10, 12));
    expect(events.map((e) => e.occasion), [Occasion.diaDasCriancas, Occasion.feriado]);
  });

  test('Finados não gera cartão festivo', () {
    final events = calendar.eventsOn(DateTime(2026, 11, 2));
    expect(events.single.occasion, isNull);
  });

  test('datas comemorativas', () {
    Occasion? first(DateTime d) => calendar.eventsOn(d).first.occasion;
    expect(first(DateTime(2026, 6, 12)), Occasion.diaDosNamorados);
    expect(first(DateTime(2026, 7, 26)), Occasion.diaDosAvos);
    expect(first(DateTime(2026, 12, 25)), Occasion.natal);
    expect(first(DateTime(2027, 1, 1)), Occasion.anoNovo);
    expect(first(DateTime(2026, 2, 16)), Occasion.carnaval);
  });
}
