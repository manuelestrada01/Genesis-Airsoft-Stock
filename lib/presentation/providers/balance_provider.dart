import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/balance_period.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/expense.dart';
import 'sales_provider.dart';
import 'expenses_provider.dart';

final periodProvider = StateProvider<BalancePeriod>((ref) {
  return PeriodPreset(PeriodType.month);
});

class BalanceSummary {
  final double income;
  final double expenses;
  final List<Sale> sales;
  final List<Expense> expenseList;

  const BalanceSummary({
    required this.income,
    required this.expenses,
    required this.sales,
    required this.expenseList,
  });

  double get balance => income - expenses;

  double get totalCost =>
      sales.fold(0.0, (sum, s) => sum + s.costPerUnit * s.quantity);

  double get ganancia => income - totalCost;

  Map<PaymentMethod, double> get byPaymentMethod => {
    for (final m in PaymentMethod.values)
      m: sales
          .where((s) => s.paymentMethod == m)
          .fold(0.0, (sum, s) => sum + s.total),
  };
}

final balanceProvider = Provider<AsyncValue<BalanceSummary>>((ref) {
  final salesAsync = ref.watch(allSalesProvider);
  final expensesAsync = ref.watch(allExpensesProvider);
  final period = ref.watch(periodProvider);

  if (salesAsync.isLoading || expensesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (salesAsync.hasError) return AsyncValue.error(salesAsync.error!, salesAsync.stackTrace!);
  if (expensesAsync.hasError) return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);

  final (from, to) = getDateRangeForPeriod(period);

  final filteredSales = (salesAsync.valueOrNull ?? [])
      .where((s) => s.createdAt.isAfter(from) && s.createdAt.isBefore(to.add(const Duration(days: 1))))
      .toList();

  final filteredExpenses = (expensesAsync.valueOrNull ?? [])
      .where((e) => e.createdAt.isAfter(from) && e.createdAt.isBefore(to.add(const Duration(days: 1))))
      .toList();

  final income = filteredSales.fold(0.0, (sum, s) => sum + s.total);
  final expTotal = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

  return AsyncValue.data(BalanceSummary(
    income: income,
    expenses: expTotal,
    sales: filteredSales,
    expenseList: filteredExpenses,
  ));
});
