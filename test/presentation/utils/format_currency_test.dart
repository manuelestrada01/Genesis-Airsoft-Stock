import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/utils/format_currency.dart';

// es_AR: símbolo '$' al final, separador de miles '.'
// intl usa espacio de no-separación (U+202F) entre número y símbolo
// → testeamos partes relevantes, no la cadena exacta

void main() {
  group('formatCurrency', () {
    test('contiene el símbolo \$', () {
      expect(formatCurrency(1000).contains('\$'), isTrue);
    });

    test('símbolo \$ al final (es_AR)', () {
      expect(formatCurrency(1000).endsWith('\$'), isTrue);
    });

    test('0 → contiene "0" y símbolo', () {
      final result = formatCurrency(0);
      expect(result.contains('0'), isTrue);
      expect(result.contains('\$'), isTrue);
    });

    test('999 → contiene "999"', () {
      expect(formatCurrency(999).contains('999'), isTrue);
    });

    test('1000 → separador de miles con punto "1.000"', () {
      expect(formatCurrency(1000).contains('1.000'), isTrue);
    });

    test('10000 → "10.000"', () {
      expect(formatCurrency(10000).contains('10.000'), isTrue);
    });

    test('100000 → "100.000"', () {
      expect(formatCurrency(100000).contains('100.000'), isTrue);
    });

    test('1000000 → "1.000.000"', () {
      expect(formatCurrency(1000000).contains('1.000.000'), isTrue);
    });

    test('sin decimales (decimalDigits=0) — no contiene coma decimal', () {
      expect(formatCurrency(1234.56).contains(','), isFalse);
    });

    test('valor redondeado: 150999.9 → "151.000"', () {
      expect(formatCurrency(150999.9).contains('151.000'), isTrue);
    });
  });
}
