import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/balance_period.dart';

void main() {
  group('getDateRangeForPeriod — PeriodType.day', () {
    test('from es inicio del día de hoy (00:00:00)', () {
      final now = DateTime.now();
      final (from, _) = getDateRangeForPeriod(PeriodPreset(PeriodType.day));

      expect(from.year, now.year);
      expect(from.month, now.month);
      expect(from.day, now.day);
      expect(from.hour, 0);
      expect(from.minute, 0);
      expect(from.second, 0);
      expect(from.millisecond, 0);
    });

    test('to es aproximadamente ahora', () {
      final before = DateTime.now();
      final (_, to) = getDateRangeForPeriod(PeriodPreset(PeriodType.day));
      final after = DateTime.now();

      expect(to.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(to.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('getDateRangeForPeriod — PeriodType.week', () {
    test('from es aproximadamente 7 días atrás', () {
      final now = DateTime.now();
      final (from, _) = getDateRangeForPeriod(PeriodPreset(PeriodType.week));

      final diff = now.difference(from);
      // Tolerancia de 1 segundo por ejecución del test
      expect(diff.inDays, 7);
    });
  });

  group('getDateRangeForPeriod — PeriodType.month', () {
    test('from es día 1 del mes actual', () {
      final now = DateTime.now();
      final (from, _) = getDateRangeForPeriod(PeriodPreset(PeriodType.month));

      expect(from.year, now.year);
      expect(from.month, now.month);
      expect(from.day, 1);
      expect(from.hour, 0);
      expect(from.minute, 0);
    });
  });

  group('getDateRangeForPeriod — PeriodType.year', () {
    test('from es 1 de enero del año actual', () {
      final now = DateTime.now();
      final (from, _) = getDateRangeForPeriod(PeriodPreset(PeriodType.year));

      expect(from.year, now.year);
      expect(from.month, 1);
      expect(from.day, 1);
    });
  });

  group('getDateRangeForPeriod — CustomRange', () {
    test('devuelve from y to tal como se pasaron', () {
      final from = DateTime(2025, 3, 1);
      final to = DateTime(2025, 3, 31, 23, 59, 59);

      final (resultFrom, resultTo) = getDateRangeForPeriod(
        CustomRange(from: from, to: to),
      );

      expect(resultFrom, from);
      expect(resultTo, to);
    });

    test('from y to son inmutables (no modifica los valores)', () {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);
      final range = CustomRange(from: from, to: to);

      getDateRangeForPeriod(range);

      expect(range.from, from);
      expect(range.to, to);
    });
  });

  group('formatPeriodLabel', () {
    test('day → "Hoy"', () {
      expect(
        formatPeriodLabel(PeriodPreset(PeriodType.day)),
        'Hoy',
      );
    });

    test('week → "Esta semana"', () {
      expect(
        formatPeriodLabel(PeriodPreset(PeriodType.week)),
        'Esta semana',
      );
    });

    test('month → "Este mes"', () {
      expect(
        formatPeriodLabel(PeriodPreset(PeriodType.month)),
        'Este mes',
      );
    });

    test('year → "Este año"', () {
      expect(
        formatPeriodLabel(PeriodPreset(PeriodType.year)),
        'Este año',
      );
    });

    test('CustomRange → "Personalizado"', () {
      expect(
        formatPeriodLabel(CustomRange(
          from: DateTime(2025, 1, 1),
          to: DateTime(2025, 1, 31),
        )),
        'Personalizado',
      );
    });
  });
}
