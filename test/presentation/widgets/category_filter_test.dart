import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/product_category.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/category_filter.dart';

Widget wrap({
  Object? selected,
  required ValueChanged<Object?> onSelect,
  bool showLowStock = false,
}) =>
    MaterialApp(
      home: Scaffold(
        body: CategoryFilter(
          selected: selected,
          onSelect: onSelect,
          showLowStock: showLowStock,
        ),
      ),
    );

void main() {
  group('CategoryFilter', () {
    testWidgets('siempre muestra chip "Todos"', (tester) async {
      await tester.pumpWidget(wrap(selected: null, onSelect: (_) {}));
      await tester.pump();

      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('muestra chips de todas las categorías', (tester) async {
      // Viewport amplio para que ListView horizontal renderice todos los chips
      tester.view.physicalSize = const Size(4000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(selected: null, onSelect: (_) {}));
      await tester.pump();

      for (final cat in ProductCategory.values) {
        expect(find.text(cat.label), findsOneWidget,
            reason: 'Chip para ${cat.label} no encontrado');
      }
    });

    testWidgets('sin showLowStock → no muestra "Stock bajo"', (tester) async {
      await tester.pumpWidget(wrap(selected: null, onSelect: (_) {}));
      await tester.pump();

      expect(find.text('Stock bajo'), findsNothing);
    });

    testWidgets('showLowStock=true → muestra "Stock bajo"', (tester) async {
      // Viewport amplio para renderizar el chip al final
      tester.view.physicalSize = const Size(4000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(
        selected: null,
        onSelect: (_) {},
        showLowStock: true,
      ));
      await tester.pump();

      expect(find.text('Stock bajo'), findsOneWidget);
    });

    testWidgets('tap en "Todos" llama onSelect(null)', (tester) async {
      Object? received = 'initial';

      await tester.pumpWidget(wrap(
        selected: ProductCategory.marcadorasAEG,
        onSelect: (v) => received = v,
      ));
      await tester.pump();

      await tester.tap(find.text('Todos'));
      await tester.pump();

      expect(received, isNull);
    });

    testWidgets('tap en primera categoría visible llama onSelect', (tester) async {
      Object? received;

      await tester.pumpWidget(wrap(
        selected: null,
        onSelect: (v) => received = v,
      ));
      await tester.pump();

      // 'Insumos' es la primera categoría en ProductCategory.values
      await tester.tap(find.text(ProductCategory.insumos.label));
      await tester.pump();

      expect(received, ProductCategory.insumos);
    });

    testWidgets('tap en "Stock bajo" llama onSelect("lowStock")', (tester) async {
      tester.view.physicalSize = const Size(4000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Object? received;

      await tester.pumpWidget(wrap(
        selected: null,
        onSelect: (v) => received = v,
        showLowStock: true,
      ));
      await tester.pump();

      await tester.tap(find.text('Stock bajo'));
      await tester.pump();

      expect(received, 'lowStock');
    });
  });
}
