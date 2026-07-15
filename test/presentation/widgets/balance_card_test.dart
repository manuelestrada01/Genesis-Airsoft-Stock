import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/balance_card.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BalanceCard', () {
    testWidgets('muestra etiquetas Balance, Ingresos, Egresos', (tester) async {
      await tester.pumpWidget(wrap(
        const BalanceCard(balance: 0, income: 0, expenses: 0),
      ));

      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Egresos'), findsOneWidget);
    });

    testWidgets('muestra valor de balance formateado', (tester) async {
      await tester.pumpWidget(wrap(
        const BalanceCard(balance: 10000, income: 15000, expenses: 5000),
      ));

      // formatCurrency(10000) contiene '10.000'
      final balanceTexts = find.textContaining('10.000');
      expect(balanceTexts, findsAtLeastNWidgets(1));
    });

    testWidgets('muestra income y expenses formateados', (tester) async {
      await tester.pumpWidget(wrap(
        const BalanceCard(balance: 7000, income: 12000, expenses: 5000),
      ));

      expect(find.textContaining('12.000'), findsOneWidget);
      expect(find.textContaining('5.000'), findsAtLeastNWidgets(1));
    });

    testWidgets('balance negativo → también se muestra', (tester) async {
      await tester.pumpWidget(wrap(
        const BalanceCard(balance: -3000, income: 2000, expenses: 5000),
      ));

      expect(find.textContaining('3.000'), findsAtLeastNWidgets(1));
    });

    testWidgets('balance=0, income=0, expenses=0 → renderiza sin error', (tester) async {
      await tester.pumpWidget(wrap(
        const BalanceCard(balance: 0, income: 0, expenses: 0),
      ));

      expect(tester.takeException(), isNull);
    });
  });
}
