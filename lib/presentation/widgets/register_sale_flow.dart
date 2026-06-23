import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../../application/usecases/register_sale.dart';
import '../utils/format_currency.dart';
import 'category_filter.dart';

enum _Step { type, select, confirm, free, payment }

class _SelectedItem {
  final Product product;
  int qty;
  double unitPrice;

  _SelectedItem({required this.product, required this.qty, required this.unitPrice});

  double get subtotal => qty * unitPrice;
}

class RegisterSaleFlowPage extends StatefulWidget {
  final List<Product> products;
  final RegisterSale useCase;

  const RegisterSaleFlowPage({
    super.key,
    required this.products,
    required this.useCase,
  });

  @override
  State<RegisterSaleFlowPage> createState() => _RegisterSaleFlowPageState();
}

class _RegisterSaleFlowPageState extends State<RegisterSaleFlowPage> {
  _Step _step = _Step.type;
  final List<_SelectedItem> _items = [];
  String _search = '';
  Object? _categoryFilter; // null | ProductCategory | 'lowStock'
  String _freeDesc = '';
  String _freeAmount = '';
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  SaleStatus _status = SaleStatus.paid;
  String _clientName = '';
  String _discountPct = '0';
  bool _submitting = false;
  String? _error;

  static const _paymentMethods = [
    (key: PaymentMethod.cash, label: 'Efectivo', icon: Icons.payments_outlined),
    (key: PaymentMethod.card, label: 'Tarjeta', icon: Icons.credit_card),
    (key: PaymentMethod.transfer, label: 'Transferencia', icon: Icons.account_balance_outlined),
    (key: PaymentMethod.other, label: 'Otro', icon: Icons.swap_horiz),
    (key: PaymentMethod.mercadopago, label: 'Mercado Pago', icon: Icons.circle_outlined),
    (key: PaymentMethod.qr, label: 'QR', icon: Icons.qr_code),
  ];

  void _setQty(Product product, int delta) {
    setState(() {
      final idx = _items.indexWhere((i) => i.product.id == product.id);
      if (idx == -1) {
        if (delta > 0) _items.add(_SelectedItem(product: product, qty: 1, unitPrice: product.finalPrice));
        return;
      }
      final newQty = _items[idx].qty + delta;
      if (newQty <= 0) {
        _items.removeAt(idx);
      } else if (newQty <= product.stock) {
        _items[idx].qty = newQty;
      }
    });
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.subtotal);
  double get _discountNum => double.tryParse(_discountPct) ?? 0;
  double get _discountAmt => _subtotal * _discountNum / 100;
  double get _total => _subtotal - _discountAmt;

  double get _freeTotal => double.tryParse(_freeAmount.replaceAll(',', '.')) ?? 0;
  double get _freeFinal => _freeTotal - (_freeTotal * _discountNum / 100);

  double get _finalTotal => _items.isEmpty ? _freeFinal : _total;

