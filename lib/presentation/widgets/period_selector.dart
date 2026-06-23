import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../domain/entities/balance_period.dart';

class PeriodSelector extends StatelessWidget {
  final DateTime selectedDate;
  final BalancePeriod period;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<BalancePeriod> onSelectPeriod;
  final VoidCallback onOpenPeriodModal;
  final PeriodType? contextType;

  const PeriodSelector({
    super.key,
    required this.selectedDate,
    required this.period,
    required this.onSelectDate,
    required this.onSelectPeriod,
    required this.onOpenPeriodModal,
    this.contextType,
  });

  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  List<DateTime> _getLast7Days() {
    final days = <DateTime>[];
    for (int i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      days.add(DateTime(d.year, d.month, d.day));
    }
    return days;
  }

  List<({DateTime from, DateTime to, String label})> _getWeeksOfMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final weeks = <({DateTime from, DateTime to, String label})>[];
    var weekStart = firstDay;
    int weekNum = 1;
    while (weekStart.isBefore(lastDay) || weekStart.isAtSameMomentAs(lastDay)) {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final actualEnd = weekEnd.isAfter(lastDay) ? lastDay : weekEnd;
      weeks.add((
        from: weekStart,
        to: DateTime(actualEnd.year, actualEnd.month, actualEnd.day, 23, 59, 59),
        label: 'S$weekNum ${weekStart.day}-${actualEnd.day} ${_months[now.month - 1]}',
      ));
      weekStart = actualEnd.add(const Duration(days: 1));
      weekNum++;
    }
    return weeks;
  }

  List<({DateTime from, DateTime to, String label})> _getLast4Weeks() {
    final now = DateTime.now();
    final weeks = <({DateTime from, DateTime to, String label})>[];
    for (int i = 3; i >= 0; i--) {
      final weekEnd = now.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      final ws = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final we = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);
      weeks.add((
        from: ws,
        to: we,
        label: '${ws.day} ${_months[ws.month - 1]}-${weekEnd.day} ${_months[weekEnd.month - 1]}',
      ));
    }
    return weeks;
  }

  List<({DateTime from, DateTime to, String label})> _getMonthsOfYear() {
    final now = DateTime.now();
    final result = <({DateTime from, DateTime to, String label})>[];
    for (int m = 1; m <= now.month; m++) {
      final from = DateTime(now.year, m, 1);
      final to = DateTime(now.year, m + 1, 0, 23, 59, 59);
      result.add((from: from, to: to, label: _months[m - 1]));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveType = contextType ?? (period is PeriodPreset ? (period as PeriodPreset).type : null);

    return Container(
      color: AppColors.primary,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: _buildChips(effectiveType, context),
              ),
            ),
          ),
          GestureDetector(
            onTap: onOpenPeriodModal,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.calendar_today_outlined, size: 22, color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChips(PeriodType? periodType, BuildContext context) {
    if (periodType == PeriodType.month) {
      final weeks = _getWeeksOfMonth();
      return weeks.map((w) {
        final isSelected = period is CustomRange &&
            (period as CustomRange).from.day == w.from.day &&
            (period as CustomRange).from.month == w.from.month;
        return _chip(
          label: w.label,
          isSelected: isSelected,
          onTap: () => onSelectPeriod(CustomRange(from: w.from, to: w.to)),
        );
      }).toList();
    }

    if (periodType == PeriodType.week) {
      final weeks = _getLast4Weeks();
      return weeks.map((w) {
        final isSelected = period is CustomRange &&
            (period as CustomRange).from.day == w.from.day &&
            (period as CustomRange).from.month == w.from.month;
        return _chip(
          label: w.label,
          isSelected: isSelected,
          onTap: () => onSelectPeriod(CustomRange(from: w.from, to: w.to)),
        );
      }).toList();
    }

    if (periodType == PeriodType.year) {
      final months = _getMonthsOfYear();
      return months.map((m) {
        final isSelected = period is CustomRange &&
            (period as CustomRange).from.month == m.from.month;
        return _chip(
          label: m.label,
          isSelected: isSelected,
          onTap: () => onSelectPeriod(CustomRange(from: m.from, to: m.to)),
        );
      }).toList();
    }

    // Default: últimos 7 días (PeriodType.day o CustomRange individual)
    final days = _getLast7Days();
    final selDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return days.map((d) {
      final isSelected = d == selDay;
      return _chip(
        label: '${d.day} ${_months[d.month - 1]}',
        isSelected: isSelected,
        onTap: () => onSelectDate(d),
      );
    }).toList();
  }

  Widget _chip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.dark : Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
