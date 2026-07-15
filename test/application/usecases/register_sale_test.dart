import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/application/usecases/register_sale.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';

import '../../helpers/mock_repositories.dart';

SaleItem makeSaleItem({
  String productId = 'prod-1',
  String productName = 'AK-47 AEG',
  int quantity = 2,
  double pricePerUnit = 5000,
  double costPerUnit = 3000,
}) =>
    SaleItem(
      productId: productId,
      productName: productName,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      costPerUnit: costPerUnit,
    );

void main() {
  late MockSaleRepository saleRepo;
  late MockProductRepository productRepo;
  late RegisterSale useCase;

  setUp(() {
    saleRepo = MockSaleRepository();
    productRepo = MockProductRepository();
    useCase = RegisterSale(saleRepo, productRepo);
  });

  group('RegisterSale — validaciones', () {
    test('items vacíos → lanza excepción', () async {
      await expectLater(
        useCase.call(
          items: [],
          paymentMethod: PaymentMethod.cash,
          status: SaleStatus.paid,
          saleType: SaleType.product,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('cantidad ≤ 0 → lanza excepción', () async {
      await expectLater(
        useCase.call(
          items: [makeSaleItem(quantity: 0)],
          paymentMethod: PaymentMethod.cash,
          status: SaleStatus.paid,
          saleType: SaleType.product,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('cantidad negativa → lanza excepción', () async {
      await expectLater(
        useCase.call(
          items: [makeSaleItem(quantity: -1)],
          paymentMethod: PaymentMethod.cash,
          status: SaleStatus.paid,
          saleType: SaleType.product,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('precio ≤ 0 → lanza excepción', () async {
      await expectLater(
        useCase.call(
          items: [makeSaleItem(pricePerUnit: 0)],
          paymentMethod: PaymentMethod.cash,
          status: SaleStatus.paid,
          saleType: SaleType.product,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('precio negativo → lanza excepción', () async {
      await expectLater(
        useCase.call(
          items: [makeSaleItem(pricePerUnit: -100)],
          paymentMethod: PaymentMethod.cash,
          status: SaleStatus.paid,
          saleType: SaleType.product,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('RegisterSale — llamadas a repositorios', () {
    test('crea venta con total correcto (sin descuento)', () async {
      await useCase.call(
        items: [makeSaleItem(quantity: 2, pricePerUnit: 5000)],
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.paid,
        saleType: SaleType.product,
      );

      expect(saleRepo.createdSales.length, 1);
      expect(saleRepo.createdSales.first.total, 10000);
    });

    test('crea venta con total ajustado por descuento', () async {
      await useCase.call(
        items: [makeSaleItem(quantity: 2, pricePerUnit: 5000)],
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.paid,
        saleType: SaleType.product,
        discountPct: 10,
      );

      // 10000 * (1 - 10/100) = 9000
      expect(saleRepo.createdSales.first.total, 9000);
    });

    test('venta de producto → descuenta stock', () async {
      await useCase.call(
        items: [makeSaleItem(productId: 'p-1', quantity: 3)],
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.paid,
        saleType: SaleType.product,
      );

      expect(productRepo.stockIncrements.length, 1);
      expect(productRepo.stockIncrements.first, ('p-1', -3));
    });

    test('venta libre → NO descuenta stock', () async {
      await useCase.call(
        items: [makeSaleItem()],
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.paid,
        saleType: SaleType.free,
      );

      expect(productRepo.stockIncrements, isEmpty);
    });

    test('múltiples items → crea una venta por item', () async {
      await useCase.call(
        items: [
          makeSaleItem(productId: 'p-1', productName: 'AK-47'),
          makeSaleItem(productId: 'p-2', productName: 'Glock 17'),
        ],
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.paid,
        saleType: SaleType.product,
      );

      expect(saleRepo.createdSales.length, 2);
      expect(productRepo.stockIncrements.length, 2);
    });

    test('guarda paymentMethod correcto', () async {
      await useCase.call(
        items: [makeSaleItem()],
        paymentMethod: PaymentMethod.transfer,
        status: SaleStatus.paid,
        saleType: SaleType.product,
      );

      expect(saleRepo.createdSales.first.paymentMethod, PaymentMethod.transfer);
    });

    test('guarda status=debt', () async {
      await useCase.call(
        items: [makeSaleItem()],
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.debt,
        saleType: SaleType.product,
      );

      expect(saleRepo.createdSales.first.status, SaleStatus.debt);
    });

    test('guarda clientName cuando se pasa', () async {
      await useCase.call(
        items: [makeSaleItem()],
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.paid,
        saleType: SaleType.product,
        clientName: 'Juan Pérez',
      );

      expect(saleRepo.createdSales.first.clientName, 'Juan Pérez');
    });

    test('error en saleRepo.create se propaga', () async {
      saleRepo.errorOnCreate = Exception('Firestore offline');

      await expectLater(
        useCase.call(
          items: [makeSaleItem()],
          paymentMethod: PaymentMethod.cash,
          status: SaleStatus.paid,
          saleType: SaleType.product,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('RegisterSale — SaleItem.total', () {
    test('total = quantity × pricePerUnit', () {
      final item = makeSaleItem(quantity: 3, pricePerUnit: 2000);
      expect(item.total, 6000);
    });
  });
}
