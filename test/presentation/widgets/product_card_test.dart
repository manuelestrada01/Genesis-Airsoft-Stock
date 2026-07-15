import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/product.dart';
import 'package:genesis_airsoft_stock/domain/entities/product_category.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/product_card.dart';

import '../../helpers/test_factories.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ProductCard', () {
    testWidgets('muestra el nombre del producto', (tester) async {
      final product = makeProduct(name: 'AK-47 AEG');

      await tester.pumpWidget(wrap(
        ProductCard(product: product, onPress: (_) {}),
      ));

      expect(find.text('AK-47 AEG'), findsOneWidget);
    });

    testWidgets('muestra el label de categoría', (tester) async {
      final product = makeProduct(category: ProductCategory.marcadorasAEG);

      await tester.pumpWidget(wrap(
        ProductCard(product: product, onPress: (_) {}),
      ));

      expect(find.text(ProductCategory.marcadorasAEG.label), findsOneWidget);
    });

    testWidgets('muestra el precio formateado (finalPrice)', (tester) async {
      final product = makeProduct(price: 50000, finalPrice: 50000);

      await tester.pumpWidget(wrap(
        ProductCard(product: product, onPress: (_) {}),
      ));

      expect(find.textContaining('50.000'), findsOneWidget);
    });

    testWidgets('usa price cuando finalPrice es NaN', (tester) async {
      final product = makeProduct(price: 40000, finalPrice: double.nan);

      await tester.pumpWidget(wrap(
        ProductCard(product: product, onPress: (_) {}),
      ));

      expect(find.textContaining('40.000'), findsOneWidget);
    });

    testWidgets('muestra "Pausado" cuando paused=true', (tester) async {
      final product = makeProduct(paused: true);

      await tester.pumpWidget(wrap(
        ProductCard(product: product, onPress: (_) {}),
      ));

      expect(find.text('Pausado'), findsOneWidget);
    });

    testWidgets('no muestra "Pausado" cuando paused=false', (tester) async {
      final product = makeProduct(paused: false);

      await tester.pumpWidget(wrap(
        ProductCard(product: product, onPress: (_) {}),
      ));

      expect(find.text('Pausado'), findsNothing);
    });

    testWidgets('muestra el stock en StockBadge', (tester) async {
      final product = makeProduct(stock: 7);

      await tester.pumpWidget(wrap(
        ProductCard(product: product, onPress: (_) {}),
      ));

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('onPress se llama con el producto al tocar', (tester) async {
      final product = makeProduct(id: 'p-test', name: 'Glock 17');
      Product? received;

      await tester.pumpWidget(wrap(
        ProductCard(product: product, onPress: (p) => received = p),
      ));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(received?.id, 'p-test');
      expect(received?.name, 'Glock 17');
    });

    testWidgets('sin cover → muestra placeholder (icon)', (tester) async {
      final product = makeProduct(cover: '');

      await tester.pumpWidget(wrap(
        ProductCard(product: product, onPress: (_) {}),
      ));

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });
  });
}
