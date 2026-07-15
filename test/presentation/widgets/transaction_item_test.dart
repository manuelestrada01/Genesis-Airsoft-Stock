import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/transaction_item.dart';

final _date = DateTime(2025, 6, 15, 10, 30, 0);

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
  });

  group('TransactionItem', () {
    testWidgets('muestra la descripción', (tester) async {
      await tester.pumpWidget(wrap(TransactionItem(
        isIncome: true,
        description: 'Venta AK-47',
        amount: 5000,
        date: _date,
      )));

      expect(find.text('Venta AK-47'), findsOneWidget);
    });

    testWidgets('isIncome=true → prefijo "+"', (tester) async {
      await tester.pumpWidget(wrap(TransactionItem(
        isIncome: true,
        description: 'Venta',
        amount: 5000,
        date: _date,
      )));

      expect(find.textContaining('+'), findsOneWidget);
      expect(find.textContaining('5.000'), findsOneWidget);
    });

    testWidgets('isIncome=false → prefijo "-"', (tester) async {
      await tester.pumpWidget(wrap(TransactionItem(
        isIncome: false,
        description: 'Gasto',
        amount: 2000,
        date: _date,
      )));

      expect(find.textContaining('-'), findsOneWidget);
      expect(find.textContaining('2.000'), findsOneWidget);
    });

    testWidgets('muestra detail cuando se provee', (tester) async {
      await tester.pumpWidget(wrap(TransactionItem(
        isIncome: true,
        description: 'Venta',
        amount: 1000,
        date: _date,
        detail: 'x2 unidades',
      )));

      expect(find.text('x2 unidades'), findsOneWidget);
    });

    testWidgets('no muestra detail cuando es null', (tester) async {
      await tester.pumpWidget(wrap(TransactionItem(
        isIncome: true,
        description: 'Venta',
        amount: 1000,
        date: _date,
      )));

      expect(find.text('x2 unidades'), findsNothing);
    });

    testWidgets('muestra statusLabel cuando se provee', (tester) async {
      await tester.pumpWidget(wrap(TransactionItem(
        isIncome: true,
        description: 'Venta',
        amount: 1000,
        date: _date,
        statusLabel: 'Pagado',
      )));

      expect(find.text('Pagado'), findsOneWidget);
    });

    testWidgets('no muestra statusLabel cuando es null', (tester) async {
      await tester.pumpWidget(wrap(TransactionItem(
        isIncome: true,
        description: 'Venta',
        amount: 1000,
        date: _date,
      )));

      expect(find.text('Pagado'), findsNothing);
    });

    testWidgets('onTap se invoca al tocar', (tester) async {
      var tapped = false;

      await tester.pumpWidget(wrap(TransactionItem(
        isIncome: true,
        description: 'Venta',
        amount: 1000,
        date: _date,
        onTap: () => tapped = true,
      )));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('sin onTap → no lanza excepción al tocar', (tester) async {
      await tester.pumpWidget(wrap(TransactionItem(
        isIncome: true,
        description: 'Venta',
        amount: 1000,
        date: _date,
      )));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
