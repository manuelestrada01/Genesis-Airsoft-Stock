import '../../domain/repositories/product_repository.dart';

class UpdateProductStock {
  final IProductRepository _repo;
  UpdateProductStock(this._repo);

  Future<void> increment(String productId, int delta) async {
    if (delta == 0) throw Exception('El delta no puede ser 0');
    await _repo.updateStock(productId, delta);
  }

  Future<void> set(String productId, int value) async {
    if (value < 0) throw Exception('El stock no puede ser negativo');
    await _repo.setStock(productId, value);
  }
}
