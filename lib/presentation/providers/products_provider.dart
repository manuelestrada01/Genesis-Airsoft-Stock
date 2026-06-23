import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/repositories/product_repository.dart';
import '../../infrastructure/firebase/firestore_product_repository.dart';

final productRepositoryProvider = Provider<IProductRepository>((ref) {
  return FirestoreProductRepository();
});

final allProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAll();
});

final categoryFilterProvider = StateProvider<ProductCategory?>((ref) => null);
final lowStockFilterProvider = StateProvider<bool>((ref) => false);
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(allProductsProvider);
  final category = ref.watch(categoryFilterProvider);
  final lowStock = ref.watch(lowStockFilterProvider);
  final search = ref.watch(searchQueryProvider);

  return productsAsync.whenData((products) {
    var result = products;
    if (category != null) {
      result = result.where((p) => p.category == category).toList();
    }
    if (lowStock) {
      result = result.where((p) => p.isLowStock).toList();
    }
    if (search.isNotEmpty) {
      final term = search.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(term)).toList();
    }
    return result;
  });
});
