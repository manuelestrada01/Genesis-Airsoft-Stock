import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/application/usecases/update_product_stock.dart';

import '../../helpers/mock_repositories.dart';

void main() {
  late MockProductRepository repo;
  late UpdateProductStock useCase;

  setUp(() {
    repo = MockProductRepository();
    useCase = UpdateProductStock(repo);
  });

  group('UpdateProductStock.increment — validaciones', () {
    test('delta = 0 → lanza excepción', () async {
      await expectLater(
        useCase.increment('p-1', 0),
        throwsA(isA<Exception>()),
      );
      expect(repo.stockIncrements, isEmpty);
    });
  });

  group('UpdateProductStock.increment — llamadas al repositorio', () {
    test('delta positivo → llama updateStock con delta positivo', () async {
      await useCase.increment('p-1', 5);

      expect(repo.stockIncrements.length, 1);
      expect(repo.stockIncrements.first, ('p-1', 5));
    });

    test('delta negativo → llama updateStock con delta negativo', () async {
      await useCase.increment('p-1', -3);

      expect(repo.stockIncrements.length, 1);
      expect(repo.stockIncrements.first, ('p-1', -3));
    });

    test('productId se pasa correctamente', () async {
      await useCase.increment('prod-abc-123', 1);

      expect(repo.stockIncrements.first.$1, 'prod-abc-123');
    });

    test('error del repo se propaga', () async {
      repo.errorOnUpdate = Exception('Firestore offline');

      await expectLater(
        useCase.increment('p-1', 1),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('UpdateProductStock.set — validaciones', () {
    test('value negativo → lanza excepción', () async {
      await expectLater(
        useCase.set('p-1', -1),
        throwsA(isA<Exception>()),
      );
      expect(repo.stockSets, isEmpty);
    });
  });

  group('UpdateProductStock.set — llamadas al repositorio', () {
    test('value = 0 → válido (vaciar stock)', () async {
      await useCase.set('p-1', 0);

      expect(repo.stockSets.length, 1);
      expect(repo.stockSets.first, ('p-1', 0));
    });

    test('value positivo → llama setStock', () async {
      await useCase.set('p-1', 15);

      expect(repo.stockSets.length, 1);
      expect(repo.stockSets.first, ('p-1', 15));
    });

    test('productId se pasa correctamente', () async {
      await useCase.set('prod-xyz', 10);

      expect(repo.stockSets.first.$1, 'prod-xyz');
    });

    test('error del repo se propaga', () async {
      repo.errorOnUpdate = Exception('Firestore offline');

      await expectLater(
        useCase.set('p-1', 10),
        throwsA(isA<Exception>()),
      );
    });
  });
}
