import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/application/usecases/register_sale.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/register_sale_flow.dart';

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

/// Advance frames without waiting for repeating animations to settle.
Future<void> pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Widget buildFlow({
  List? products,
  MockSaleRepository? saleRepo,
  MockProductRepository? productRepo,
}) {
  final sr = saleRepo ?? MockSaleRepository();
  final pr = productRepo ?? MockProductRepository();
  return MaterialApp(
    home: RegisterSaleFlowPage(
      products: (products ?? []).cast(),
      useCase: RegisterSale(sr, pr),
    ),
  );
}

void main() {
  group('RegisterSaleFlowPage — paso tipo', () {
    testWidgets('muestra "Nueva venta"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      expect(find.text('Nueva venta'), findsOneWidget);
    });

    testWidgets('muestra opción "Venta de productos"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      expect(find.text('Venta de productos'), findsOneWidget);
    });

    testWidgets('muestra opción "Venta libre"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      expect(find.text('Venta libre'), findsOneWidget);
    });

    testWidgets('muestra badge "Nuevo" en Cotizaciones', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      expect(find.text('Nuevo'), findsOneWidget);
    });

    testWidgets('tap "Venta de productos" → va al paso de selección', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);

      expect(find.text('Seleccionar productos'), findsOneWidget);
    });

    testWidgets('tap "Venta libre" → va al paso de venta libre', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      await tester.tap(find.text('Venta libre'));
      await pump(tester);

      expect(find.text('Venta libre'), findsWidgets);
      expect(find.text('Descripción *'), findsOneWidget);
    });
  });

  group('RegisterSaleFlowPage — flujo venta de productos', () {
    testWidgets('muestra nombre del producto en la lista', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow(
        products: [makeProduct(name: 'AK-47 AEG', stock: 5)],
      ));
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);

      expect(find.text('AK-47 AEG'), findsOneWidget);
    });

    testWidgets('muestra stock disponible del producto', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow(
        products: [makeProduct(stock: 8)],
      ));
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);

      expect(find.text('8 disponibles'), findsOneWidget);
    });

    testWidgets('tap + → contador muestra 1', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow(
        products: [makeProduct(name: 'Glock 17', stock: 5)],
      ));
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);

      await tester.tap(find.text('+'));
      await pump(tester);

      // qty = 1 appears in the counter (may also appear in stock display)
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('tap + → aparece FAB "Añadir productos"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow(
        products: [makeProduct(stock: 5)],
      ));
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);

      await tester.tap(find.text('+'));
      await pump(tester);

      expect(find.text('Añadir productos'), findsOneWidget);
    });

    testWidgets('tap FAB → va al paso de confirmar precios', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow(
        products: [makeProduct(stock: 5)],
      ));
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);

      await tester.tap(find.text('+'));
      await pump(tester);

      await tester.tap(find.text('Añadir productos'));
      await pump(tester);

      expect(find.text('Confirma precios y cantidades'), findsOneWidget);
    });

    testWidgets('paso confirm muestra nombre del producto', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow(
        products: [makeProduct(name: 'AK-47 AEG', stock: 5)],
      ));
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);
      await tester.tap(find.text('+'));
      await pump(tester);
      await tester.tap(find.text('Añadir productos'));
      await pump(tester);

      expect(find.text('AK-47 AEG'), findsOneWidget);
    });

    testWidgets('tap "Confirmar" → va al paso de pago', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow(
        products: [makeProduct(stock: 5, finalPrice: 5000)],
      ));
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);
      await tester.tap(find.text('+'));
      await pump(tester);
      await tester.tap(find.text('Añadir productos'));
      await pump(tester);
      await tester.tap(find.text('Confirmar'));
      await pump(tester);

      expect(find.text('Pagado'), findsOneWidget);
      expect(find.text('Deuda'), findsOneWidget);
    });

    testWidgets('paso pago muestra métodos de pago', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow(
        products: [makeProduct(stock: 5, finalPrice: 5000)],
      ));
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);
      await tester.tap(find.text('+'));
      await pump(tester);
      await tester.tap(find.text('Añadir productos'));
      await pump(tester);
      await tester.tap(find.text('Confirmar'));
      await pump(tester);

      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('Tarjeta'), findsOneWidget);
    });

    testWidgets('tap "Crear venta" → llama al useCase y crea venta', (tester) async {
      suppressOverflow();
      final saleRepo = MockSaleRepository();
      final productRepo = MockProductRepository();

      await tester.pumpWidget(buildFlow(
        products: [makeProduct(id: 'p1', stock: 5, finalPrice: 5000)],
        saleRepo: saleRepo,
        productRepo: productRepo,
      ));
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);
      await tester.tap(find.text('+'));
      await pump(tester);
      await tester.tap(find.text('Añadir productos'));
      await pump(tester);
      await tester.tap(find.text('Confirmar'));
      await pump(tester);
      await tester.tap(find.text('Crear venta'));
      await pump(tester);

      expect(saleRepo.createdSales.length, 1);
      expect(saleRepo.createdSales.first.saleType, SaleType.product);
      expect(productRepo.stockIncrements.length, 1);
      expect(productRepo.stockIncrements.first.$2, -1); // delta = -1
    });
  });

  group('RegisterSaleFlowPage — flujo venta libre', () {
    testWidgets('muestra campos Descripción y Monto', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      await tester.tap(find.text('Venta libre'));
      await pump(tester);

      expect(find.text('Descripción *'), findsOneWidget);
      expect(find.text('Monto *'), findsOneWidget);
    });

    testWidgets('descripción vacía → error', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      await tester.tap(find.text('Venta libre'));
      await pump(tester);

      await tester.tap(find.text('Continuar'));
      await pump(tester);

      expect(find.text('Ingresa una descripción.'), findsOneWidget);
    });

    testWidgets('monto 0 → error', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      await tester.tap(find.text('Venta libre'));
      await pump(tester);

      await tester.enterText(find.byType(TextField).first, 'Servicio');
      await pump(tester);

      await tester.tap(find.text('Continuar'));
      await pump(tester);

      expect(find.text('El monto debe ser mayor a 0.'), findsOneWidget);
    });

    testWidgets('datos válidos → va al paso de pago', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      await tester.tap(find.text('Venta libre'));
      await pump(tester);

      await tester.enterText(find.byType(TextField).first, 'Servicio BB');
      await pump(tester);
      await tester.enterText(find.byType(TextField).last, '3000');
      await pump(tester);

      await tester.tap(find.text('Continuar'));
      await pump(tester);

      expect(find.text('Pagado'), findsOneWidget);
    });

    testWidgets('tap "Crear venta" (libre) → llama useCase con SaleType.free', (tester) async {
      suppressOverflow();
      final saleRepo = MockSaleRepository();

      await tester.pumpWidget(buildFlow(saleRepo: saleRepo));
      await pump(tester);

      await tester.tap(find.text('Venta libre'));
      await pump(tester);

      await tester.enterText(find.byType(TextField).first, 'Servicio');
      await pump(tester);
      await tester.enterText(find.byType(TextField).last, '2000');
      await pump(tester);

      await tester.tap(find.text('Continuar'));
      await pump(tester);

      await tester.tap(find.text('Crear venta'));
      await pump(tester);

      expect(saleRepo.createdSales.length, 1);
      expect(saleRepo.createdSales.first.saleType, SaleType.free);
      expect(saleRepo.createdSales.first.productName, 'Servicio');
    });
  });

  group('RegisterSaleFlowPage — navegación entre pasos', () {
    testWidgets('back desde selección → vuelve al tipo', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await pump(tester);

      expect(find.text('Nueva venta'), findsOneWidget);
    });

    testWidgets('back desde libre → vuelve al tipo', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow());
      await pump(tester);

      await tester.tap(find.text('Venta libre'));
      await pump(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await pump(tester);

      expect(find.text('Nueva venta'), findsOneWidget);
    });

    testWidgets('búsqueda filtra productos por nombre', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildFlow(
        products: [
          makeProduct(id: 'p1', name: 'AK-47 AEG'),
          makeProduct(id: 'p2', name: 'Glock 17'),
        ],
      ));
      await pump(tester);

      await tester.tap(find.text('Venta de productos'));
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'Glock');
      await pump(tester);

      expect(find.text('Glock 17'), findsOneWidget);
      expect(find.text('AK-47 AEG'), findsNothing);
    });
  });
}
