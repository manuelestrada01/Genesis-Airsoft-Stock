import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class FirestoreExpenseRepository implements IExpenseRepository {
  final _collection = FirebaseFirestore.instance.collection('expenses');

  @override
  Stream<List<Expense>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return Expense.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .whereType<Expense>()
          .toList();
    });
  }

  @override
  Future<void> create(NewExpense expense) async {
    final data = Expense(
      id: '',
      description: expense.description,
      amount: expense.amount,
      category: expense.category,
      createdAt: DateTime.now(),
    ).toFirestore();

    await _collection.add(data);
  }
}
