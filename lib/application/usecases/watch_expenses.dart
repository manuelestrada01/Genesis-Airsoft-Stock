import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class WatchExpenses {
  final IExpenseRepository _repo;
  WatchExpenses(this._repo);

  Stream<List<Expense>> call() => _repo.watchAll();
}
