import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class FirestoreProductRepository implements IProductRepository {
  final _collection = FirebaseFirestore.instance.collection('products');

  @override
  Stream<List<Product>> watchAll() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return Product.fromFirestore(doc);
            } catch (e) {
              // Documento corrupto — se omite silenciosamente
              return null;
            }
          })
          .whereType<Product>()
          .toList();
    });
  }

  @override
  Future<void> updateStock(String productId, int delta) async {
    await _collection.doc(productId).update({
      'stock': FieldValue.increment(delta),
    });
  }

  @override
  Future<void> setStock(String productId, int value) async {
    await _collection.doc(productId).update({'stock': value});
  }

  @override
  Future<void> updateCostPrice(String productId, double costPrice) async {
    await _collection.doc(productId).update({'costPrice': costPrice});
  }

  @override
  Future<void> updateSalePrice(String productId, double finalPrice) async {
    await _collection.doc(productId).update({
      'finalPrice': finalPrice,
      'price': finalPrice,
    });
  }

  @override
  Future<void> create(NewProduct product) async {
    await _collection.add({
      'name': product.name,
      'price': product.price,
      'discount': product.discount,
      'finalPrice': product.finalPrice,
      'stock': product.stock,
      'category': product.category.label,
      'description': product.description,
      'images': [],
      'cover': '',
      'paused': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
