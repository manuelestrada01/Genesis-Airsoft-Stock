import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/product.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/stock_badge.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StockBadge', () {
    testWidgets('muestra el número de stock', (tester) async {
      await tester.pumpWidget(wrap(const StockBadge(stock: 10)));
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('stock = 0 → muestra "0"', (tester) async {
      await tester.pumpWidget(wrap(const StockBadge(stock: 0)));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('stock ≤ lowStockThreshold → fondo rojo', (tester) async {
      await tester.pumpWidget(wrap(const StockBadge(stock: 5)));
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFE53935));
    });

    testWidgets('stock > lowStockThreshold → fondo verde', (tester) async {
      await tester.pumpWidget(wrap(const StockBadge(stock: 6)));
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFC8F400));
    });

    testWidgets('stock bajo (5) → texto blanco', (tester) async {
      await tester.pumpWidget(wrap(const StockBadge(stock: 5)));
      final text = tester.widget<Text>(find.text('5'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('stock normal (6) → texto oscuro', (tester) async {
      await tester.pumpWidget(wrap(const StockBadge(stock: 6)));
      final text = tester.widget<Text>(find.text('6'));
      expect(text.style?.color, const Color(0xFF0F0F0F));
    });

    testWidgets('boundary: stock = lowStockThreshold (5) → bajo', (tester) async {
      expect(lowStockThreshold, 5);
      await tester.pumpWidget(wrap(const StockBadge(stock: lowStockThreshold)));
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFE53935)); // rojo
    });

    testWidgets('boundary: stock = 6 → normal', (tester) async {
      await tester.pumpWidget(wrap(const StockBadge(stock: 6)));
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFC8F400)); // verde
    });
  });
}
