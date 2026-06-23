import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

class WatchSales {
  final ISaleRepository _repo;
  WatchSales(this._repo);

  Stream<List<Sale>> call() => _repo.watchAll();
}
