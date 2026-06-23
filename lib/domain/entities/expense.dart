import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> expenseCategories = ['Compra stock', 'Servicios', 'Otros'];

class Expense {
  final String id;
  final String description;
  final double amount;
  final String category;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.createdAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      category: data['category'] as String? ?? 'Otros',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
