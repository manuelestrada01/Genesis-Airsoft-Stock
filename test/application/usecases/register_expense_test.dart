import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/application/usecases/register_expense.dart';

import '../../helpers/mock_repositories.dart';

void main() {
  late MockExpenseRepository repo;
  late RegisterExpense useCase;

  setUp(() {
    repo = MockExpenseRepository();
    useCase = RegisterExpense(repo);
  });

  group('RegisterExpense — validaciones', () {
    test('descripción vacía → lanza excepción', () async {
      await expectLater(
        useCase.call(description: '', amount: 1000, category: 'Otros'),
        throwsA(isA<Exception>()),
      );
      expect(repo.createdExpenses, isEmpty);
    });

    test('descripción solo espacios → lanza excepción', () async {
      await expectLater(
        useCase.call(description: '   ', amount: 1000, category: 'Otros'),
        throwsA(isA<Exception>()),
      );
      expect(repo.createdExpenses, isEmpty);
    });

    test('monto = 0 → lanza excepción', () async {
      await expectLater(
        useCase.call(description: 'Compra BBs', amount: 0, category: 'Otros'),
        throwsA(isA<Exception>()),
      );
      expect(repo.createdExpenses, isEmpty);
    });

    test('monto negativo → lanza excepción', () async {
      await expectLater(
        useCase.call(description: 'Compra BBs', amount: -100, category: 'Otros'),
        throwsA(isA<Exception>()),
      );
      expect(repo.createdExpenses, isEmpty);
    });
  });

  group('RegisterExpense — llamadas al repositorio', () {
    test('datos válidos → llama repo.create', () async {
      await useCase.call(
        description: 'Compra de BBs',
        amount: 5000,
        category: 'Compra stock',
      );

      expect(repo.createdExpenses.length, 1);
    });

    test('guarda descripción con trim', () async {
      await useCase.call(
        description: '  Compra de BBs  ',
        amount: 5000,
        category: 'Otros',
      );

      expect(repo.createdExpenses.first.description, 'Compra de BBs');
    });

    test('guarda monto exacto', () async {
      await useCase.call(
        description: 'Servicio',
        amount: 3500.50,
        category: 'Servicios',
      );

      expect(repo.createdExpenses.first.amount, 3500.50);
    });

    test('guarda categoría correcta', () async {
      await useCase.call(
        description: 'Test',
        amount: 100,
        category: 'Servicios',
      );

      expect(repo.createdExpenses.first.category, 'Servicios');
    });

    test('acepta las 3 categorías válidas', () async {
      for (final cat in ['Compra stock', 'Servicios', 'Otros']) {
        repo.createdExpenses.clear();
        await useCase.call(description: 'Test', amount: 100, category: cat);
        expect(repo.createdExpenses.first.category, cat);
      }
    });

    test('monto decimal positivo → válido', () async {
      await useCase.call(
        description: 'Servicio',
        amount: 0.01,
        category: 'Otros',
      );

      expect(repo.createdExpenses.length, 1);
    });

    test('error en repo.create se propaga', () async {
      repo.errorOnCreate = Exception('Sin conexión');

      await expectLater(
        useCase.call(description: 'Test', amount: 100, category: 'Otros'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
