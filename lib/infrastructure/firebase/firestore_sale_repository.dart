import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

class FirestoreSaleRepository implements ISaleRepository {
  final _collection = FirebaseFirestore.instance.collection('sales');

  @override
  Stream<List<Sale>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return Sale.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .whereType<Sale>()
          .toList();
    });
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  @override
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<void> create(NewSale sale) async {
    final data = Sale(
      id: '',
      productId: sale.productId,
      productName: sale.productName,
      quantity: sale.quantity,
      pricePerUnit: sale.pricePerUnit,
      costPerUnit: sale.costPerUnit,
      total: sale.total,
      createdAt: DateTime.now(),
      paymentMethod: sale.paymentMethod,
      status: sale.status,
      saleType: sale.saleType,
      clientName: sale.clientName,
      discountPct: sale.discountPct,
    ).toFirestore();

    await _collection.add(data);
  }
}
