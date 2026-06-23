import '../entities/sale.dart';

typedef NewSale = ({
  String productId,
  String productName,
  int quantity,
  double pricePerUnit,
  double costPerUnit,
  double total,
  PaymentMethod paymentMethod,
  SaleStatus status,
  SaleType saleType,
  String? clientName,
  double? discountPct,
});

abstract class ISaleRepository {
  Stream<List<Sale>> watchAll();
  Future<void> create(NewSale sale);
  Future<void> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
}
