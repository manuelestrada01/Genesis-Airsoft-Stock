import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/search_bar_widget.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// SearchBarWidget evalúa _controller.text en build() pero no llama setState.
/// En producción el padre (InventoryScreen + Riverpod) lo reconstruye.
/// En tests, usamos StatefulBuilder para simular ese comportamiento.
Widget wrapRebuildable({required ValueChanged<String> onChanged}) {
  return MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (_, setState) => SearchBarWidget(
          onChanged: (v) {
            setState(() {});
            onChanged(v);
          },
        ),
      ),
    ),
  );
}

void main() {
  group('SearchBarWidget', () {
    testWidgets('muestra placeholder por defecto', (tester) async {
      await tester.pumpWidget(wrap(
        SearchBarWidget(onChanged: (_) {}),
      ));

      expect(find.text('Buscar producto...'), findsOneWidget);
    });

    testWidgets('placeholder personalizado', (tester) async {
      await tester.pumpWidget(wrap(
        SearchBarWidget(
          onChanged: (_) {},
          placeholder: 'Buscar venta...',
        ),
      ));

      expect(find.text('Buscar venta...'), findsOneWidget);
    });

    testWidgets('muestra ícono de búsqueda', (tester) async {
      await tester.pumpWidget(wrap(
        SearchBarWidget(onChanged: (_) {}),
      ));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('sin texto → no muestra botón clear', (tester) async {
      await tester.pumpWidget(wrap(
        SearchBarWidget(onChanged: (_) {}),
      ));

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('tipear texto → onChanged se llama', (tester) async {
      String? received;
      await tester.pumpWidget(wrap(
        SearchBarWidget(onChanged: (v) => received = v),
      ));

      await tester.enterText(find.byType(TextField), 'ak47');
      await tester.pump();

      expect(received, 'ak47');
    });

    testWidgets('con texto → muestra botón clear', (tester) async {
      await tester.pumpWidget(wrapRebuildable(onChanged: (_) {}));

      await tester.enterText(find.byType(TextField), 'glock');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('tap en clear → limpia campo y llama onChanged("")', (tester) async {
      String? received;
      await tester.pumpWidget(wrapRebuildable(onChanged: (v) => received = v));

      await tester.enterText(find.byType(TextField), 'glock');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsNothing);
      expect(received, '');
    });

    testWidgets('tap en clear → campo queda vacío', (tester) async {
      await tester.pumpWidget(wrapRebuildable(onChanged: (_) {}));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller?.text, '');
    });
  });
}
