import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../infrastructure/firebase/firestore_expense_repository.dart';

final expenseRepositoryProvider = Provider<IExpenseRepository>((ref) {
  return FirestoreExpenseRepository();
});

final allExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAll();
});
