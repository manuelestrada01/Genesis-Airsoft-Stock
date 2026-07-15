import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/product.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';
import 'package:genesis_airsoft_stock/presentation/providers/products_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/sales_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/stats_provider.dart';

import '../../helpers/test_factories.dart';

ProviderContainer makeContainer({
  List<Sale> sales = const [],
  List<Product> products = const [],
}) {
  final c = ProviderContainer(
    overrides: [
      allSalesProvider.overrideWith((_) => Stream.value(sales)),
      allProductsProvider.overrideWith((_) => Stream.value(products)),
    ],
  );
  return c;
}

Future<AppStats> readStats(ProviderContainer c) async {
  await c.read(allSalesProvider.future);
  await c.read(allProductsProvider.future);
  return c.read(statsProvider).value!;
}

void main() {
  group('statsProvider — todaySalesCount', () {
    test('sin ventas → 0', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.todaySalesCount, 0);
    });

    test('venta de hoy → cuenta', () async {
      final now = DateTime.now();
      final c = makeContainer(
        sales: [makeSale(createdAt: now)],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.todaySalesCount, 1);
    });

    test('venta de ayer → NO cuenta', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final c = makeContainer(
        sales: [makeSale(createdAt: yesterday)],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.todaySalesCount, 0);
    });

    test('mezcla hoy y ayer → solo cuenta las de hoy', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final c = makeContainer(
        sales: [
          makeSale(id: 's1', createdAt: now),
          makeSale(id: 's2', createdAt: now),
          makeSale(id: 's3', createdAt: yesterday),
        ],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.todaySalesCount, 2);
    });
  });

  group('statsProvider — lowStockCount', () {
    test('sin productos → 0', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.lowStockCount, 0);
    });

    test('producto con stock = 5 → cuenta (isLowStock boundary)', () async {
      final c = makeContainer(
        products: [makeProduct(stock: 5)],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.lowStockCount, 1);
    });

    test('producto con stock = 6 → NO cuenta', () async {
      final c = makeContainer(
        products: [makeProduct(stock: 6)],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.lowStockCount, 0);
    });

    test('producto con stock = 0 → cuenta', () async {
      final c = makeContainer(
        products: [makeProduct(stock: 0)],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.lowStockCount, 1);
    });

    test('múltiples productos, solo los de stock bajo', () async {
      final c = makeContainer(
        products: [
          makeProduct(id: 'p1', stock: 3),
          makeProduct(id: 'p2', stock: 5),
          makeProduct(id: 'p3', stock: 6),
          makeProduct(id: 'p4', stock: 0),
        ],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.lowStockCount, 3); // p1, p2, p4
    });

    test('incluye productos pausados con stock bajo', () async {
      final c = makeContainer(
        products: [makeProduct(stock: 2, paused: true)],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.lowStockCount, 1);
    });
  });

  group('statsProvider — topProductName', () {
    test('sin ventas → null', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.topProductName, isNull);
    });

    test('una sola venta → ese producto es top', () async {
      final now = DateTime.now();
      final c = makeContainer(
        sales: [makeSale(productName: 'AK-47 AEG', quantity: 3, createdAt: now)],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.topProductName, 'AK-47 AEG');
    });

    test('producto con más unidades gana', () async {
      final now = DateTime.now();
      final c = makeContainer(
        sales: [
          makeSale(id: 's1', productName: 'AK-47', quantity: 5, createdAt: now),
          makeSale(id: 's2', productName: 'Glock 17', quantity: 2, createdAt: now),
          makeSale(id: 's3', productName: 'Glock 17', quantity: 1, createdAt: now),
        ],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      // AK-47: 5 unidades, Glock 17: 3 unidades
      expect(stats.topProductName, 'AK-47');
    });

    test('acumula unidades del mismo producto en múltiples ventas', () async {
      final now = DateTime.now();
      final c = makeContainer(
        sales: [
          makeSale(id: 's1', productName: 'AK-47', quantity: 3, createdAt: now),
          makeSale(id: 's2', productName: 'AK-47', quantity: 4, createdAt: now), // total 7
          makeSale(id: 's3', productName: 'Glock 17', quantity: 6, createdAt: now),
        ],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.topProductName, 'AK-47'); // 7 vs 6
    });

    test('ventas del mes pasado NO cuentan para top product', () async {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15);
      final c = makeContainer(
        sales: [
          makeSale(id: 's1', productName: 'Viejo', quantity: 100, createdAt: lastMonth),
          makeSale(id: 's2', productName: 'Nuevo', quantity: 1, createdAt: now),
        ],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.topProductName, 'Nuevo');
    });
  });

  group('statsProvider — monthlyEarnings', () {
    test('sin ventas del mes → 0', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.monthlyEarnings, 0);
    });

    test('venta de este mes → suma al total', () async {
      final now = DateTime.now();
      final c = makeContainer(
        sales: [makeSale(total: 15000, createdAt: now)],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.monthlyEarnings, 15000);
    });

    test('venta del mes pasado → excluida', () async {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15);
      final c = makeContainer(
        sales: [
          makeSale(id: 's1', total: 5000, createdAt: now),
          makeSale(id: 's2', total: 99000, createdAt: lastMonth),
        ],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.monthlyEarnings, 5000);
    });

    test('múltiples ventas del mes → suma correcta', () async {
      final now = DateTime.now();
      final c = makeContainer(
        sales: [
          makeSale(id: 's1', total: 3000, createdAt: now),
          makeSale(id: 's2', total: 7000, createdAt: now),
        ],
      );
      addTearDown(c.dispose);
      final stats = await readStats(c);
      expect(stats.monthlyEarnings, 10000);
    });
  });

  group('statsProvider — estado de carga', () {
    test('cuando ventas cargan → AsyncValue.loading', () {
      final c = ProviderContainer(
        overrides: [
          allSalesProvider.overrideWith((_) => const Stream.empty()),
          allProductsProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(statsProvider), isA<AsyncLoading>());
    });

    test('cuando productos cargan → AsyncValue.loading', () {
      final c = ProviderContainer(
        overrides: [
          allSalesProvider.overrideWith((_) => Stream.value([])),
          allProductsProvider.overrideWith((_) => const Stream.empty()),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(statsProvider), isA<AsyncLoading>());
    });
  });
}
