import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class WatchProducts {
  final IProductRepository _repo;
  WatchProducts(this._repo);

  Stream<List<Product>> call() => _repo.watchAll();
}
