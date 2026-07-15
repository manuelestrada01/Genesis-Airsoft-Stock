import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/product.dart';
import 'package:genesis_airsoft_stock/domain/entities/product_category.dart';
import 'package:genesis_airsoft_stock/presentation/providers/products_provider.dart';

import '../../helpers/test_factories.dart';

ProviderContainer makeContainer(List<Product> products) {
  final container = ProviderContainer(
    overrides: [
      allProductsProvider.overrideWith((_) => Stream.value(products)),
    ],
  );
  return container;
}

void main() {
  group('filteredProductsProvider', () {
    group('sin filtros', () {
      test('devuelve todos los productos', () async {
        final products = [
          makeProduct(id: 'p-1', name: 'AK-47'),
          makeProduct(id: 'p-2', name: 'Glock 17'),
        ];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!.length, 2);
      });

      test('lista vacía → resultado vacío', () async {
        final container = makeContainer([]);
        addTearDown(container.dispose);

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!, isEmpty);
      });
    });

    group('filtro por categoría', () {
      test('filtra por categoría correcta', () async {
        final products = [
          makeProduct(id: 'p-1', category: ProductCategory.marcadorasAEG),
          makeProduct(id: 'p-2', category: ProductCategory.insumos),
          makeProduct(id: 'p-3', category: ProductCategory.accesorios),
        ];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        container.read(categoryFilterProvider.notifier).state =
            ProductCategory.marcadorasAEG;

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!.length, 1);
        expect(result.value!.first.id, 'p-1');
      });

      test('categoría sin coincidencias → vacío', () async {
        final products = [
          makeProduct(id: 'p-1', category: ProductCategory.insumos),
        ];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        container.read(categoryFilterProvider.notifier).state =
            ProductCategory.marcadorasAEG;

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!, isEmpty);
      });

      test('sin filtro de categoría (null) → no filtra', () async {
        final products = [
          makeProduct(id: 'p-1', category: ProductCategory.marcadorasAEG),
          makeProduct(id: 'p-2', category: ProductCategory.insumos),
        ];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        // categoryFilter default = null

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!.length, 2);
      });
    });

    group('filtro lowStock', () {
      test('lowStock=true → solo productos con stock ≤ 5', () async {
        final products = [
          makeProduct(id: 'p-1', stock: 3),
          makeProduct(id: 'p-2', stock: 5),
          makeProduct(id: 'p-3', stock: 6),
          makeProduct(id: 'p-4', stock: 10),
        ];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        container.read(lowStockFilterProvider.notifier).state = true;

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!.length, 2);
        expect(result.value!.map((p) => p.id), containsAll(['p-1', 'p-2']));
      });

      test('lowStock=false → no filtra por stock', () async {
        final products = [
          makeProduct(id: 'p-1', stock: 3),
          makeProduct(id: 'p-2', stock: 10),
        ];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        // lowStockFilter default = false

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!.length, 2);
      });
    });

    group('filtro de búsqueda', () {
      test('búsqueda coincide con nombre (case-insensitive)', () async {
        final products = [
          makeProduct(id: 'p-1', name: 'AK-47 AEG'),
          makeProduct(id: 'p-2', name: 'Glock 17'),
          makeProduct(id: 'p-3', name: 'ak47 custom'),
        ];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        container.read(searchQueryProvider.notifier).state = 'ak';

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!.length, 2);
        expect(result.value!.map((p) => p.id), containsAll(['p-1', 'p-3']));
      });

      test('búsqueda sin coincidencias → vacío', () async {
        final products = [makeProduct(name: 'AK-47 AEG')];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        container.read(searchQueryProvider.notifier).state = 'pistola';

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!, isEmpty);
      });

      test('búsqueda vacía → no filtra', () async {
        final products = [
          makeProduct(id: 'p-1'),
          makeProduct(id: 'p-2', name: 'Glock 17'),
        ];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        // searchQuery default = ''

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!.length, 2);
      });
    });

    group('filtros combinados', () {
      test('categoría + búsqueda aplican juntos', () async {
        final products = [
          makeProduct(id: 'p-1', name: 'AK-47 AEG', category: ProductCategory.marcadorasAEG),
          makeProduct(id: 'p-2', name: 'Glock GBB', category: ProductCategory.marcadorasGBB),
          makeProduct(id: 'p-3', name: 'AK custom', category: ProductCategory.marcadorasGBB),
        ];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        container.read(categoryFilterProvider.notifier).state =
            ProductCategory.marcadorasGBB;
        container.read(searchQueryProvider.notifier).state = 'ak';

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!.length, 1);
        expect(result.value!.first.id, 'p-3');
      });

      test('categoría + lowStock aplican juntos', () async {
        final products = [
          makeProduct(id: 'p-1', stock: 3, category: ProductCategory.insumos),
          makeProduct(id: 'p-2', stock: 3, category: ProductCategory.marcadorasAEG),
          makeProduct(id: 'p-3', stock: 10, category: ProductCategory.insumos),
        ];
        final container = makeContainer(products);
        addTearDown(container.dispose);

        container.read(categoryFilterProvider.notifier).state =
            ProductCategory.insumos;
        container.read(lowStockFilterProvider.notifier).state = true;

        await container.read(allProductsProvider.future);
        final result = container.read(filteredProductsProvider);

        expect(result.value!.length, 1);
        expect(result.value!.first.id, 'p-1');
      });
    });

    group('estado de carga', () {
      test('cuando allProductsProvider está cargando → AsyncValue.loading', () {
        // Stream que nunca emite = loading
        final container = ProviderContainer(
          overrides: [
            allProductsProvider.overrideWith((_) => const Stream.empty()),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(filteredProductsProvider);
        expect(result, isA<AsyncLoading>());
      });
    });
  });
}
