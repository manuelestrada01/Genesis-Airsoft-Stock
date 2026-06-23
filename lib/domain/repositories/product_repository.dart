import '../entities/product.dart';
import '../entities/product_category.dart';

typedef NewProduct = ({
  String name,
  double price,
  double discount,
  double finalPrice,
  int stock,
  ProductCategory category,
  String description,
});

abstract class IProductRepository {
  Stream<List<Product>> watchAll();
  Future<void> updateStock(String productId, int delta);
  Future<void> setStock(String productId, int value);
  Future<void> updateCostPrice(String productId, double costPrice);
  Future<void> updateSalePrice(String productId, double finalPrice);
  Future<void> create(NewProduct product);
}
