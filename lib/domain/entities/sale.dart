import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod {
  cash('cash', 'Efectivo'),
  card('card', 'Tarjeta'),
  transfer('transfer', 'Transferencia'),
  mercadopago('mercadopago', 'Mercado Pago'),
  qr('qr', 'QR'),
  other('other', 'Otro');

  const PaymentMethod(this.value, this.label);
  final String value;
  final String label;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (m) => m.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

enum SaleStatus {
  paid('paid', 'Pagado'),
  debt('debt', 'Deuda');

  const SaleStatus(this.value, this.label);
  final String value;
  final String label;

  static SaleStatus fromString(String value) {
    return SaleStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => SaleStatus.paid,
    );
  }
}

enum SaleType {
  product('product'),
  free('free');

  const SaleType(this.value);
  final String value;

  static SaleType fromString(String value) {
    return SaleType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => SaleType.product,
    );
  }
}

class Sale {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double pricePerUnit;
  final double costPerUnit;
  final double total;
  final DateTime createdAt;
  final PaymentMethod paymentMethod;
  final SaleStatus status;
  final SaleType saleType;
  final String? clientName;
  final double? discountPct;

  const Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.pricePerUnit,
    required this.costPerUnit,
    required this.total,
    required this.createdAt,
    required this.paymentMethod,
    required this.status,
    required this.saleType,
    this.clientName,
    this.discountPct,
  });

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      pricePerUnit: (data['pricePerUnit'] as num?)?.toDouble() ?? 0,
      costPerUnit: (data['costPerUnit'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000),
      paymentMethod: PaymentMethod.fromString(data['paymentMethod'] as String? ?? ''),
      status: SaleStatus.fromString(data['status'] as String? ?? ''),
      saleType: SaleType.fromString(data['saleType'] as String? ?? ''),
      clientName: data['clientName'] as String?,
      discountPct: (data['discountPct'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'costPerUnit': costPerUnit,
      'total': total,
      'createdAt': FieldValue.serverTimestamp(),
      'paymentMethod': paymentMethod.value,
      'status': status.value,
      'saleType': saleType.value,
      if (clientName != null) 'clientName': clientName,
      if (discountPct != null) 'discountPct': discountPct,
    };
  }
}
