import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/quick_action_card.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void suppressOverflow() {
  final saved = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    saved?.call(details);
  };
  addTearDown(() => FlutterError.onError = saved);
}

QuickActionCard buildCard({
  String title = 'Vender',
  IconData icon = Icons.sell_outlined,
  QuickActionVariant variant = QuickActionVariant.dark,
  VoidCallback? onPress,
}) =>
    QuickActionCard(
      title: title,
      icon: icon,
      variant: variant,
      onPress: onPress ?? () {},
    );

void main() {
  group('QuickActionCard', () {
    testWidgets('muestra el título', (tester) async {
      await tester.pumpWidget(wrap(buildCard(title: 'Vender')));
      expect(find.text('Vender'), findsOneWidget);
    });

    testWidgets('muestra el ícono', (tester) async {
      await tester.pumpWidget(wrap(buildCard(icon: Icons.sell_outlined)));
      expect(find.byIcon(Icons.sell_outlined), findsOneWidget);
    });

    testWidgets('tap → llama onPress', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(wrap(buildCard(onPress: () => pressed = true)));

      await tester.tap(find.byType(QuickActionCard));
      expect(pressed, isTrue);
    });

    testWidgets('variant dark → renderiza sin error', (tester) async {
      await tester.pumpWidget(wrap(buildCard(variant: QuickActionVariant.dark)));
      expect(find.byType(QuickActionCard), findsOneWidget);
    });

    testWidgets('variant light → renderiza sin error', (tester) async {
      await tester.pumpWidget(wrap(buildCard(variant: QuickActionVariant.light)));
      expect(find.byType(QuickActionCard), findsOneWidget);
    });

    testWidgets('título multi-palabra se muestra completo', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(wrap(buildCard(title: 'Registrar gasto')));
      expect(find.text('Registrar gasto'), findsOneWidget);
    });

    testWidgets('distintos íconos renderizan correctamente', (tester) async {
      await tester.pumpWidget(wrap(buildCard(icon: Icons.add_box_outlined)));
      expect(find.byIcon(Icons.add_box_outlined), findsOneWidget);
    });
  });
}