  List<Product> get _filteredProducts {
    return widget.products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _categoryFilter == null
          ? true
          : _categoryFilter == 'lowStock'
              ? p.isLowStock
              : p.category == _categoryFilter;
      return matchSearch && matchCat;
    }).toList();
  }

  Future<void> _submit() async {
    setState(() { _error = null; _submitting = true; });
    try {
      if (_items.isNotEmpty) {
        await widget.useCase.call(
          items: _items.map((i) => SaleItem(
            productId: i.product.id,
            productName: i.product.name,
            quantity: i.qty,
            pricePerUnit: i.unitPrice,
            costPerUnit: i.product.costPrice,
          )).toList(),
          paymentMethod: _paymentMethod,
          status: _status,
          saleType: SaleType.product,
          clientName: _clientName.trim().isNotEmpty ? _clientName.trim() : null,
          discountPct: _discountNum > 0 ? _discountNum : null,
        );
      } else {
        if (_freeDesc.trim().isEmpty) throw Exception('Ingresa una descripción.');
        if (_freeTotal <= 0) throw Exception('El monto debe ser mayor a 0.');
        await widget.useCase.call(
          items: [SaleItem(
            productId: '',
            productName: _freeDesc.trim(),
            quantity: 1,
            pricePerUnit: _freeFinal,
            costPerUnit: 0,
          )],
          paymentMethod: _paymentMethod,
          status: _status,
          saleType: SaleType.free,
          clientName: _clientName.trim().isNotEmpty ? _clientName.trim() : null,
          discountPct: _discountNum > 0 ? _discountNum : null,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Venta registrada exitosamente'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.type => _buildTypeSelector(),
      _Step.select => _buildSelectProducts(),
      _Step.confirm => _buildConfirmPrices(),
      _Step.free => _buildFreeSale(),
      _Step.payment => _buildPayment(),
    };
  }

  // ── Step 0: Tipo de venta ──────────────────────────────────────────────
  Widget _buildTypeSelector() {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nueva venta', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Text('✕', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Selecciona el tipo de venta que quieres hacer.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  _TypeOption(
                    emoji: '🛒',
                    emojiBg: const Color(0xFFFFF8E1),
                    title: 'Venta de productos',
                    desc: 'Registra una venta seleccionando los productos de tu inventario.',
                    onTap: () => setState(() => _step = _Step.select),
                  ),
                  const SizedBox(height: 10),
                  _TypeOption(
                    emoji: '💵',
                    emojiBg: const Color(0xFFF0F0F0),
                    title: 'Venta libre',
                    desc: 'Registra un ingreso sin seleccionar productos de tu inventario.',
                    onTap: () => setState(() => _step = _Step.free),
                  ),
                  const SizedBox(height: 10),
                  _TypeOption(
                    emoji: '📋',
                    emojiBg: const Color(0xFFFFF8E1),
                    title: 'Cotizaciones',
                    desc: 'Crea cotizaciones para tus clientes y compártelas con ellos.',
                    badge: 'Nuevo',
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const AlertDialog(
                        title: Text('Próximamente'),
                        content: Text('Las cotizaciones estarán disponibles pronto.'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 1: Seleccionar productos ──────────────────────────────────────
  Widget _buildSelectProducts() {
    final filtered = _filteredProducts;
    final totalQty = _items.fold(0, (s, i) => s + i.qty);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FsHeader(
              title: 'Seleccionar productos',
              onBack: () => setState(() => _step = _Step.type),
            ),
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            CategoryFilter(
              selected: _categoryFilter,
              onSelect: (v) => setState(() => _categoryFilter = v),
              showLowStock: true,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: filtered.length,
                itemBuilder: (_, idx) {
                  final product = filtered[idx];
                  final qty = _items.firstWhere(
                    (i) => i.product.id == product.id,
                    orElse: () => _SelectedItem(product: product, qty: 0, unitPrice: 0),
                  ).qty;
                  final isSelected = qty > 0;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.success : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: product.cover.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.cover,
                                  width: 60, height: 60, fit: BoxFit.cover,
                                  placeholder: (_, __) => _ImgPlaceholder(),
                                  errorWidget: (_, __, ___) => _ImgPlaceholder(),
                                )
                              : _ImgPlaceholder(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F8EF),
                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                ),
                                child: Text(
                                  '${product.stock} disponibles',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: product.stock == 0 ? AppColors.danger : AppColors.success,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(formatCurrency(product.finalPrice),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _CounterBtn(onTap: () => _setQty(product, -1), icon: '−'),
                            SizedBox(
                              width: 28,
                              child: Text('$qty', textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark)),
                            ),
                            _CounterBtn(
                              onTap: product.stock > 0 ? () => _setQty(product, 1) : null,
                              icon: '+',
                              disabled: product.stock == 0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _items.isNotEmpty
          ? _Fab(
              badge: '$totalQty',
              label: 'Añadir productos',
              price: formatCurrency(_subtotal),
              onTap: () => setState(() => _step = _Step.confirm),
            )
          : null,
    );
  }

  // ── Step 2: Confirmar precios ──────────────────────────────────────────
  Widget _buildConfirmPrices() {
    final totalQty = _items.fold(0, (s, i) => s + i.qty);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FsHeader(
              title: 'Confirma precios y cantidades',
              onBack: () => setState(() => _step = _Step.select),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF4FF),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Al crear la venta se descontarán las unidades seleccionadas de tu inventario.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._items.map((item) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: item.product.cover.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item.product.cover,
                                    width: 44, height: 44, fit: BoxFit.cover,
                                    placeholder: (_, __) => _ImgPlaceholder(size: 44),
                                    errorWidget: (_, __, ___) => _ImgPlaceholder(size: 44),
                                  )
                                : _ImgPlaceholder(size: 44),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark)),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _items.removeWhere((i) => i.product.id == item.product.id)),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.danger, width: 1.5),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Cantidad *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          GestureDetector(
                                            onTap: () => setState(() {
                                              if (item.qty > 1) { item.qty--; } else { _items.remove(item); }
                                            }),
                                            child: const Text('−', style: TextStyle(fontSize: 20, color: AppColors.dark)),
                                          ),
                                          Text('${item.qty}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark)),
                                          GestureDetector(
                                            onTap: () => setState(() { if (item.qty < item.product.stock) item.qty++; }),
                                            child: const Text('+', style: TextStyle(fontSize: 20, color: AppColors.dark)),
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
                                  const Text('Precio unitario *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                      child: Row(
                                        children: [
                                          const Text('\$', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: TextField(
                                              controller: TextEditingController(text: item.unitPrice > 0 ? '${item.unitPrice.toInt()}' : '')
                                                ..selection = TextSelection.collapsed(offset: item.unitPrice > 0 ? '${item.unitPrice.toInt()}'.length : 0),
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                              decoration: const InputDecoration(
                                                hintText: '0',
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                filled: false,
                                                contentPadding: EdgeInsets.zero,
                                                isDense: true,
                                              ),
                                              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                                              onChanged: (v) => setState(() {
                                                item.unitPrice = double.tryParse(v) ?? 0;
                                              }),
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
                        'Precio por ${item.qty} unidad${item.qty != 1 ? 'es' : ''}: ${formatCurrency(item.subtotal)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Divider(height: 24),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _Fab(
        badge: '$totalQty',
        label: 'Confirmar',
        price: formatCurrency(_subtotal),
        onTap: () => setState(() => _step = _Step.payment),
      ),
    );
  }

  // ── Step free: Venta libre ─────────────────────────────────────────────
  Widget _buildFreeSale() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FsHeader(title: 'Venta libre', onBack: () => setState(() => _step = _Step.type)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Descripción *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => setState(() => _freeDesc = v),
                      decoration: const InputDecoration(hintText: 'Ej: Servicio de mantenimiento'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Monto *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      onChanged: (v) => setState(() => _freeAmount = v),
                      decoration: const InputDecoration(hintText: '0', prefixText: '\$ '),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _Fab(
        label: 'Continuar',
        price: _freeTotal > 0 ? formatCurrency(_freeTotal) : null,
        onTap: () {
          if (_freeDesc.trim().isEmpty) { setState(() => _error = 'Ingresa una descripción.'); return; }
          if (_freeTotal <= 0) { setState(() => _error = 'El monto debe ser mayor a 0.'); return; }
          setState(() { _error = null; _step = _Step.payment; });
        },
      ),
    );
  }

  // ── Step 3: Detalle de pago ────────────────────────────────────────────
  Widget _buildPayment() {
    final today = '${DateTime.now().day} de ${_monthName(DateTime.now().month)}';
    final totalQty = _items.isEmpty ? 1 : _items.fold(0, (s, i) => s + i.qty);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FsHeader(
              title: 'Nueva venta',
              onBack: () => setState(() => _step = _items.isNotEmpty ? _Step.confirm : _Step.free),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pagado / Deuda
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: AppColors.background,
                      ),
                      child: Row(
                        children: [
                          _ToggleBtn(label: 'Pagado', isActive: _status == SaleStatus.paid, activeColor: AppColors.success,
                            onTap: () => setState(() => _status = SaleStatus.paid)),
                          _ToggleBtn(label: 'Deuda', isActive: _status == SaleStatus.debt, activeColor: AppColors.danger,
                            onTap: () => setState(() => _status = SaleStatus.debt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Fecha de la venta:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(width: 6),
                        Text(today, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Selecciona el método de pago *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                              border: Border.all(
                                color: isActive ? AppColors.success : AppColors.border,
                                width: isActive ? 2 : 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(m.icon, size: 28, color: isActive ? AppColors.success : AppColors.textSecondary),
                                const SizedBox(height: 4),
                                Text(
                                  m.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isActive ? AppColors.success : AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
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
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (v) => setState(() => _discountPct = v),
                                      controller: TextEditingController.fromValue(
                                        TextEditingValue(text: _discountPct,
                                          selection: TextSelection.collapsed(offset: _discountPct.length)),
                                      ),
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
                                _discountNum > 0
                                    ? formatCurrency(_items.isEmpty ? _freeTotal * _discountNum / 100 : _discountAmt)
                                    : '\$ 0',
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Cliente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => setState(() => _clientName = v),
                      decoration: const InputDecoration(hintText: 'Nombre del cliente (opcional)'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13), textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _Fab(
        badge: '$totalQty',
        label: 'Crear venta',
        price: formatCurrency(_finalTotal),
        loading: _submitting,
        onTap: _submit,
      ),
    );
  }

  String _monthName(int m) {
    const months = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return months[m - 1];
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────

class _FsHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _FsHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const SizedBox(
              width: 40, height: 40,
              child: Icon(Icons.arrow_back, color: AppColors.dark),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final String? badge;
  final String label;
  final String? price;
  final bool loading;
  final VoidCallback onTap;

  const _Fab({this.badge, required this.label, this.price, this.loading = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        color: AppColors.dark,
        padding: EdgeInsets.fromLTRB(
          16, 14, 16, 14 + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            if (badge != null) ...[
              Container(
                width: 28, height: 28,
                margin: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(badge!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dark)),
              ),
            ],
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            if (price != null && !loading)
              Text('$price ›', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String emoji;
  final Color emojiBg;
  final String title;
  final String desc;
  final String? badge;
  final VoidCallback onTap;

  const _TypeOption({
    required this.emoji, required this.emojiBg, required this.title,
    required this.desc, this.badge, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: badge != null ? Border.all(color: AppColors.success, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: emojiBg, borderRadius: BorderRadius.circular(AppRadius.md)),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(AppRadius.xs)),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final String icon;
  final bool disabled;

  const _CounterBtn({this.onTap, required this.icon, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.3 : 1,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 18, color: AppColors.dark)),
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleBtn({required this.label, required this.isActive, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  final double size;
  const _ImgPlaceholder({this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      color: const Color(0xFFEEEEEE),
      child: const Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 22),
    );
  }
}

void showRegisterSaleFlow(BuildContext context, {
  required List<Product> products,
  required RegisterSale useCase,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => RegisterSaleFlowPage(products: products, useCase: useCase),
    ),
  );
}
