import '../../domain/repositories/expense_repository.dart';

class RegisterExpense {
  final IExpenseRepository _repo;
  RegisterExpense(this._repo);

  Future<void> call({
    required String description,
    required double amount,
    required String category,
  }) async {
    if (description.trim().isEmpty) {
      throw Exception('La descripción es requerida');
    }
    if (amount <= 0) {
      throw Exception('El monto debe ser mayor a 0');
    }
    await _repo.create((
      description: description.trim(),
      amount: amount,
      category: category,
    ));
  }
}
