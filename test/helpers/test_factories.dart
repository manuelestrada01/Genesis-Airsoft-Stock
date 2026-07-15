import 'package:genesis_airsoft_stock/domain/entities/expense.dart';
import 'package:genesis_airsoft_stock/domain/entities/product.dart';
import 'package:genesis_airsoft_stock/domain/entities/product_category.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';

Sale makeSale({
  String id = 'sale-1',
  String productId = 'prod-1',
  String productName = 'AK-47 AEG',
  int quantity = 1,
  double pricePerUnit = 5000,
  double costPerUnit = 3000,
  double total = 5000,
  DateTime? createdAt,
  PaymentMethod paymentMethod = PaymentMethod.cash,
  SaleStatus status = SaleStatus.paid,
  SaleType saleType = SaleType.product,
  String? clientName,
  double? discountPct,
}) =>
    Sale(
      id: id,
      productId: productId,
      productName: productName,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      costPerUnit: costPerUnit,
      total: total,
      createdAt: createdAt ?? DateTime.now(),
      paymentMethod: paymentMethod,
      status: status,
      saleType: saleType,
      clientName: clientName,
      discountPct: discountPct,
    );

Product makeProduct({
  String id = 'prod-1',
  String name = 'AK-47 AEG',
  double price = 50000,
  double discount = 0,
  double finalPrice = 50000,
  int stock = 10,
  ProductCategory category = ProductCategory.marcadorasAEG,
  String description = '',
  String cover = '',
  bool paused = false,
  double costPrice = 30000,
  DateTime? createdAt,
}) =>
    Product(
      id: id,
      name: name,
      price: price,
      discount: discount,
      finalPrice: finalPrice,
      stock: stock,
      category: category,
      description: description,
      images: [],
      cover: cover,
      paused: paused,
      createdAt: createdAt ?? DateTime(2025, 1, 1),
      costPrice: costPrice,
    );

Expense makeExpense({
  String id = 'exp-1',
  String description = 'Compra de BBs',
  double amount = 1000,
  String category = 'Compra stock',
  DateTime? createdAt,
}) =>
    Expense(
      id: id,
      description: description,
      amount: amount,
      category: category,
      createdAt: createdAt ?? DateTime.now(),
    );
