import '../entities/expense.dart';

typedef NewExpense = ({
  String description,
  double amount,
  String category,
});

abstract class IExpenseRepository {
  Stream<List<Expense>> watchAll();
  Future<void> create(NewExpense expense);
}
