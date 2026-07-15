import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/application/usecases/register_expense.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/register_expense_modal.dart';

import '../../helpers/mock_repositories.dart';

Widget buildModal({MockExpenseRepository? repo}) {
  final r = repo ?? MockExpenseRepository();
  return MaterialApp(
    home: Scaffold(body: RegisterExpenseModal(useCase: RegisterExpense(r))),
  );
}

void main() {
  group('RegisterExpenseModal', () {
    testWidgets('muestra título "Registrar gasto"', (tester) async {
      await tester.pumpWidget(buildModal());
      // Title + button both contain this text
      expect(find.text('Registrar gasto'), findsWidgets);
    });

    testWidgets('muestra campo Descripción con hint', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Descripción'), findsOneWidget);
      expect(find.text('Ej. Compra de BBs...'), findsOneWidget);
    });

    testWidgets('muestra campo Monto', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Monto'), findsOneWidget);
    });

    testWidgets('muestra las 3 categorías de gasto', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Compra stock'), findsOneWidget);
      expect(find.text('Servicios'), findsOneWidget);
      expect(find.text('Otros'), findsOneWidget);
    });

    testWidgets('categoría por defecto es "Otros"', (tester) async {
      await tester.pumpWidget(buildModal());

      // "Otros" text must be present and rendered with bold weight (selected)
      final otrosText = tester.widget<Text>(find.text('Otros'));
      expect(otrosText.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('tap en categoría → cambia selección a "Compra stock"', (tester) async {
      await tester.pumpWidget(buildModal());

      await tester.tap(find.text('Compra stock'));
      await tester.pump();

      final compraText = tester.widget<Text>(find.text('Compra stock'));
      expect(compraText.style?.fontWeight, FontWeight.w700);

      final otrosText = tester.widget<Text>(find.text('Otros'));
      expect(otrosText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('descripción vacía → error de validación', (tester) async {
      await tester.pumpWidget(buildModal());

      await tester.tap(find.text('Registrar gasto').last);
      await tester.pumpAndSettle();

      expect(find.text('La descripción es requerida'), findsOneWidget);
    });

    testWidgets('monto = 0 → error de validación', (tester) async {
      await tester.pumpWidget(buildModal());

      await tester.enterText(find.byType(TextField).first, 'BBs 0.20g');
      await tester.pump();

      // Leave amount empty (parsed as 0)
      await tester.tap(find.text('Registrar gasto').last);
      await tester.pumpAndSettle();

      expect(find.text('El monto debe ser mayor a 0'), findsOneWidget);
    });

    testWidgets('datos válidos → gasto creado en el repo', (tester) async {
      final repo = MockExpenseRepository();
      await tester.pumpWidget(buildModal(repo: repo));

      await tester.enterText(find.byType(TextField).first, 'BBs 0.20g');
      await tester.enterText(find.byType(TextField).at(1), '5000');
      await tester.pump();

      await tester.tap(find.text('Registrar gasto').last);
      await tester.pumpAndSettle();

      expect(repo.createdExpenses.length, 1);
      expect(repo.createdExpenses.first.description, 'BBs 0.20g');
      expect(repo.createdExpenses.first.amount, 5000);
    });

    testWidgets('muestra botón Cancelar', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('error en repo → muestra mensaje de error', (tester) async {
      final repo = MockExpenseRepository()
        ..errorOnCreate = Exception('Sin conexión');
      await tester.pumpWidget(buildModal(repo: repo));

      await tester.enterText(find.byType(TextField).first, 'BBs');
      await tester.enterText(find.byType(TextField).at(1), '1000');
      await tester.pump();

      await tester.tap(find.text('Registrar gasto').last);
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión'), findsOneWidget);
    });
  });
}
