import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../domain/entities/product_category.dart';

/// selected: null = Todos, ProductCategory = filtro, 'lowStock' = stock bajo
class CategoryFilter extends StatelessWidget {
  final Object? selected;
  final ValueChanged<Object?> onSelect;
  final bool showLowStock;

  const CategoryFilter({
    super.key,
    required this.selected,
    required this.onSelect,
    this.showLowStock = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(
            label: 'Todos',
            isSelected: selected == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...ProductCategory.values.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: cat.label,
                  isSelected: selected == cat,
                  onTap: () => onSelect(cat),
                ),
              )),
          if (showLowStock)
            _LowStockChip(
              isSelected: selected == 'lowStock',
              onTap: () => onSelect('lowStock'),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.dark : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected ? AppColors.dark : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}

class _LowStockChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _LowStockChip({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.danger : const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected ? AppColors.danger : AppColors.danger,
          ),
        ),
        child: Text(
          'Stock bajo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.danger,
          ),
        ),
      ),
    );
  }
}
