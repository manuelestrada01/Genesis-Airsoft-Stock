import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/balance_period.dart';
import 'package:genesis_airsoft_stock/domain/entities/expense.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';
import 'package:genesis_airsoft_stock/presentation/providers/balance_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/expenses_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/products_provider.dart';
import 'package:genesis_airsoft_stock/presentation/providers/sales_provider.dart';
import 'package:genesis_airsoft_stock/presentation/screens/balance_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/test_factories.dart';

void suppressOverflow() {
  final saved = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    saved?.call(details);
  };
  addTearDown(() => FlutterError.onError = saved);
}

Widget buildBalance({
  List<Sale> sales = const [],
  List<Expense> expenses = const [],
  BalancePeriod? period,
  bool loadingSales = false,
  bool loadingExpenses = false,
}) {
  return ProviderScope(
    overrides: [
      allProductsProvider.overrideWith((_) => Stream.value([])),
      allSalesProvider.overrideWith(
        (_) => loadingSales ? const Stream.empty() : Stream.value(sales),
      ),
      allExpensesProvider.overrideWith(
        (_) => loadingExpenses ? const Stream.empty() : Stream.value(expenses),
      ),
      if (period != null) periodProvider.overrideWith((ref) => period),
    ],
    child: const MaterialApp(home: BalanceScreen()),
  );
}

Future<void> pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR');
  });

  group('BalanceScreen', () {
    testWidgets('muestra "Balance" en header', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildBalance());
      await pump(tester);

      expect(find.text('Balance'), findsWidgets);
    });

    testWidgets('estado de carga → muestra CircularProgressIndicator', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildBalance(loadingSales: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('datos cargados → BalanceCard muestra "Ingresos" y "Egresos"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildBalance());
      await pump(tester);

      expect(find.text('Ingresos'), findsWidgets);
      expect(find.text('Egresos'), findsWidgets);
    });

    testWidgets('sin ventas en período → muestra "Sin ingresos"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildBalance(
        sales: [],
        period: CustomRange(
          from: DateTime(2020, 1, 1),
          to: DateTime(2020, 1, 31),
        ),
      ));
      await pump(tester);

      expect(find.text('Sin ingresos'), findsOneWidget);
    });

    testWidgets('con ventas en período → muestra nombre del producto', (tester) async {
      suppressOverflow();
      final now = DateTime.now();
      await tester.pumpWidget(buildBalance(
        sales: [makeSale(productName: 'AK-47 AEG', total: 5000, createdAt: now)],
        period: PeriodPreset(PeriodType.month),
      ));
      await pump(tester);

      expect(find.text('AK-47 AEG'), findsOneWidget);
    });

    testWidgets('income → aparece en BalanceCard formateado', (tester) async {
      suppressOverflow();
      final now = DateTime.now();
      await tester.pumpWidget(buildBalance(
        sales: [makeSale(total: 10000, createdAt: now)],
        period: PeriodPreset(PeriodType.month),
      ));
      await pump(tester);

      expect(find.textContaining('10.000'), findsWidgets);
    });

    testWidgets('tap en tab "Egresos" → muestra "Sin egresos"', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildBalance());
      await pump(tester);

      // 'Egresos' aparece en BalanceCard (primero) y TabSelector (último)
      await tester.tap(find.text('Egresos').last);
      await tester.pump();

      expect(find.text('Sin egresos'), findsOneWidget);
    });

    testWidgets('tab Egresos con gastos → muestra descripción del gasto', (tester) async {
      suppressOverflow();
      final now = DateTime.now();
      await tester.pumpWidget(buildBalance(
        expenses: [
          makeExpense(description: 'Compra de BBs', amount: 2000, createdAt: now),
        ],
        period: PeriodPreset(PeriodType.month),
      ));
      await pump(tester);

      await tester.tap(find.text('Egresos').last);
      await tester.pump();

      expect(find.text('Compra de BBs'), findsOneWidget);
    });

    testWidgets('muestra ícono FAB (add_rounded)', (tester) async {
      suppressOverflow();
      await tester.pumpWidget(buildBalance());
      await pump(tester);

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });
  });
}
