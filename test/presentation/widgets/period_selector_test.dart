import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/balance_period.dart';
import 'package:genesis_airsoft_stock/presentation/widgets/period_selector.dart';

Widget buildSelector({
  BalancePeriod? period,
  PeriodType? contextType,
  DateTime? selectedDate,
  ValueChanged<DateTime>? onSelectDate,
  ValueChanged<BalancePeriod>? onSelectPeriod,
  VoidCallback? onOpenPeriodModal,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PeriodSelector(
        selectedDate: selectedDate ?? DateTime.now(),
        period: period ?? PeriodPreset(PeriodType.day),
        contextType: contextType,
        onSelectDate: onSelectDate ?? (_) {},
        onSelectPeriod: onSelectPeriod ?? (_) {},
        onOpenPeriodModal: onOpenPeriodModal ?? () {},
      ),
    ),
  );
}

void main() {
  group('PeriodSelector', () {
    testWidgets('muestra ícono de calendario', (tester) async {
      await tester.pumpWidget(buildSelector());
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('tap en calendario → llama onOpenPeriodModal', (tester) async {
      bool opened = false;
      await tester.pumpWidget(buildSelector(onOpenPeriodModal: () => opened = true));

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pump();

      expect(opened, isTrue);
    });

    testWidgets('modo día (default) → muestra chips de fecha', (tester) async {
      // Wide viewport so all 7 day chips are visible
      tester.view.physicalSize = const Size(2000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildSelector(contextType: PeriodType.day));

      // Today's chip matches "d mmm" — just verify multiple chips exist
      final texts = tester.widgetList<Text>(
        find.descendant(of: find.byType(PeriodSelector), matching: find.byType(Text)),
      ).map((t) => t.data ?? '').toList();

      // 7 day chips + calendar icon (no text)
      expect(texts.where((t) => t.isNotEmpty).length, greaterThanOrEqualTo(7));
    });

    testWidgets('contextType=month → muestra etiquetas de meses', (tester) async {
      tester.view.physicalSize = const Size(2000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildSelector(
        contextType: PeriodType.month,
        period: PeriodPreset(PeriodType.month),
      ));

      // Month chips are 'ene', 'feb', ... up to current month
      expect(find.text('ene'), findsOneWidget);
    });

    testWidgets('contextType=year → muestra año actual', (tester) async {
      tester.view.physicalSize = const Size(2000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildSelector(
        contextType: PeriodType.year,
        period: PeriodPreset(PeriodType.year),
      ));

      expect(find.text('${DateTime.now().year}'), findsOneWidget);
    });

    testWidgets('contextType=week → muestra 4 chips de semana', (tester) async {
      tester.view.physicalSize = const Size(2000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildSelector(
        contextType: PeriodType.week,
        period: PeriodPreset(PeriodType.week),
      ));

      // Week chips: 4 items, each has "-" in label like "9 jul-15 jul"
      final chipTexts = tester.widgetList<Text>(
        find.descendant(of: find.byType(PeriodSelector), matching: find.byType(Text)),
      ).where((t) => (t.data ?? '').contains('-')).toList();

      expect(chipTexts.length, 4);
    });

    testWidgets('chip seleccionado tiene fontWeight w700', (tester) async {
      final today = DateTime.now();
      final todayNorm = DateTime(today.year, today.month, today.day);

      await tester.pumpWidget(buildSelector(
        contextType: PeriodType.day,
        period: PeriodPreset(PeriodType.day),
        selectedDate: todayNorm,
      ));

      // The selected chip (today) should be bold
      // Find chip with today's day number
      final dayStr = '${today.day}';
      final texts = tester.widgetList<Text>(
        find.descendant(of: find.byType(PeriodSelector), matching: find.byType(Text)),
      ).where((t) => (t.data ?? '').startsWith(dayStr)).toList();

      expect(texts.isNotEmpty, isTrue);
      expect(texts.first.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('tap en chip de mes → llama onSelectPeriod con CustomRange', (tester) async {
      tester.view.physicalSize = const Size(2000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      BalancePeriod? selected;
      await tester.pumpWidget(buildSelector(
        contextType: PeriodType.month,
        period: PeriodPreset(PeriodType.month),
        onSelectPeriod: (p) => selected = p,
      ));

      await tester.tap(find.text('ene'));
      await tester.pump();

      expect(selected, isA<CustomRange>());
      expect((selected as CustomRange).from.month, 1);
    });

    testWidgets('tap en chip de año → llama onSelectPeriod con CustomRange del año', (tester) async {
      tester.view.physicalSize = const Size(2000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      BalancePeriod? selected;
      await tester.pumpWidget(buildSelector(
        contextType: PeriodType.year,
        period: PeriodPreset(PeriodType.year),
        onSelectPeriod: (p) => selected = p,
      ));

      await tester.tap(find.text('${DateTime.now().year}'));
      await tester.pump();

      expect(selected, isA<CustomRange>());
      expect((selected as CustomRange).from.year, DateTime.now().year);
    });
  });
}
