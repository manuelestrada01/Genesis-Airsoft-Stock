import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/repositories/product_repository.dart';
import '../utils/format_currency.dart';

class CreateProductScreen extends StatefulWidget {
  final IProductRepository repo;

  const CreateProductScreen({super.key, required this.repo});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _finalPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();

  ProductCategory? _category;
  bool _finalPriceManual = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _finalPriceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  double get _price => double.tryParse(_priceCtrl.text) ?? 0;
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _computedFinalPrice => _price * (1 - _discount / 100);
  double get _finalPrice => double.tryParse(_finalPriceCtrl.text) ?? 0;

  void _onPriceOrDiscountChanged() {
    if (!_finalPriceManual) {
      final computed = _computedFinalPrice;
      _finalPriceCtrl.text = computed > 0 ? computed.toInt().toString() : '';
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _error = 'El nombre es obligatorio.'); return; }
    if (_category == null) { setState(() => _error = 'Seleccioná una categoría.'); return; }
    if (_price <= 0) { setState(() => _error = 'El precio de costo debe ser mayor a 0.'); return; }
    if (_finalPrice <= 0) { setState(() => _error = 'El precio de venta debe ser mayor a 0.'); return; }

    setState(() { _submitting = true; _error = null; });
    try {
      await widget.repo.create((
        name: name,
        price: _price,
        discount: _discount,
        finalPrice: _finalPrice,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        category: _category!,
        description: _descCtrl.text.trim(),
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                      'Crear producto',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    _label('Nombre *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Ej: ARCTURUS LWT MK-II CQB'),
                    ),
                    const SizedBox(height: 16),

                    // Categoría
                    _label('Categoría *'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ProductCategory>(
                          value: _category,
                          hint: const Text('Seleccionar categoría', style: TextStyle(color: AppColors.textSecondary)),
                          isExpanded: true,
                          items: ProductCategory.values.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label),
                          )).toList(),
                          onChanged: (v) => setState(() => _category = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Precio costo + Descuento
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Precio de costo *'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _priceCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
                                onChanged: (_) => setState(_onPriceOrDiscountChanged),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Descuento %'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _discountCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(suffixText: '%', hintText: '0'),
                                onChanged: (_) {
                                  setState(() => _finalPriceManual = false);
                                  _onPriceOrDiscountChanged();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Precio de venta
                    _label('Precio de venta *'),
                    const SizedBox(height: 4),
                    const Text(
                      'Auto-calculado desde el costo y el descuento. Podés editarlo manualmente.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _finalPriceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
                      onChanged: (_) => setState(() => _finalPriceManual = true),
                    ),
                    if (_price > 0 && _finalPrice > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Margen: ${formatCurrency(_finalPrice - _price)} (${((_finalPrice - _price) / _price * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: _finalPrice >= _price ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Stock inicial
                    _label('Stock inicial'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: '0', suffixText: 'unidades'),
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    _label('Descripción'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Descripción del producto (opcional)',
                        alignLabelWithHint: true,
                      ),
                    ),

                    // Info sin imágenes
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: const Color(0xFFFFD54F)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.photo_outlined, size: 18, color: Color(0xFFF57F17)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Las imágenes se pueden agregar desde el panel web después de crear el producto.',
                              style: TextStyle(fontSize: 13, color: Color(0xFFF57F17), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

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
        onTap: _submitting ? null : _submit,
        child: Container(
          color: AppColors.dark,
          padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
          child: Row(
            children: [
              const Expanded(
                child: Text('Crear producto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              if (_submitting)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else if (_finalPrice > 0)
                Text(formatCurrency(_finalPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
  }
}
