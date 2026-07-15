import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/product.dart';
import 'package:genesis_airsoft_stock/presentation/providers/products_provider.dart';
import 'package:genesis_airsoft_stock/presentation/screens/inventory_screen.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_factories.dart';

void suppressOverflow() {
  final saved = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    saved?.call(details);
  };
  addTearDown(() => FlutterError.onError = saved);
}

Widget buildInventory({
  List<Product> products = const [],
  bool loading = false,
}) {
  return ProviderScope(
    overrides: [
      // Bypass Firebase — InventoryScreen reads productRepositoryProvider during build
      productRepositoryProvider.overrideWithValue(MockProductRepository()),
      allProductsProvider.overrideWith(
        (_) => loading ? const Stream.empty() : Stream.value(products),
      ),
    ],
    child: const MaterialApp(home: InventoryScreen()),
  );
}

Future<void> pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  group('InventoryScreen', () {
    testWidgets('muestra "Inventario" en el header', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildInventory());
      await pump(tester);

      expect(find.text('Inventario'), findsOneWidget);
    });

    testWidgets('muestra botón "Crear producto"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildInventory());
      await pump(tester);

      expect(find.text('Crear producto'), findsOneWidget);
    });

    testWidgets('lista vacía → muestra EmptyState "Sin productos"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildInventory(products: []));
      await pump(tester);

      expect(find.text('Sin productos'), findsOneWidget);
    });

    testWidgets('productos cargados → muestra nombres en lista', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildInventory(
        products: [
          makeProduct(id: 'p1', name: 'AK-47 AEG'),
          makeProduct(id: 'p2', name: 'Glock 17'),
        ],
      ));
      await pump(tester);

      expect(find.text('AK-47 AEG'), findsOneWidget);
      expect(find.text('Glock 17'), findsOneWidget);
    });

    testWidgets('muestra sección "Referencias:"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildInventory(
        products: [makeProduct(id: 'p1'), makeProduct(id: 'p2')],
      ));
      await pump(tester);

      expect(find.textContaining('Referencias'), findsOneWidget);
    });

    testWidgets('estado de carga → EmptyState no visible', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildInventory(loading: true));
      await tester.pump();

      expect(find.text('Sin productos'), findsNothing);
    });

    testWidgets('muestra chip "Todos" en CategoryFilter', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildInventory());
      await pump(tester);

      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('muestra chip "Stock bajo" en CategoryFilter', (tester) async {
      suppressOverflow();
      // Stock bajo is the last chip in a horizontal ListView — need wide viewport
      tester.view.physicalSize = const Size(4000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildInventory());
      await pump(tester);

      expect(find.text('Stock bajo'), findsOneWidget);
    });

    testWidgets('muestra icono de búsqueda en header', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildInventory());
      await pump(tester);

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('tap en búsqueda → ícono cambia a search_off', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildInventory());
      await pump(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });
}
