import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/update_stock_modal.dart';

import '../../helpers/test_factories.dart';

/// Opens the modal via showUpdateStockModal and returns the tester ready for assertions.
Widget buildTrigger({
  int stock = 10,
  double costPrice = 3000,
  double finalPrice = 5000,
  Future<void> Function(String, int)? onConfirm,
  Future<void> Function(String, int)? onSet,
  Future<void> Function(String, double)? onUpdatePrice,
  Future<void> Function(String, double)? onUpdateSalePrice,
}) {
  final product = makeProduct(
    name: 'AK-47 AEG',
    stock: stock,
    costPrice: costPrice,
    finalPrice: finalPrice,
  );
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showUpdateStockModal(
            ctx,
            product: product,
            onConfirm: onConfirm ?? (_, __) async {},
            onSet: onSet ?? (_, __) async {},
            onUpdatePrice: onUpdatePrice ?? (_, __) async {},
            onUpdateSalePrice: onUpdateSalePrice ?? (_, __) async {},
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

Future<void> openModal(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('UpdateStockModal', () {
    testWidgets('muestra nombre del producto', (tester) async {
      await tester.pumpWidget(buildTrigger());
      await openModal(tester);

      expect(find.text('AK-47 AEG'), findsOneWidget);
    });

    testWidgets('muestra stock actual', (tester) async {
      await tester.pumpWidget(buildTrigger(stock: 7));
      await openModal(tester);

      expect(find.text('Stock actual: 7'), findsOneWidget);
    });

    testWidgets('muestra tabs Agregar, Quitar, Establecer', (tester) async {
      await tester.pumpWidget(buildTrigger());
      await openModal(tester);

      expect(find.text('Agregar'), findsOneWidget);
      expect(find.text('Quitar'), findsOneWidget);
      expect(find.text('Establecer'), findsOneWidget);
    });

    testWidgets('modo por defecto → botón "Agregar stock"', (tester) async {
      await tester.pumpWidget(buildTrigger());
      await openModal(tester);

      expect(find.text('Agregar stock'), findsOneWidget);
    });

    testWidgets('tap "Quitar" → botón cambia a "Quitar stock"', (tester) async {
      await tester.pumpWidget(buildTrigger());
      await openModal(tester);

      await tester.tap(find.text('Quitar'));
      await tester.pump();

      expect(find.text('Quitar stock'), findsOneWidget);
    });

    testWidgets('tap "Establecer" → botón cambia a "Establecer stock"', (tester) async {
      await tester.pumpWidget(buildTrigger());
      await openModal(tester);

      await tester.tap(find.text('Establecer'));
      await tester.pump();

      expect(find.text('Establecer stock'), findsOneWidget);
    });

    testWidgets('campo vacío → error "Ingresa un número válido mayor a 0."', (tester) async {
      await tester.pumpWidget(buildTrigger());
      await openModal(tester);

      await tester.tap(find.text('Agregar stock'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un número válido mayor a 0.'), findsOneWidget);
    });

    testWidgets('quitar más stock del disponible → error', (tester) async {
      await tester.pumpWidget(buildTrigger(stock: 5));
      await openModal(tester);

      await tester.tap(find.text('Quitar'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '10');
      await tester.pump();

      await tester.tap(find.text('Quitar stock'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No puedes quitar más'), findsOneWidget);
    });

    testWidgets('agregar stock válido → llama onConfirm con delta correcto', (tester) async {
      String? calledId;
      int? calledDelta;
      await tester.pumpWidget(buildTrigger(
        onConfirm: (id, delta) async {
          calledId = id;
          calledDelta = delta;
        },
      ));
      await openModal(tester);

      await tester.enterText(find.byType(TextField), '3');
      await tester.pump();

      await tester.tap(find.text('Agregar stock'));
      await tester.pumpAndSettle();

      expect(calledDelta, 3);
      expect(calledId, 'prod-1');
    });

    testWidgets('quitar stock válido → llama onConfirm con delta negativo', (tester) async {
      int? calledDelta;
      await tester.pumpWidget(buildTrigger(
        stock: 10,
        onConfirm: (_, delta) async { calledDelta = delta; },
      ));
      await openModal(tester);

      await tester.tap(find.text('Quitar'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '4');
      await tester.pump();

      await tester.tap(find.text('Quitar stock'));
      await tester.pumpAndSettle();

      expect(calledDelta, -4);
    });

    testWidgets('establecer stock → llama onSet con valor', (tester) async {
      int? setValue;
      await tester.pumpWidget(buildTrigger(
        onSet: (_, val) async { setValue = val; },
      ));
      await openModal(tester);

      await tester.tap(find.text('Establecer'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '15');
      await tester.pump();

      await tester.tap(find.text('Establecer stock'));
      await tester.pumpAndSettle();

      expect(setValue, 15);
    });

    testWidgets('muestra botón Cancelar', (tester) async {
      await tester.pumpWidget(buildTrigger());
      await openModal(tester);

      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('muestra precio Costo y Venta', (tester) async {
      await tester.pumpWidget(buildTrigger(costPrice: 3000, finalPrice: 5000));
      await openModal(tester);

      expect(find.text('Costo'), findsOneWidget);
      expect(find.text('Venta'), findsOneWidget);
    });
  });
}
