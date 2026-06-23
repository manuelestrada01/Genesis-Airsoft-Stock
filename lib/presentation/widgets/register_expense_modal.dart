import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../domain/entities/expense.dart';
import '../../application/usecases/register_expense.dart';

class RegisterExpenseModal extends StatefulWidget {
  final RegisterExpense useCase;

  const RegisterExpenseModal({super.key, required this.useCase});

  @override
  State<RegisterExpenseModal> createState() => _RegisterExpenseModalState();
}

class _RegisterExpenseModalState extends State<RegisterExpenseModal> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = expenseCategories.last; // 'Otros'
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _close() => Navigator.pop(context);

  Future<void> _register() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

    setState(() => _error = null);
    try {
      await widget.useCase.call(
        description: _descController.text,
        amount: amount,
        category: _category,
      );
      if (mounted) _close();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Registrar gasto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 16),
          const Text('Descripción', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(hintText: 'Ej. Compra de BBs...'),
            enabled: !_submitting,
          ),
          const SizedBox(height: 12),
          const Text('Monto', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: const InputDecoration(hintText: '0', prefixText: '\$ '),
            enabled: !_submitting,
          ),
          const SizedBox(height: 12),
          const Text('Categoría', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: expenseCategories.map((cat) {
              final isSelected = _category == cat;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.danger : AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: isSelected ? AppColors.danger : AppColors.border),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : _close,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submitting ? null : () { setState(() => _submitting = true); _register(); },
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Registrar gasto'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void showRegisterExpenseModal(BuildContext context, {required RegisterExpense useCase}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: RegisterExpenseModal(useCase: useCase),
    ),
  );
}
