import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/empty_state.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('EmptyState', () {
    testWidgets('muestra el title', (tester) async {
      await tester.pumpWidget(wrap(
        const EmptyState(title: 'Sin productos'),
      ));

      expect(find.text('Sin productos'), findsOneWidget);
    });

    testWidgets('muestra subtitle cuando se provee', (tester) async {
      await tester.pumpWidget(wrap(
        const EmptyState(title: 'Sin ventas', subtitle: 'Registrá tu primera venta'),
      ));

      expect(find.text('Sin ventas'), findsOneWidget);
      expect(find.text('Registrá tu primera venta'), findsOneWidget);
    });

    testWidgets('no muestra subtitle cuando es null', (tester) async {
      await tester.pumpWidget(wrap(
        const EmptyState(title: 'Sin datos'),
      ));

      expect(find.text('Sin datos'), findsOneWidget);
      // Solo un Text visible (el title)
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('muestra icono inbox', (tester) async {
      await tester.pumpWidget(wrap(
        const EmptyState(title: 'Vacío'),
      ));

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });
  });
}
