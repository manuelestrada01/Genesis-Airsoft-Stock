import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum QuickActionVariant { dark, light }

class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final QuickActionVariant variant;
  final VoidCallback onPress;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.variant,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = variant == QuickActionVariant.dark;
    return GestureDetector(
      onTap: onPress,
      child: Container(
        width: 110,
        height: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isDark ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 24,
              color: isDark ? AppColors.primary : AppColors.dark,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
