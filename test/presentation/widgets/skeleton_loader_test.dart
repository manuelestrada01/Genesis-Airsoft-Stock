import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/skeleton_loader.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SkeletonLoader', () {
    testWidgets('renderiza con dimensiones dadas', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonLoader(width: 200, height: 20)));
      await tester.pump();

      final size = tester.getSize(find.byType(SkeletonLoader));
      expect(size.width, 200);
      expect(size.height, 20);
    });

    testWidgets('renderiza sin error con borderRadius por defecto', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonLoader(width: 100, height: 12)));
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renderiza con borderRadius personalizado', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonLoader(width: 60, height: 60, borderRadius: 30)));
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('animación avanza sin error', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonLoader(width: 120, height: 16)));
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });

  group('SkeletonStatRow', () {
    testWidgets('renderiza dos celdas de skeleton', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonStatRow()));
      await tester.pump();

      // Contiene múltiples SkeletonLoaders
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('renderiza sin error', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonStatRow()));
      await tester.pump();

      expect(find.byType(SkeletonStatRow), findsOneWidget);
    });
  });

  group('SkeletonInfoCard', () {
    testWidgets('renderiza sin error', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonInfoCard()));
      await tester.pump();

      expect(find.byType(SkeletonInfoCard), findsOneWidget);
    });

    testWidgets('contiene SkeletonLoaders internos', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonInfoCard()));
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsWidgets);
    });
  });

  group('SkeletonProductCard', () {
    testWidgets('renderiza sin error', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonProductCard()));
      await tester.pump();

      expect(find.byType(SkeletonProductCard), findsOneWidget);
    });

    testWidgets('contiene múltiples SkeletonLoaders', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonProductCard()));
      await tester.pump();

      // Image thumb + label + category + price + badge
      expect(find.byType(SkeletonLoader), findsWidgets);
    });
  });
}
