import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/expense.dart';
import 'package:genesis_airsoft_stock/domain/entities/product.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';
import 'package:genesis_airsoft_stock/presentation/providers/expenses_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/products_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/sales_provider.dart';
import 'package:genesis_airsoft_stock/presentation/screens/home_screen.dart';

import '../../helpers/test_factories.dart';

/// Suppresses RenderFlex overflow errors. Call inside testWidgets body AFTER
/// the test framework sets its own error handler (which happens before the callback).
/// QuickActionCard has a known overflow in the test font environment (fixed card
/// size too small for fallback font text metrics).
void suppressOverflow() {
  final saved = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    saved?.call(details);
  };
  addTearDown(() => FlutterError.onError = saved);
}

Widget buildHome({
  List<Sale> sales = const [],
  List<Product> products = const [],
  List<Expense> expenses = const [],
  bool loading = false,
}) {
  return ProviderScope(
    overrides: [
      allProductsProvider.overrideWith(
        (_) => loading ? const Stream.empty() : Stream.value(products),
      ),
      allSalesProvider.overrideWith(
        (_) => loading ? const Stream.empty() : Stream.value(sales),
      ),
      allExpensesProvider.overrideWith(
        (_) => loading ? const Stream.empty() : Stream.value(expenses),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

// Pump past SalesLineChart AnimationController (1000ms) + Future.delayed (150+80ms)
Future<void> pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  group('HomeScreen', () {
    testWidgets('muestra "Genesis Airsoft" en el header', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildHome());
      await pump(tester);

      expect(find.text('Genesis Airsoft'), findsOneWidget);
    });

    testWidgets('muestra acciones rápidas', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildHome());
      await pump(tester);

      expect(find.text('Registrar Venta'), findsOneWidget);
      expect(find.text('Registrar Gasto'), findsOneWidget);
      expect(find.text('Ver Inventario'), findsOneWidget);
    });

    testWidgets('estado de carga → stat cards no visibles', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildHome(loading: true));
      await tester.pump();

      expect(find.text('Ventas hoy'), findsNothing);
      expect(find.text('Stock bajo'), findsNothing);
    });

    testWidgets('datos cargados → muestra etiquetas de stat cards', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildHome());
      await pump(tester);

      expect(find.text('Ventas hoy'), findsOneWidget);
      expect(find.text('Stock bajo'), findsOneWidget);
      expect(find.text('Producto estrella'), findsOneWidget);
      expect(find.text('Facturación del mes'), findsOneWidget);
    });

    testWidgets('sin ventas de hoy → stat card muestra "0"', (tester) async {
      suppressOverflow();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(buildHome(
        sales: [makeSale(createdAt: yesterday)],
      ));
      await pump(tester);

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('venta de hoy → "Ventas hoy" muestra 1', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildHome(
        sales: [makeSale(createdAt: DateTime.now())],
      ));
      await pump(tester);

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('producto con stock bajo → "Stock bajo" muestra 1', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildHome(
        products: [
          makeProduct(id: 'p1', stock: 3),
          makeProduct(id: 'p2', stock: 10),
        ],
      ));
      await pump(tester);

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('sin ventas del mes → "Producto estrella" muestra "—"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildHome());
      await pump(tester);

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('venta del mes → "Producto estrella" muestra nombre', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildHome(
        sales: [makeSale(productName: 'Glock 17', createdAt: DateTime.now())],
      ));
      await pump(tester);

      expect(find.text('Glock 17'), findsOneWidget);
    });
  });
}
