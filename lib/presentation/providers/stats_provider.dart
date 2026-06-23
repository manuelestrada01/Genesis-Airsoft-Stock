import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sales_provider.dart';
import 'products_provider.dart';

class AppStats {
  final int todaySalesCount;
  final int lowStockCount;
  final String? topProductName;
  final double monthlyEarnings;

  const AppStats({
    required this.todaySalesCount,
    required this.lowStockCount,
    this.topProductName,
    required this.monthlyEarnings,
  });
}

final statsProvider = Provider<AsyncValue<AppStats>>((ref) {
  final salesAsync = ref.watch(allSalesProvider);
  final productsAsync = ref.watch(allProductsProvider);

  if (salesAsync.isLoading || productsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final sales = salesAsync.valueOrNull ?? [];
  final products = productsAsync.valueOrNull ?? [];

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final monthStart = DateTime(now.year, now.month, 1);

  // Ventas de hoy
  final todaySales = sales.where((s) => s.createdAt.isAfter(todayStart)).toList();

  // Ventas del mes
  final monthlySales = sales.where((s) => s.createdAt.isAfter(monthStart)).toList();
  final monthlyEarnings = monthlySales.fold(0.0, (sum, s) => sum + s.total);

  // Producto más vendido del mes
  final Map<String, int> unitsByProduct = {};
  for (final sale in monthlySales) {
    unitsByProduct[sale.productName] =
        (unitsByProduct[sale.productName] ?? 0) + sale.quantity;
  }
  String? topProductName;
  if (unitsByProduct.isNotEmpty) {
    topProductName = unitsByProduct.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Stock bajo
  final lowStockCount = products.where((p) => p.isLowStock).length;

  return AsyncValue.data(AppStats(
    todaySalesCount: todaySales.length,
    lowStockCount: lowStockCount,
    topProductName: topProductName,
    monthlyEarnings: monthlyEarnings,
  ));
});
