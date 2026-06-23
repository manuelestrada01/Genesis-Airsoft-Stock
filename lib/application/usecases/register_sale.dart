import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/product_repository.dart';

class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double pricePerUnit;
  final double costPerUnit;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.pricePerUnit,
    required this.costPerUnit,
  });

  double get total => quantity * pricePerUnit;
}

class RegisterSale {
  final ISaleRepository _saleRepo;
  final IProductRepository _productRepo;

  RegisterSale(this._saleRepo, this._productRepo);

  Future<void> call({
    required List<SaleItem> items,
    required PaymentMethod paymentMethod,
    required SaleStatus status,
    required SaleType saleType,
    String? clientName,
    double? discountPct,
  }) async {
    if (items.isEmpty) throw Exception('Debe agregar al menos un producto');

    for (final item in items) {
      if (item.quantity <= 0) throw Exception('La cantidad debe ser mayor a 0');
      if (item.pricePerUnit <= 0) throw Exception('El precio debe ser mayor a 0');

      final total = item.total;
      await _saleRepo.create((
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        pricePerUnit: item.pricePerUnit,
        costPerUnit: item.costPerUnit,
        total: total,
        paymentMethod: paymentMethod,
        status: status,
        saleType: saleType,
        clientName: clientName,
        discountPct: discountPct,
      ));

      // Deducir stock solo para ventas de producto
      if (saleType == SaleType.product) {
        await _productRepo.updateStock(item.productId, -item.quantity);
      }
    }
  }
}
