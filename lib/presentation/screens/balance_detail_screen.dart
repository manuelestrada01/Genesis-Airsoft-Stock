import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../domain/entities/balance_period.dart';
import '../../domain/entities/sale.dart';
import '../providers/balance_provider.dart';
import '../utils/format_currency.dart';
import '../widgets/balance_card.dart';
import '../widgets/period_selector.dart';
import '../widgets/period_modal.dart';

class BalanceDetailScreen extends ConsumerStatefulWidget {
  const BalanceDetailScreen({super.key});

  @override
  ConsumerState<BalanceDetailScreen> createState() => _BalanceDetailScreenState();
}

class _BalanceDetailScreenState extends ConsumerState<BalanceDetailScreen> {
  DateTime _selectedDate = DateTime.now();
  PeriodType? _contextType;

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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.dark),
                        ),
                        const Text(
                          'Detalle del balance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PeriodSelector(
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
                ],
              ),
            ),
          ),

          // Content
          balanceAsync.when(
            loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Expanded(
              child: Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
            ),
            data: (summary) => Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    BalanceCard(
                      balance: summary.balance,
                      income: summary.income,
                      expenses: summary.expenses,
                    ),
                    const SizedBox(height: 4),
                    _GananciaCard(summary: summary),
                    const SizedBox(height: 8),
                    ...PaymentMethod.values
                        .where((m) => (summary.byPaymentMethod[m] ?? 0) > 0)
                        .map((m) => _PaymentMethodCard(
                              method: m,
                              total: summary.byPaymentMethod[m]!,
                              sales: summary.sales
                                  .where((s) => s.paymentMethod == m)
                                  .toList(),
                            )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GananciaCard extends StatefulWidget {
  final BalanceSummary summary;
  const _GananciaCard({required this.summary});

  @override
  State<_GananciaCard> createState() => _GananciaCardState();
}

class _GananciaCardState extends State<_GananciaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final ganancia = s.ganancia;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ganancia',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    formatCurrency(ganancia),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ganancia >= 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Se calcula restando de tus ventas el costo de los productos vendidos.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            _DetailRow(label: 'Ventas', value: formatCurrency(s.income), color: AppColors.success),
            _DetailRow(
              label: 'Costo de productos que vendiste',
              value: formatCurrency(s.totalCost),
              color: AppColors.danger,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ganancia estimada',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    formatCurrency(ganancia),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ganancia >= 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatefulWidget {
  final PaymentMethod method;
  final double total;
  final List<Sale> sales;

  const _PaymentMethodCard({
    required this.method,
    required this.total,
    required this.sales,
  });

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.method.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    formatCurrency(widget.total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
            ...widget.sales.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.productName,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${s.quantity} u.',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatCurrency(s.total),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
