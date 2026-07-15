import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:genesis_airsoft_stock/domain/entities/balance_period.dart';
import 'package:genesis_airsoft_stock/domain/entities/expense.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';
import 'package:genesis_airsoft_stock/presentation/providers/balance_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/sales_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/expenses_provider.dart';
import 'package:genesis_airsoft_stock/presentation/screens/balance_detail_screen.dart';

import '../../helpers/test_factories.dart';

void suppressOverflow() {
  final saved = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    saved?.call(details);
  };
  addTearDown(() => FlutterError.onError = saved);
}

Widget buildScreen({
  List<Sale> sales = const [],
  List<Expense> expenses = const [],
  bool loading = false,
}) {
  final period = CustomRange(from: DateTime(2000), to: DateTime(2100));
  return ProviderScope(
    overrides: [
      periodProvider.overrideWith((ref) => period),
      allSalesProvider.overrideWith(
        (_) => loading ? const Stream.empty() : Stream.value(sales),
      ),
      allExpensesProvider.overrideWith(
        (_) => loading ? const Stream.empty() : Stream.value(expenses),
      ),
    ],
    child: const MaterialApp(home: BalanceDetailScreen()),
  );
}

Future<void> pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
  });

  group('BalanceDetailScreen', () {
    testWidgets('muestra "Detalle del balance" en el header', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await pump(tester);

      expect(find.text('Detalle del balance'), findsOneWidget);
    });

    testWidgets('estado de carga → muestra CircularProgressIndicator', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(loading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra etiqueta "Balance" en BalanceCard', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await pump(tester);

      expect(find.text('Balance'), findsOneWidget);
    });

    testWidgets('muestra etiqueta "Ingresos" en BalanceCard', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await pump(tester);

      expect(find.text('Ingresos'), findsOneWidget);
    });

    testWidgets('muestra etiqueta "Egresos" en BalanceCard', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await pump(tester);

      expect(find.text('Egresos'), findsOneWidget);
    });

    testWidgets('muestra sección "Ganancia"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await pump(tester);

      expect(find.text('Ganancia'), findsWidgets);
    });

    testWidgets('muestra cards de métodos de pago (Efectivo, Tarjeta)', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await pump(tester);

      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('Tarjeta'), findsOneWidget);
    });

    testWidgets('ventas cargadas → ingresos no son cero', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(
        sales: [makeSale(total: 8000)],
      ));
      await pump(tester);

      // BalanceCard shows income as formatted currency — should not be "$ 0"
      expect(find.text(r'$ 0'), findsNothing);
    });

    testWidgets('tap en GananciaCard colapsa el detalle', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await pump(tester);

      // GananciaCard starts expanded — tap header to collapse
      await tester.tap(find.text('Ganancia').first);
      await tester.pumpAndSettle();

      // After collapse, detail text should not be visible
      expect(find.text('Ganancia estimada'), findsNothing);
    });

    testWidgets('muestra ícono de back en el header', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await pump(tester);

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });
  });
}
