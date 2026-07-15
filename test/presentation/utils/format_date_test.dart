import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:genesis_airsoft_stock/presentation/utils/format_date.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
  });

  // Fecha fija: 14 de julio de 2025, 15:30
  final fixedDate = DateTime(2025, 7, 14, 15, 30, 0);

  group('formatDate', () {
    test('contiene el día (14)', () {
      expect(formatDate(fixedDate), contains('14'));
    });

    test('contiene la hora (15:30)', () {
      expect(formatDate(fixedDate), contains('15:30'));
    });

    test('contiene abreviatura del mes julio', () {
      final result = formatDate(fixedDate).toLowerCase();
      expect(result, contains('jul'));
    });

    test('contiene el año corto (25)', () {
      expect(formatDate(fixedDate), contains('25'));
    });

    test('formato general dd/MMM/yy HH:mm', () {
      final result = formatDate(fixedDate);
      // Debe tener separadores /
      expect(result, contains('/'));
    });

    test('primer día del año', () {
      final d = DateTime(2025, 1, 1, 0, 0);
      final result = formatDate(d).toLowerCase();
      expect(result, contains('01'));
      expect(result, contains('ene'));
    });

    test('último día del año', () {
      final d = DateTime(2025, 12, 31, 23, 59);
      final result = formatDate(d).toLowerCase();
      expect(result, contains('31'));
      expect(result, contains('dic'));
      expect(result, contains('23:59'));
    });
  });

  group('formatShortDate', () {
    test('formato dd/MM/yyyy', () {
      final result = formatShortDate(fixedDate);
      expect(result, '14/07/2025');
    });

    test('primer día del año', () {
      expect(formatShortDate(DateTime(2025, 1, 1)), '01/01/2025');
    });

    test('no contiene hora', () {
      final result = formatShortDate(fixedDate);
      expect(result.contains(':'), isFalse);
    });

    test('año completo (4 dígitos)', () {
      expect(formatShortDate(fixedDate), contains('2025'));
    });
  });
}
