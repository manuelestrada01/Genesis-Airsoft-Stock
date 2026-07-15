import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/app/theme.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/tab_selector.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('TabSelector', () {
    testWidgets('muestra todos los tabs', (tester) async {
      await tester.pumpWidget(wrap(TabSelector(
        tabs: const ['Ingresos', 'Egresos'],
        activeIndex: 0,
        onSelect: (_) {},
      )));

      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Egresos'), findsOneWidget);
    });

    testWidgets('tab activo tiene color primario', (tester) async {
      await tester.pumpWidget(wrap(TabSelector(
        tabs: const ['Ingresos', 'Egresos'],
        activeIndex: 0,
        onSelect: (_) {},
      )));

      final activeText = tester.widget<Text>(find.text('Ingresos'));
      expect(activeText.style?.color, AppColors.textPrimary);
      expect(activeText.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('tab inactivo tiene color secundario', (tester) async {
      await tester.pumpWidget(wrap(TabSelector(
        tabs: const ['Ingresos', 'Egresos'],
        activeIndex: 0,
        onSelect: (_) {},
      )));

      final inactiveText = tester.widget<Text>(find.text('Egresos'));
      expect(inactiveText.style?.color, AppColors.textSecondary);
      expect(inactiveText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('tap en tab llama onSelect con índice correcto', (tester) async {
      int? selected;
      await tester.pumpWidget(wrap(TabSelector(
        tabs: const ['Ingresos', 'Egresos'],
        activeIndex: 0,
        onSelect: (i) => selected = i,
      )));

      await tester.tap(find.text('Egresos'));
      await tester.pump();

      expect(selected, 1);
    });

    testWidgets('tap en tab activo llama onSelect(0)', (tester) async {
      int? selected;
      await tester.pumpWidget(wrap(TabSelector(
        tabs: const ['Ingresos', 'Egresos'],
        activeIndex: 0,
        onSelect: (i) => selected = i,
      )));

      await tester.tap(find.text('Ingresos'));
      await tester.pump();

      expect(selected, 0);
    });

    testWidgets('funciona con 3 tabs', (tester) async {
      int? selected;
      await tester.pumpWidget(wrap(TabSelector(
        tabs: const ['A', 'B', 'C'],
        activeIndex: 1,
        onSelect: (i) => selected = i,
      )));

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      await tester.tap(find.text('C'));
      await tester.pump();
      expect(selected, 2);
    });

    testWidgets('activeIndex=1 marca el segundo tab como activo', (tester) async {
      await tester.pumpWidget(wrap(TabSelector(
        tabs: const ['Ingresos', 'Egresos'],
        activeIndex: 1,
        onSelect: (_) {},
      )));

      final activeText = tester.widget<Text>(find.text('Egresos'));
      expect(activeText.style?.fontWeight, FontWeight.w700);

      final inactiveText = tester.widget<Text>(find.text('Ingresos'));
      expect(inactiveText.style?.fontWeight, FontWeight.w500);
    });
  });
}
