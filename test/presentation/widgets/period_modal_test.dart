import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/balance_period.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/period_modal.dart';

void suppressOverflow() {
  final saved = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    saved?.call(details);
  };
  addTearDown(() => FlutterError.onError = saved);
}

Widget buildModal({
  BalancePeriod? current,
  ValueChanged<BalancePeriod>? onSelect,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PeriodModal(
        current: current ?? PeriodPreset(PeriodType.month),
        onSelect: onSelect ?? (_) {},
      ),
    ),
  );
}

Widget buildTrigger({
  BalancePeriod? current,
  ValueChanged<BalancePeriod>? onSelect,
}) {
  final c = current ?? PeriodPreset(PeriodType.month);
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showPeriodModal(ctx, current: c, onSelect: onSelect ?? (_) {}),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  group('PeriodModal', () {
    testWidgets('muestra el título del modal', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Elige el periodo que quieres ver:'), findsOneWidget);
    });

    testWidgets('muestra las 4 opciones de periodo', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Diario'), findsOneWidget);
      expect(find.text('Semanal'), findsOneWidget);
      expect(find.text('Mensual'), findsOneWidget);
      expect(find.text('Anual'), findsOneWidget);
    });

    testWidgets('muestra opción "Rango personalizado"', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('Rango personalizado'), findsOneWidget);
    });

    testWidgets('opción activa (Mensual) tiene fontWeight w700', (tester) async {
      await tester.pumpWidget(buildModal(current: PeriodPreset(PeriodType.month)));

      final text = tester.widget<Text>(find.text('Mensual'));
      expect(text.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('opción inactiva tiene fontWeight normal', (tester) async {
      await tester.pumpWidget(buildModal(current: PeriodPreset(PeriodType.month)));

      final text = tester.widget<Text>(find.text('Diario'));
      expect(text.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('current=CustomRange → "Rango personalizado" activo', (tester) async {
      await tester.pumpWidget(buildModal(
        current: CustomRange(from: DateTime(2026, 1, 1), to: DateTime(2026, 6, 30)),
      ));

      final text = tester.widget<Text>(find.text('Rango personalizado'));
      expect(text.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('tap en "Diario" → llama onSelect con PeriodPreset(day)', (tester) async {
      BalancePeriod? selected;
      await tester.pumpWidget(buildModal(onSelect: (p) => selected = p));

      await tester.tap(find.text('Diario'));
      await tester.pump();

      expect(selected, isA<PeriodPreset>());
      expect((selected as PeriodPreset).type, PeriodType.day);
    });

    testWidgets('tap en "Semanal" → llama onSelect con PeriodPreset(week)', (tester) async {
      BalancePeriod? selected;
      await tester.pumpWidget(buildModal(onSelect: (p) => selected = p));

      await tester.tap(find.text('Semanal'));
      await tester.pump();

      expect((selected as PeriodPreset).type, PeriodType.week);
    });

    testWidgets('tap en "Rango personalizado" → llama onSelect con CustomRange', (tester) async {
      BalancePeriod? selected;
      await tester.pumpWidget(buildModal(onSelect: (p) => selected = p));

      await tester.tap(find.text('Rango personalizado'));
      await tester.pump();

      expect(selected, isA<CustomRange>());
    });

    testWidgets('muestra botón ✕ para cerrar', (tester) async {
      await tester.pumpWidget(buildModal());
      expect(find.text('✕'), findsOneWidget);
    });

    testWidgets('showPeriodModal → tap opción cierra el modal', (tester) async {
      suppressOverflow();
      BalancePeriod? selected;
      await tester.pumpWidget(buildTrigger(onSelect: (p) => selected = p));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Diario'), findsOneWidget);

      await tester.tap(find.text('Diario'));
      await tester.pumpAndSettle();

      expect(find.text('Diario'), findsNothing);
      expect(selected, isA<PeriodPreset>());
    });
  });
}
