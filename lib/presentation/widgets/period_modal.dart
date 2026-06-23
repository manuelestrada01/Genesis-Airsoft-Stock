import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../domain/entities/balance_period.dart';

class PeriodModal extends StatelessWidget {
  final BalancePeriod current;
  final ValueChanged<BalancePeriod> onSelect;

  const PeriodModal({super.key, required this.current, required this.onSelect});

  static const _options = [
    (label: 'Diario', type: PeriodType.day),
    (label: 'Semanal', type: PeriodType.week),
    (label: 'Mensual', type: PeriodType.month),
    (label: 'Anual', type: PeriodType.year),
  ];

  bool _isCurrentType(PeriodType type) {
    if (current is PeriodPreset) return (current as PeriodPreset).type == type;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Elige el periodo que quieres ver:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('✕', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._options.map((opt) => _OptionTile(
                label: opt.label,
                isActive: _isCurrentType(opt.type),
                onTap: () {
                  onSelect(PeriodPreset(opt.type));
                  Navigator.pop(context);
                },
              )),
          _OptionTile(
            label: 'Rango personalizado',
            isActive: current is CustomRange,
            onTap: () {
              final now = DateTime.now();
              onSelect(CustomRange(
                from: DateTime(now.year, now.month, 1),
                to: now,
              ));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _OptionTile({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isActive ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

void showPeriodModal(
  BuildContext context, {
  required BalancePeriod current,
  required ValueChanged<BalancePeriod> onSelect,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => PeriodModal(current: current, onSelect: onSelect),
  );
}
