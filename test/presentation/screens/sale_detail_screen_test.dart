import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';
import 'package:genesis_airsoft_stock/presentation/screens/sale_detail_screen.dart';

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

Widget buildScreen(Sale sale, {MockSaleRepository? repo}) {
  return MaterialApp(
    home: SaleDetailScreen(
      sale: sale,
      repo: repo ?? MockSaleRepository(),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
  });

  group('SaleDetailScreen', () {
    testWidgets('muestra "Detalle de venta" en el header', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale()));
      await tester.pump();

      expect(find.text('Detalle de venta'), findsOneWidget);
    });

    testWidgets('nombre del producto pre-cargado en el campo', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale(productName: 'AK-47 AEG')));
      await tester.pump();

      expect(find.text('AK-47 AEG'), findsOneWidget);
    });

    testWidgets('muestra botón de estado "Pagado"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale(status: SaleStatus.paid)));
      await tester.pump();

      expect(find.text('Pagado'), findsOneWidget);
    });

    testWidgets('muestra botón de estado "Deuda"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale()));
      await tester.pump();

      expect(find.text('Deuda'), findsOneWidget);
    });

    testWidgets('muestra labels de métodos de pago', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale()));
      await tester.pump();

      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('Tarjeta'), findsOneWidget);
      expect(find.text('Transferencia'), findsOneWidget);
    });

    testWidgets('muestra "Guardar cambios" en el bottomSheet', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale()));
      await tester.pump();

      expect(find.text('Guardar cambios'), findsOneWidget);
    });

    testWidgets('muestra ícono de eliminar', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale()));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('tap en eliminar → muestra diálogo de confirmación', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale()));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar venta'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('tap en Cancelar del diálogo → cierra sin eliminar', (tester) async {
      suppressOverflow();
      final repo = MockSaleRepository();
      await tester.pumpWidget(buildScreen(makeSale(), repo: repo));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar venta'), findsNothing);
    });

    testWidgets('nombre vacío → muestra error al guardar', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale()));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();

      await tester.tap(find.text('Guardar cambios'));
      await tester.pump();

      expect(find.text('El nombre no puede estar vacío.'), findsOneWidget);
    });

    testWidgets('tap en + aumenta la cantidad', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale(quantity: 1)));
      await tester.pump();

      await tester.tap(find.text('+'));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('tap en − con qty=1 no disminuye', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildScreen(makeSale(quantity: 1)));
      await tester.pump();

      await tester.tap(find.text('−'));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });
  });
}
