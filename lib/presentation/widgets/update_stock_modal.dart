import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../domain/entities/product.dart';
import '../utils/format_currency.dart';

enum _Mode { add, remove, set }

class _UpdateStockSheet extends StatefulWidget {
  final Product product;
  final Future<void> Function(String productId, int delta) onConfirm;
  final Future<void> Function(String productId, int value) onSet;
  final Future<void> Function(String productId, double costPrice) onUpdatePrice;
  final Future<void> Function(String productId, double finalPrice) onUpdateSalePrice;

  const _UpdateStockSheet({
    required this.product,
    required this.onConfirm,
    required this.onSet,
    required this.onUpdatePrice,
    required this.onUpdateSalePrice,
  });

  @override
  State<_UpdateStockSheet> createState() => _UpdateStockSheetState();
}

class _UpdateStockSheetState extends State<_UpdateStockSheet> {
  _Mode _mode = _Mode.add;
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;
  late double _currentCost;
  late double _currentSalePrice;

  @override
  void initState() {
    super.initState();
    _currentCost = widget.product.costPrice;
    final p = widget.product;
    _currentSalePrice = p.finalPrice.isNaN ? p.price : p.finalPrice;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final val = int.tryParse(_controller.text);
    if (val == null || val <= 0) {
      setState(() => _error = 'Ingresa un número válido mayor a 0.');
      return;
    }
    if (_mode == _Mode.remove && val > widget.product.stock) {
      setState(() => _error = 'Stock actual es ${widget.product.stock}. No puedes quitar más.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      if (_mode == _Mode.add) {
        await widget.onConfirm(widget.product.id, val);
      } else if (_mode == _Mode.remove) {
        await widget.onConfirm(widget.product.id, -val);
      } else {
        await widget.onSet(widget.product.id, val);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock actualizado: ${widget.product.name}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  Future<void> _editCost() async {
    String inputValue = _currentCost.toInt().toString();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar precio de costo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextFormField(
          initialValue: inputValue,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
          onChanged: (v) => inputValue = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dark, foregroundColor: Colors.white),
            onPressed: () {
              final val = double.tryParse(inputValue);
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    setState(() { _submitting = true; _error = null; });
    try {
      await widget.onUpdatePrice(widget.product.id, result);
      if (mounted) {
        setState(() { _currentCost = result; _submitting = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Costo actualizado: ${widget.product.name}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  Future<void> _editSalePrice() async {
    String inputValue = _currentSalePrice.toInt().toString();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar precio de venta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextFormField(
          initialValue: inputValue,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
          onChanged: (v) => inputValue = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dark, foregroundColor: Colors.white),
            onPressed: () {
              final val = double.tryParse(inputValue);
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    setState(() { _submitting = true; _error = null; });
    try {
      await widget.onUpdateSalePrice(widget.product.id, result);
      if (mounted) {
        setState(() { _currentSalePrice = result; _submitting = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Precio de venta actualizado: ${widget.product.name}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    const modeLabels = {_Mode.add: 'Agregar', _Mode.remove: 'Quitar', _Mode.set: 'Establecer'};
    const confirmLabels = {_Mode.add: 'Agregar stock', _Mode.remove: 'Quitar stock', _Mode.set: 'Establecer stock'};
    const inputLabels = {_Mode.add: 'Unidades a agregar', _Mode.remove: 'Unidades a quitar', _Mode.set: 'Nuevo stock total'};

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Nombre + stock
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 4),
          Text(
            'Stock actual: ${product.stock}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Costo + Valor venta
          Row(
            children: [
              GestureDetector(
                onTap: _editCost,
                child: _PriceChip(
                  label: 'Costo',
                  value: formatCurrency(_currentCost),
                  color: AppColors.textSecondary,
                  editable: true,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _editSalePrice,
                child: _PriceChip(
                  label: 'Venta',
                  value: formatCurrency(_currentSalePrice),
                  color: AppColors.success,
                  editable: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tabs modo
          Row(
            children: _Mode.values.map((m) {
              final isActive = _mode == m;
              final isRemove = m == _Mode.remove;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _mode = m; _controller.clear(); _error = null; }),
                  child: Container(
                    margin: EdgeInsets.only(right: m != _Mode.set ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? (isRemove ? AppColors.danger : AppColors.dark) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: isActive ? (isRemove ? AppColors.danger : AppColors.dark) : AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      modeLabels[m]!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Input
          Text(inputLabels[_mode]!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: '0'),
            enabled: !_submitting,
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mode == _Mode.remove ? AppColors.danger : AppColors.dark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitting ? null : _confirm,
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(confirmLabels[_mode]!, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool editable;

  const _PriceChip({required this.label, required this.value, required this.color, this.editable = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: editable ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          if (editable) ...[
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined, size: 14, color: AppColors.textTertiary),
          ],
        ],
      ),
    );
  }
}

void showUpdateStockModal(
  BuildContext context, {
  required Product product,
  required Future<void> Function(String, int) onConfirm,
  required Future<void> Function(String, int) onSet,
  required Future<void> Function(String, double) onUpdatePrice,
  required Future<void> Function(String, double) onUpdateSalePrice,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _UpdateStockSheet(
      product: product,
      onConfirm: onConfirm,
      onSet: onSet,
      onUpdatePrice: onUpdatePrice,
      onUpdateSalePrice: onUpdateSalePrice,
    ),
  );
}
