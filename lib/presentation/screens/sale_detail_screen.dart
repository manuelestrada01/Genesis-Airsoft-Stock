import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../utils/format_currency.dart';
import '../utils/format_date.dart';

class SaleDetailScreen extends StatefulWidget {
  final Sale sale;
  final ISaleRepository repo;

  const SaleDetailScreen({super.key, required this.sale, required this.repo});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _clientCtrl;
  late int _qty;
  late PaymentMethod _paymentMethod;
  late SaleStatus _status;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  static const _paymentMethods = [
    (key: PaymentMethod.cash, label: 'Efectivo', icon: Icons.payments_outlined),
    (key: PaymentMethod.card, label: 'Tarjeta', icon: Icons.credit_card),
    (key: PaymentMethod.transfer, label: 'Transferencia', icon: Icons.account_balance_outlined),
    (key: PaymentMethod.other, label: 'Otro', icon: Icons.swap_horiz),
    (key: PaymentMethod.mercadopago, label: 'Mercado Pago', icon: Icons.circle_outlined),
    (key: PaymentMethod.qr, label: 'QR', icon: Icons.qr_code),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.sale.productName);
    _priceCtrl = TextEditingController(text: widget.sale.pricePerUnit.toInt().toString());
    _discountCtrl = TextEditingController(text: (widget.sale.discountPct ?? 0).toInt().toString());
    _clientCtrl = TextEditingController(text: widget.sale.clientName ?? '');
    _qty = widget.sale.quantity;
    _paymentMethod = widget.sale.paymentMethod;
    _status = widget.sale.status;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _clientCtrl.dispose();
    super.dispose();
  }

  double get _price => double.tryParse(_priceCtrl.text) ?? 0;
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => _qty * _price * (1 - _discount / 100);

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El nombre no puede estar vacío.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.repo.update(widget.sale.id, {
        'productName': _nameCtrl.text.trim(),
        'quantity': _qty,
        'pricePerUnit': _price,
        'total': _total,
        'paymentMethod': _paymentMethod.value,
        'status': _status.value,
        'clientName': _clientCtrl.text.trim().isNotEmpty ? _clientCtrl.text.trim() : null,
        'discountPct': _discount > 0 ? _discount : null,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() { _deleting = true; _error = null; });
    try {
      await widget.repo.delete(widget.sale.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_back, color: AppColors.dark)),
                  ),
                  const Expanded(
                    child: Text(
                      'Detalle de venta',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
                    ),
                  ),
                  GestureDetector(
                    onTap: _deleting ? null : _delete,
                    child: SizedBox(
                      width: 40, height: 40,
                      child: _deleting
                          ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger)))
                          : const Icon(Icons.delete_outline, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info no editable
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF4FF),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Creada el ${formatDate(widget.sale.createdAt)}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Estado Pagado/Deuda
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: AppColors.background,
                      ),
                      child: Row(
                        children: [
                          _toggleBtn('Pagado', _status == SaleStatus.paid, AppColors.success, () => setState(() => _status = SaleStatus.paid)),
                          _toggleBtn('Deuda', _status == SaleStatus.debt, AppColors.danger, () => setState(() => _status = SaleStatus.debt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    const Text('Descripción', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Nombre del producto')),
                    const SizedBox(height: 16),

                    // Cantidad + Precio
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Cantidad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        GestureDetector(
                                          onTap: () => setState(() { if (_qty > 1) _qty--; }),
                                          child: const Text('−', style: TextStyle(fontSize: 22, color: AppColors.dark)),
                                        ),
                                        Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark)),
                                        GestureDetector(
                                          onTap: () => setState(() => _qty++),
                                          child: const Text('+', style: TextStyle(fontSize: 22, color: AppColors.dark)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Precio unitario', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
                                    child: Row(
                                      children: [
                                        const Text('\$', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: TextField(
                                            controller: _priceCtrl,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            onChanged: (_) => setState(() {}),
                                            decoration: const InputDecoration(
                                              hintText: '0',
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              filled: false,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${formatCurrency(_total)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Método de pago
                    const Text('Método de pago', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                      children: _paymentMethods.map((m) {
                        final isActive = _paymentMethod == m.key;
                        return GestureDetector(
                          onTap: () => setState(() => _paymentMethod = m.key),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFF0FFF4) : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isActive ? AppColors.success : AppColors.border, width: isActive ? 2 : 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(m.icon, size: 28, color: isActive ? AppColors.success : AppColors.textSecondary),
                                const SizedBox(height: 4),
                                Text(m.label,
                                  style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isActive ? AppColors.success : AppColors.textSecondary),
                                  textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Descuento
                    const Text('Descuento', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _discountCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  const Text('%', style: TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Center(child: Text('=', style: TextStyle(fontSize: 16, color: AppColors.textSecondary))),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _discount > 0 ? formatCurrency(_qty * _price * _discount / 100) : '\$ 0',
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cliente
                    const Text('Cliente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(controller: _clientCtrl, decoration: const InputDecoration(hintText: 'Nombre del cliente (opcional)')),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: GestureDetector(
        onTap: _saving ? null : _save,
        child: Container(
          color: AppColors.dark,
          padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
          child: Row(
            children: [
              const Expanded(
                child: Text('Guardar cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              if (_saving)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else
                Text(formatCurrency(_total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, bool isActive, Color activeColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isActive ? activeColor : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.sm)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }
}
