import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/balance_period.dart';
import 'package:genesis_airsoft_stock/domain/entities/expense.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';
import 'package:genesis_airsoft_stock/presentation/providers/balance_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/expenses_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/sales_provider.dart';

import '../../helpers/test_factories.dart';

// Rango fijo para tests deterministas
final _from = DateTime(2025, 1, 1, 0, 0, 1);  // justo pasada la medianoche
final _to   = DateTime(2025, 1, 31, 23, 59, 59);

ProviderContainer makeContainer({
  List<Sale> sales = const [],
  List<Expense> expenses = const [],
  BalancePeriod? period,
}) {
  final container = ProviderContainer(
    overrides: [
      allSalesProvider.overrideWith((_) => Stream.value(sales)),
      allExpensesProvider.overrideWith((_) => Stream.value(expenses)),
    ],
  );
  if (period != null) {
    container.read(periodProvider.notifier).state = period;
  } else {
    container.read(periodProvider.notifier).state =
        CustomRange(from: _from, to: _to);
  }
  return container;
}

Future<BalanceSummary> readBalance(ProviderContainer c) async {
  await c.read(allSalesProvider.future);
  await c.read(allExpensesProvider.future);
  final value = c.read(balanceProvider);
  return value.value!;
}

void main() {
  group('balanceProvider — income', () {
    test('sin ventas → income = 0', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final summary = await readBalance(c);
      expect(summary.income, 0);
    });

    test('venta en período → suma al income', () async {
      final c = makeContainer(
        sales: [makeSale(total: 5000, createdAt: DateTime(2025, 1, 15))],
      );
      addTearDown(c.dispose);
      final summary = await readBalance(c);
      expect(summary.income, 5000);
    });

    test('múltiples ventas → income es suma total', () async {
      final c = makeContainer(
        sales: [
          makeSale(id: 's1', total: 3000, createdAt: DateTime(2025, 1, 10)),
          makeSale(id: 's2', total: 7000, createdAt: DateTime(2025, 1, 20)),
        ],
      );
      addTearDown(c.dispose);
      final summary = await readBalance(c);
      expect(summary.income, 10000);
    });

    test('venta FUERA del período → excluida del income', () async {
      final c = makeContainer(
        sales: [
          makeSale(id: 's1', total: 5000, createdAt: DateTime(2025, 1, 15)), // dentro
          makeSale(id: 's2', total: 9000, createdAt: DateTime(2025, 2, 5)),  // fuera
        ],
      );
      addTearDown(c.dispose);
      final summary = await readBalance(c);
      expect(summary.income, 5000);
      expect(summary.sales.length, 1);
    });
  });

  group('balanceProvider — expenses', () {
    test('sin gastos → expenses = 0', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final summary = await readBalance(c);
      expect(summary.expenses, 0);
    });

    test('gasto en período → suma a expenses', () async {
      final c = makeContainer(
        expenses: [makeExpense(amount: 2000, createdAt: DateTime(2025, 1, 10))],
      );
      addTearDown(c.dispose);
      final summary = await readBalance(c);
      expect(summary.expenses, 2000);
    });

    test('gasto fuera del período → excluido', () async {
      final c = makeContainer(
        expenses: [
          makeExpense(id: 'e1', amount: 1000, createdAt: DateTime(2025, 1, 10)), // dentro
          makeExpense(id: 'e2', amount: 9000, createdAt: DateTime(2024, 12, 31)), // fuera
        ],
      );
      addTearDown(c.dispose);
      final summary = await readBalance(c);
      expect(summary.expenses, 1000);
    });
  });

  group('BalanceSummary — balance y ganancia', () {
    test('balance = income - expenses', () async {
      final c = makeContainer(
        sales: [makeSale(total: 10000, createdAt: DateTime(2025, 1, 15))],
        expenses: [makeExpense(amount: 3000, createdAt: DateTime(2025, 1, 10))],
      );
      addTearDown(c.dispose);
      final summary = await readBalance(c);
      expect(summary.balance, 7000);
    });

    test('balance negativo cuando expenses > income', () async {
      final c = makeContainer(
        sales: [makeSale(total: 1000, createdAt: DateTime(2025, 1, 15))],
        expenses: [makeExpense(amount: 5000, createdAt: DateTime(2025, 1, 10))],
      );
      addTearDown(c.dispose);
      final summary = await readBalance(c);
      expect(summary.balance, -4000);
    });

    test('ganancia = income - totalCost', () async {
      final c = makeContainer(
        sales: [
          makeSale(
            total: 10000,
            quantity: 2,
            costPerUnit: 3000, // totalCost = 6000
            createdAt: DateTime(2025, 1, 15),
          ),
        ],
      );
      addTearDown(c.dispose);
      final summary = await readBalance(c);
      expect(summary.totalCost, 6000);
      expect(summary.ganancia, 4000); // 10000 - 6000
    });
  });

  group('BalanceSummary — byPaymentMethod', () {
    test('ventas agrupadas por medio de pago', () async {
      final c = makeContainer(
        sales: [
          makeSale(id: 's1', total: 3000, paymentMethod: PaymentMethod.cash, createdAt: DateTime(2025, 1, 10)),
          makeSale(id: 's2', total: 2000, paymentMethod: PaymentMethod.cash, createdAt: DateTime(2025, 1, 11)),
          makeSale(id: 's3', total: 5000, paymentMethod: PaymentMethod.transfer, createdAt: DateTime(2025, 1, 12)),
        ],
      );
      addTearDown(c.dispose);
      final summary = await readBalance(c);

      expect(summary.byPaymentMethod[PaymentMethod.cash], 5000);
      expect(summary.byPaymentMethod[PaymentMethod.transfer], 5000);
      expect(summary.byPaymentMethod[PaymentMethod.card], 0);
    });

    test('sin ventas → todos los métodos en 0', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final summary = await readBalance(c);

      for (final method in PaymentMethod.values) {
        expect(summary.byPaymentMethod[method], 0);
      }
    });
  });

  group('balanceProvider — estado de carga', () {
    test('cuando ventas están cargando → AsyncValue.loading', () {
      final container = ProviderContainer(
        overrides: [
          allSalesProvider.overrideWith((_) => const Stream.empty()),
          allExpensesProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(balanceProvider);
      expect(result, isA<AsyncLoading>());
    });

    test('cuando gastos están cargando → AsyncValue.loading', () {
      final container = ProviderContainer(
        overrides: [
          allSalesProvider.overrideWith((_) => Stream.value([])),
          allExpensesProvider.overrideWith((_) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(balanceProvider);
      expect(result, isA<AsyncLoading>());
    });
  });

  group('balanceProvider — cambio de período', () {
    test('cambiando a PeriodPreset.day filtra por hoy', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final c = ProviderContainer(
        overrides: [
          allSalesProvider.overrideWith((_) => Stream.value([
            makeSale(id: 's1', total: 5000, createdAt: now),
            makeSale(id: 's2', total: 3000, createdAt: yesterday),
          ])),
          allExpensesProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      addTearDown(c.dispose);
      c.read(periodProvider.notifier).state = PeriodPreset(PeriodType.day);

      await c.read(allSalesProvider.future);
      await c.read(allExpensesProvider.future);

      final summary = c.read(balanceProvider).value!;
      expect(summary.income, 5000); // solo la de hoy
    });
  });
}
