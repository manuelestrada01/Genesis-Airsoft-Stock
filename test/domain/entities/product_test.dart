import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/product.dart';
import 'package:genesis_airsoft_stock/domain/entities/product_category.dart';

Product makeProduct({int stock = 10}) => Product(
      id: 'p-1',
      name: 'AK-47 AEG',
      price: 50000,
      discount: 0,
      finalPrice: 50000,
      stock: stock,
      category: ProductCategory.marcadorasAEG,
      description: '',
      images: [],
      cover: '',
      paused: false,
      createdAt: DateTime(2025, 1, 1),
      costPrice: 30000,
    );

void main() {
  group('Product.isLowStock', () {
    test('stock = 0 → isLowStock true', () {
      expect(makeProduct(stock: 0).isLowStock, isTrue);
    });

    test('stock = 1 → isLowStock true', () {
      expect(makeProduct(stock: 1).isLowStock, isTrue);
    });

    test('stock = 5 → isLowStock true (límite inferior)', () {
      expect(makeProduct(stock: 5).isLowStock, isTrue);
    });

    test('stock = 6 → isLowStock false (límite superior)', () {
      expect(makeProduct(stock: 6).isLowStock, isFalse);
    });

    test('stock = 100 → isLowStock false', () {
      expect(makeProduct(stock: 100).isLowStock, isFalse);
    });
  });

  group('lowStockThreshold', () {
    test('constante es 5', () {
      expect(lowStockThreshold, 5);
    });
  });
}
