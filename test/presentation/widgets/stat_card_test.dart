import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/app/theme.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/stat_card.dart';

// StatCard usa Expanded internamente → necesita padre Row
Widget wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Row(children: [child]),
      ),
    );

void main() {
  group('StatCard', () {
    testWidgets('muestra label y value', (tester) async {
      await tester.pumpWidget(wrap(
        const StatCard(label: 'Ventas hoy', value: '5'),
      ));

      expect(find.text('Ventas hoy'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('muestra value con texto largo (truncado)', (tester) async {
      await tester.pumpWidget(wrap(
        const StatCard(label: 'Ingresos', value: '1.000.000 \$'),
      ));

      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('1.000.000 \$'), findsOneWidget);
    });

    testWidgets('sin valueColor usa color por defecto', (tester) async {
      await tester.pumpWidget(wrap(
        const StatCard(label: 'Stock bajo', value: '3'),
      ));

      final valueText = tester.widget<Text>(find.text('3'));
      expect(valueText.style?.color, AppColors.textPrimary);
    });

    testWidgets('valueColor personalizado se aplica al value', (tester) async {
      await tester.pumpWidget(wrap(
        const StatCard(
          label: 'Stock bajo',
          value: '3',
          valueColor: AppColors.danger,
        ),
      ));

      final valueText = tester.widget<Text>(find.text('3'));
      expect(valueText.style?.color, AppColors.danger);
    });
  });
}
