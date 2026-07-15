import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/header.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('Header', () {
    testWidgets('muestra el título', (tester) async {
      await tester.pumpWidget(wrap(const Header(title: 'Inicio')));
      expect(find.text('Inicio'), findsOneWidget);
    });

    testWidgets('muestra subtitle cuando se provee', (tester) async {
      await tester.pumpWidget(wrap(const Header(
        title: 'Inicio',
        subtitle: 'Bienvenido',
      )));
      expect(find.text('Bienvenido'), findsOneWidget);
    });

    testWidgets('no muestra subtitle cuando es null', (tester) async {
      await tester.pumpWidget(wrap(const Header(title: 'Inicio')));
      expect(find.text('Bienvenido'), findsNothing);
    });

    testWidgets('showAvatar=false → sin avatar', (tester) async {
      await tester.pumpWidget(wrap(const Header(
        title: 'Inicio',
        showAvatar: false,
      )));
      // No CircleAvatar or circular container
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('rightContent se muestra cuando se provee', (tester) async {
      await tester.pumpWidget(wrap(Header(
        title: 'Inventario',
        rightContent: const Icon(Icons.search),
      )));
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('rightContent ausente cuando no se provee', (tester) async {
      await tester.pumpWidget(wrap(const Header(title: 'Inventario')));
      expect(find.byIcon(Icons.search), findsNothing);
    });

    testWidgets('bottomContent se muestra cuando se provee', (tester) async {
      await tester.pumpWidget(wrap(Header(
        title: 'Inventario',
        bottomContent: const Text('filtros aquí'),
      )));
      expect(find.text('filtros aquí'), findsOneWidget);
    });

    testWidgets('bottomContent ausente cuando no se provee', (tester) async {
      await tester.pumpWidget(wrap(const Header(title: 'Inventario')));
      expect(find.text('filtros aquí'), findsNothing);
    });

    testWidgets('renderiza sin subtitle ni extras sin lanzar error', (tester) async {
      await tester.pumpWidget(wrap(const Header(title: 'Balance')));
      expect(find.byType(Header), findsOneWidget);
    });
  });
}
