import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/screens/debts_screen.dart';

Widget wrap() => const MaterialApp(home: DebtsScreen());

void main() {
  group('DebtsScreen', () {
    testWidgets('muestra título "Deudas"', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('Deudas'), findsOneWidget);
    });

    testWidgets('muestra "Próximamente"', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('Próximamente'), findsOneWidget);
    });

    testWidgets('muestra ícono receipt_long', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    });
  });
}
