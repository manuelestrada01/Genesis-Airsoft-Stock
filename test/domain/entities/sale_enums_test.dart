import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';

void main() {
  group('PaymentMethod.fromString', () {
    test('mapea todos los valores válidos', () {
      expect(PaymentMethod.fromString('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('card'), PaymentMethod.card);
      expect(PaymentMethod.fromString('transfer'), PaymentMethod.transfer);
      expect(PaymentMethod.fromString('mercadopago'), PaymentMethod.mercadopago);
      expect(PaymentMethod.fromString('qr'), PaymentMethod.qr);
      expect(PaymentMethod.fromString('other'), PaymentMethod.other);
    });

    test('valor inválido → fallback a cash', () {
      expect(PaymentMethod.fromString(''), PaymentMethod.cash);
      expect(PaymentMethod.fromString('bitcoin'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('CASH'), PaymentMethod.cash);
    });
  });

  group('SaleStatus.fromString', () {
    test('mapea valores válidos', () {
      expect(SaleStatus.fromString('paid'), SaleStatus.paid);
      expect(SaleStatus.fromString('debt'), SaleStatus.debt);
    });

    test('valor inválido → fallback a paid', () {
      expect(SaleStatus.fromString(''), SaleStatus.paid);
      expect(SaleStatus.fromString('unknown'), SaleStatus.paid);
    });
  });

  group('SaleType.fromString', () {
    test('mapea valores válidos', () {
      expect(SaleType.fromString('product'), SaleType.product);
      expect(SaleType.fromString('free'), SaleType.free);
    });

    test('valor inválido → fallback a product', () {
      expect(SaleType.fromString(''), SaleType.product);
      expect(SaleType.fromString('unknown'), SaleType.product);
    });
  });

  group('PaymentMethod.label', () {
    test('labels son descriptivos', () {
      expect(PaymentMethod.cash.label, 'Efectivo');
      expect(PaymentMethod.transfer.label, 'Transferencia');
      expect(PaymentMethod.mercadopago.label, 'Mercado Pago');
    });
  });

  group('SaleStatus.label', () {
    test('labels en español', () {
      expect(SaleStatus.paid.label, 'Pagado');
      expect(SaleStatus.debt.label, 'Deuda');
    });
  });
}
