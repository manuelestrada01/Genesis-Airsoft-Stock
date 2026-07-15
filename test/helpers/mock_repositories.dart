import 'package:firebase_auth/firebase_auth.dart';
import 'package:genesis_airsoft_stock/domain/entities/expense.dart';
import 'package:genesis_airsoft_stock/domain/entities/product.dart';
import 'package:genesis_airsoft_stock/domain/entities/product_category.dart';
import 'package:genesis_airsoft_stock/domain/entities/sale.dart';
import 'package:genesis_airsoft_stock/domain/repositories/expense_repository.dart';
import 'package:genesis_airsoft_stock/domain/repositories/product_repository.dart';
import 'package:genesis_airsoft_stock/domain/repositories/sale_repository.dart';
import 'package:genesis_airsoft_stock/infrastructure/auth/auth_service.dart';

class MockAuthService implements IAuthService {
  int signInCallCount = 0;
  FirebaseAuthException? throwOnSignIn;
  bool neverCompletes = false;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<void> signIn(String email, String password) async {
    signInCallCount++;
    if (neverCompletes) await Future<void>.delayed(const Duration(hours: 1));
    if (throwOnSignIn != null) throw throwOnSignIn!;
  }

  @override
  Future<void> signOut() async {}
}

class MockSaleRepository implements ISaleRepository {
  final List<NewSale> createdSales = [];
  Exception? errorOnCreate;

  @override
  Future<void> create(NewSale sale) async {
    if (errorOnCreate != null) throw errorOnCreate!;
    createdSales.add(sale);
  }

  @override
  Stream<List<Sale>> watchAll() => const Stream.empty();

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {}

  @override
  Future<void> delete(String id) async {}
}

class MockProductRepository implements IProductRepository {
  final List<(String id, int delta)> stockIncrements = [];
  final List<(String id, int value)> stockSets = [];
  Exception? errorOnUpdate;

  @override
  Future<void> updateStock(String productId, int delta) async {
    if (errorOnUpdate != null) throw errorOnUpdate!;
    stockIncrements.add((productId, delta));
  }

  @override
  Future<void> setStock(String productId, int value) async {
    if (errorOnUpdate != null) throw errorOnUpdate!;
    stockSets.add((productId, value));
  }

  @override
  Stream<List<Product>> watchAll() => const Stream.empty();

  @override
  Future<void> updateCostPrice(String productId, double costPrice) async {}

  @override
  Future<void> updateSalePrice(String productId, double finalPrice) async {}

  @override
  Future<void> create(NewProduct product) async {}
}

class MockExpenseRepository implements IExpenseRepository {
  final List<NewExpense> createdExpenses = [];
  Exception? errorOnCreate;

  @override
  Future<void> create(NewExpense expense) async {
    if (errorOnCreate != null) throw errorOnCreate!;
    createdExpenses.add(expense);
  }

  @override
  Stream<List<Expense>> watchAll() => const Stream.empty();
}
