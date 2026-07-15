import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/screens/create_product_screen.dart';

import '../../helpers/mock_repositories.dart';

void suppressOverflow() {
  final saved = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    saved?.call(details);
  };
  addTearDown(() => FlutterError.onError = saved);
}

Widget buildScreen({MockProductRepository? repo}) {
  return MaterialApp(
    home: CreateProductScreen(repo: repo ?? MockProductRepository()),
  );
}

void main() {
  group('CreateProductScreen', () {
    testWidgets('muestra "Crear producto" en el header', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Both header and bottomSheet show "Crear producto"
      expect(find.text('Crear producto'), findsWidgets);
    });

    testWidgets('muestra campo de nombre con hint', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Nombre *'), findsOneWidget);
      expect(find.text('Ej: ARCTURUS LWT MK-II CQB'), findsOneWidget);
    });

    testWidgets('muestra dropdown de categoría', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Categoría *'), findsOneWidget);
      expect(find.text('Seleccionar categoría'), findsOneWidget);
    });

    testWidgets('muestra campos de precio costo y descuento', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Precio de costo *'), findsOneWidget);
      expect(find.text('Descuento %'), findsOneWidget);
    });

    testWidgets('muestra campo de precio de venta', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Precio de venta *'), findsOneWidget);
    });

    testWidgets('nombre vacío → error "El nombre es obligatorio."', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.text('Crear producto').last);
      await tester.pump();

      expect(find.text('El nombre es obligatorio.'), findsOneWidget);
    });

    testWidgets('sin categoría → error "Seleccioná una categoría."', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Enter a name first
      await tester.enterText(find.byType(TextField).first, 'AK-47');
      await tester.pump();

      await tester.tap(find.text('Crear producto').last);
      await tester.pump();

      expect(find.text('Seleccioná una categoría.'), findsOneWidget);
    });

    testWidgets('precio costo = 0 → error sobre precio', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Enter name
      await tester.enterText(find.byType(TextField).first, 'AK-47');
      await tester.pump();

      // Select category from dropdown
      await tester.tap(find.text('Seleccionar categoría'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcadoras AEG').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear producto').last);
      await tester.pump();

      expect(find.text('El precio de costo debe ser mayor a 0.'), findsOneWidget);
    });

    testWidgets('precio venta = 0 → error sobre precio de venta', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Enter name
      await tester.enterText(find.byType(TextField).first, 'AK-47');
      await tester.pump();

      // Select category
      await tester.tap(find.text('Seleccionar categoría'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcadoras AEG').last);
      await tester.pumpAndSettle();

      // Enter cost price — TextField index 1 (after name)
      await tester.enterText(find.byType(TextField).at(1), '5000');
      await tester.pump();

      // finalPrice auto-computed but leave it as 0 by manually clearing it
      // Find the finalPrice field (index 3: name=0, price=1, discount=2, finalPrice=3)
      await tester.enterText(find.byType(TextField).at(3), '0');
      await tester.pump();

      await tester.tap(find.text('Crear producto').last);
      await tester.pump();

      expect(find.text('El precio de venta debe ser mayor a 0.'), findsOneWidget);
    });

    testWidgets('precio costo auto-calcula precio de venta (sin descuento)', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // TextField indices: name=0, price=1, discount=2, finalPrice=3, stock=4, desc=5
      await tester.enterText(find.byType(TextField).at(1), '10000');
      await tester.pump();

      final finalPriceField = tester.widget<TextField>(find.byType(TextField).at(3));
      expect(finalPriceField.controller?.text, '10000');
    });

    testWidgets('descuento 10% → precio de venta = 90% del costo', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(1), '10000');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(2), '10');
      await tester.pump();

      final finalPriceField = tester.widget<TextField>(find.byType(TextField).at(3));
      expect(finalPriceField.controller?.text, '9000');
    });

    testWidgets('muestra aviso sobre imágenes del panel web', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(
        find.textContaining('imágenes se pueden agregar desde el panel web'),
        findsOneWidget,
      );
    });
  });
}
