import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/icons.dart';
import '../../application/usecases/register_expense.dart';
import '../../application/usecases/register_sale.dart';
import '../providers/products_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/format_currency.dart';
import '../widgets/header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/register_sale_flow.dart';
import '../widgets/register_expense_modal.dart';
import '../widgets/skeleton_loader.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(allProductsProvider).valueOrNull ?? [];
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Header(
            title: 'Genesis Airsoft',
            subtitle: 'Propietario',
            showAvatar: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acceso rápido',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        QuickActionCard(
                          title: 'Registrar Venta',
                          icon: AppIcons.registerSale,
                          variant: QuickActionVariant.dark,
                          onPress: () {
                            final saleRepo = ref.read(saleRepositoryProvider);
                            final productRepo = ref.read(productRepositoryProvider);
                            showRegisterSaleFlow(
                              context,
                              products: products,
                              useCase: RegisterSale(saleRepo, productRepo),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        QuickActionCard(
                          title: 'Registrar Gasto',
                          icon: AppIcons.registerExpense,
                          variant: QuickActionVariant.light,
                          onPress: () {
                            showRegisterExpenseModal(
                              context,
                              useCase: RegisterExpense(ref.read(expenseRepositoryProvider)),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        QuickActionCard(
                          title: 'Ver Inventario',
                          icon: AppIcons.viewInventory,
                          variant: QuickActionVariant.light,
                          onPress: () => context.go('/inventory'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  statsAsync.when(
                    loading: () => const Column(
                      children: [
                        SkeletonStatRow(),
                        SizedBox(height: 12),
                        SkeletonInfoCard(),
                        SizedBox(height: 12),
                        SkeletonInfoCard(),
                      ],
                    ),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.danger)),
                    data: (stats) => Column(
                      children: [
                        Row(
                          children: [
                            StatCard(label: 'Ventas hoy', value: '${stats.todaySalesCount}'),
                            const SizedBox(width: 12),
                            StatCard(
                              label: 'Stock bajo',
                              value: '${stats.lowStockCount}',
                              valueColor: stats.lowStockCount > 0 ? AppColors.danger : AppColors.success,
                            ),
                          ],
                        ),
                        if (stats.topProductName != null) ...[
                          const SizedBox(height: 12),
                          _InfoCard(
                            label: 'Producto estrella (este mes)',
                            title: stats.topProductName!,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _InfoCard(
                          label: 'Ganancias del mes',
                          title: formatCurrency(stats.monthlyEarnings),
                          titleColor: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String title;
  final Color? titleColor;

  const _InfoCard({required this.label, required this.title, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: titleColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
