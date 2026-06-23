import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../application/usecases/register_expense.dart';
import '../../application/usecases/register_sale.dart';
import '../../domain/entities/balance_period.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/expense.dart';
import '../providers/balance_provider.dart';
import '../providers/products_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/expenses_provider.dart';
import '../widgets/header.dart';
import '../widgets/balance_card.dart';
import '../widgets/tab_selector.dart';
import '../widgets/transaction_item.dart';
import '../widgets/period_selector.dart';
import '../widgets/period_modal.dart';
import '../widgets/empty_state.dart';
import '../widgets/register_sale_flow.dart';
import '../widgets/register_expense_modal.dart';
import 'sale_detail_screen.dart';
import 'balance_detail_screen.dart';

class BalanceScreen extends ConsumerStatefulWidget {
  const BalanceScreen({super.key});

  @override
  ConsumerState<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends ConsumerState<BalanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showExpenses = false;
  PeriodType? _contextType = PeriodType.month;

  void _onSelectDate(DateTime date) {
    setState(() => _selectedDate = date);
    ref.read(periodProvider.notifier).state = CustomRange(
      from: DateTime(date.year, date.month, date.day),
      to: DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(balanceProvider);
    final period = ref.watch(periodProvider);
    final products = ref.watch(allProductsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Header(
            title: 'Balance',
            bottomContent: PeriodSelector(
              selectedDate: _selectedDate,
              period: period,
              contextType: _contextType,
              onSelectDate: _onSelectDate,
              onSelectPeriod: (p) => ref.read(periodProvider.notifier).state = p,
              onOpenPeriodModal: () => showPeriodModal(
                context,
                current: period,
                onSelect: (p) {
                  ref.read(periodProvider.notifier).state = p;
                  if (p is PeriodPreset) {
                    setState(() => _contextType = p.type);
                  }
                },
              ),
            ),
          ),
          balanceAsync.when(
            loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Expanded(
              child: Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
            ),
            data: (summary) => Expanded(
              child: _BalanceContent(
                summary: summary,
                showExpenses: _showExpenses,
                onToggleTab: (i) => setState(() => _showExpenses = i == 1),
                products: products,
                periodForSale: period,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceContent extends ConsumerWidget {
  final BalanceSummary summary;
  final bool showExpenses;
  final ValueChanged<int> onToggleTab;
  final List products;
  final BalancePeriod periodForSale;

  const _BalanceContent({
    required this.summary,
    required this.showExpenses,
    required this.onToggleTab,
    required this.products,
    required this.periodForSale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = showExpenses ? summary.expenseList : summary.sales;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BalanceCard(
                balance: summary.balance,
                income: summary.income,
                expenses: summary.expenses,
              ),
            ),
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BalanceDetailScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Ver desglose',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.dark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.dark),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: TabSelector(
                tabs: const ['Ingresos', 'Egresos'],
                activeIndex: showExpenses ? 1 : 0,
                onSelect: onToggleTab,
              ),
            ),
            items.isEmpty
                ? SliverFillRemaining(
                    child: EmptyState(
                      title: showExpenses ? 'Sin egresos' : 'Sin ingresos',
                      subtitle: 'No hay transacciones en este período.',
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, idx) {
                        if (showExpenses) {
                          final e = items[idx] as Expense;
                          return TransactionItem(
                            isIncome: false,
                            description: e.description,
                            amount: e.amount,
                            date: e.createdAt,
                            detail: e.category,
                          );
                        } else {
                          final s = items[idx] as Sale;
                          return TransactionItem(
                            isIncome: true,
                            description: s.productName,
                            amount: s.total,
                            date: s.createdAt,
                            detail: '${s.quantity} u. × ${s.pricePerUnit.toStringAsFixed(0)}',
                            statusLabel: s.status.label,
                            statusColor: s.status == SaleStatus.paid ? AppColors.success : AppColors.danger,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => SaleDetailScreen(
                                  sale: s,
                                  repo: ref.read(saleRepositoryProvider),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      childCount: items.length,
                    ),
                  ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
        // FABs
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'fab_sale',
                backgroundColor: AppColors.success,
                onPressed: () {
                  final saleRepo = ref.read(saleRepositoryProvider);
                  final productRepo = ref.read(productRepositoryProvider);
                  showRegisterSaleFlow(
                    context,
                    products: products.cast(),
                    useCase: RegisterSale(saleRepo, productRepo),
                  );
                },
                label: const Text('+ Nueva venta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'fab_expense',
                backgroundColor: AppColors.danger,
                onPressed: () => showRegisterExpenseModal(
                  context,
                  useCase: RegisterExpense(ref.read(expenseRepositoryProvider)),
                ),
                label: const Text('+ Nuevo gasto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
