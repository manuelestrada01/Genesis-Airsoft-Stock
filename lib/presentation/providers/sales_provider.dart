import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../infrastructure/firebase/firestore_sale_repository.dart';

final saleRepositoryProvider = Provider<ISaleRepository>((ref) {
  return FirestoreSaleRepository();
});

final allSalesProvider = StreamProvider<List<Sale>>((ref) {
  return ref.watch(saleRepositoryProvider).watchAll();
});
