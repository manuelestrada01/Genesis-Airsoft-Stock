import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../application/usecases/update_product_stock.dart';
import '../../domain/entities/product_category.dart';
import '../providers/products_provider.dart';
import '../utils/format_currency.dart';
import '../widgets/header.dart';
import '../widgets/product_card.dart';
import '../widgets/category_filter.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/update_stock_modal.dart';
import 'create_product_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _searchVisible = false;

  @override
  Widget build(BuildContext context) {
    final allProductsAsync = ref.watch(allProductsProvider);
    final filteredAsync = ref.watch(filteredProductsProvider);
    final allProducts = allProductsAsync.valueOrNull ?? [];
    final totalCost = allProducts.fold(0.0, (sum, p) => sum + p.costPrice * p.stock);
    final totalSaleValue = allProducts.fold(0.0, (sum, p) {
      final fp = p.finalPrice.isNaN ? p.price : p.finalPrice;
      return sum + fp * p.stock;
    });
    final categoryFilter = ref.watch(categoryFilterProvider);
    final lowStockFilter = ref.watch(lowStockFilterProvider);

    final stockRepo = ref.read(productRepositoryProvider);
    final updateStock = UpdateProductStock(stockRepo);

    // Determine current selection for CategoryFilter
    Object? filterSelection;
    if (lowStockFilter) {
      filterSelection = 'lowStock';
    } else {
      filterSelection = categoryFilter;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Header(
            title: 'Genesis Airsoft',
            subtitle: 'Inventario',
            showAvatar: true,
            rightContent: GestureDetector(
              onTap: () {
                setState(() => _searchVisible = !_searchVisible);
                if (_searchVisible) ref.read(searchQueryProvider.notifier).state = '';
              },
              child: Icon(
                _searchVisible ? Icons.search_off : Icons.search,
                color: AppColors.dark,
                size: 24,
              ),
            ),
          ),
          if (_searchVisible)
            SearchBarWidget(
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
            ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Referencias: ',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: '${allProducts.length}',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: 'Costo: ',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: formatCurrency(totalCost),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Valor de venta: ',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: formatCurrency(totalSaleValue),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CategoryFilter(
            selected: filterSelection,
            onSelect: (v) {
              if (v == null) {
                ref.read(categoryFilterProvider.notifier).state = null;
                ref.read(lowStockFilterProvider.notifier).state = false;
              } else if (v == 'lowStock') {
                ref.read(lowStockFilterProvider.notifier).state = true;
                ref.read(categoryFilterProvider.notifier).state = null;
              } else {
                ref.read(categoryFilterProvider.notifier).state = v as ProductCategory;
                ref.read(lowStockFilterProvider.notifier).state = false;
              }
            },
            showLowStock: true,
          ),
          Expanded(
            child: filteredAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: 6,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: const SkeletonProductCard(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: AppColors.danger)),
              ),
              data: (products) => products.isEmpty
                  ? const EmptyState(
                      title: 'Sin productos',
                      subtitle: 'No hay productos en esta categoría.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: products.length,
                      itemBuilder: (_, idx) => ProductCard(
                        product: products[idx],
                        onPress: (product) => showUpdateStockModal(
                          context,
                          product: product,
                          onConfirm: (id, delta) => updateStock.increment(id, delta),
                          onSet: (id, val) => updateStock.set(id, val),
                          onUpdatePrice: (id, cost) => stockRepo.updateCostPrice(id, cost),
                          onUpdateSalePrice: (id, price) => stockRepo.updateSalePrice(id, price),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => CreateProductScreen(repo: stockRepo),
              ),
            );
            if (created == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Producto creado exitosamente'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: const Text('+ Crear producto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
