enum PeriodType { day, week, month, year }

sealed class BalancePeriod {}

class PeriodPreset extends BalancePeriod {
  final PeriodType type;
  PeriodPreset(this.type);
}

class CustomRange extends BalancePeriod {
  final DateTime from;
  final DateTime to;
  CustomRange({required this.from, required this.to});
}

/// Retorna rango [desde, hasta] para el período dado.
(DateTime from, DateTime to) getDateRangeForPeriod(BalancePeriod period) {
  final now = DateTime.now();

  if (period is CustomRange) {
    return (period.from, period.to);
  }

  final preset = period as PeriodPreset;
  return switch (preset.type) {
    PeriodType.day => (
        DateTime(now.year, now.month, now.day),
        now,
      ),
    PeriodType.week => (
        now.subtract(const Duration(days: 7)),
        now,
      ),
    PeriodType.month => (
        DateTime(now.year, now.month, 1),
        now,
      ),
    PeriodType.year => (
        DateTime(now.year, 1, 1),
        now,
      ),
  };
}

String formatPeriodLabel(BalancePeriod period) {
  return switch (period) {
    PeriodPreset p => switch (p.type) {
        PeriodType.day => 'Hoy',
        PeriodType.week => 'Esta semana',
        PeriodType.month => 'Este mes',
        PeriodType.year => 'Este año',
      },
    CustomRange _ => 'Personalizado',
  };
}
