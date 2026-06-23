import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../app/icons.dart';
import '../utils/format_currency.dart';
import '../utils/format_date.dart';

class TransactionItem extends StatelessWidget {
  final bool isIncome;
  final String description;
  final double amount;
  final DateTime date;
  final String? detail;
  final String? statusLabel;
  final Color? statusColor;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.isIncome,
    required this.description,
    required this.amount,
    required this.date,
    this.detail,
    this.statusLabel,
    this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome
                  ? const Color(0xFFE8F8EF)
                  : const Color(0xFFFDECEA),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isIncome ? AppIcons.incomeArrow : AppIcons.expenseArrow,
              size: 18,
              color: isIncome ? AppColors.success : AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                Text(
                  formatDate(date),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${formatCurrency(amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isIncome ? AppColors.success : AppColors.danger,
                ),
              ),
              if (statusLabel != null)
                Text(
                  statusLabel!,
                  style: TextStyle(fontSize: 11, color: statusColor ?? AppColors.success),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
