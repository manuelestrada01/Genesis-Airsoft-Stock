enum ProductCategory {
  insumos('Insumos'),
  marcadorasAEG('Marcadoras AEG'),
  accesorios('Accesorios'),
  indumentaria('Indumentaria'),
  marcadorasGBB('Marcadoras GBB'),
  magazines('Magazines'),
  repuestos('Repuestos');

  const ProductCategory(this.label);
  final String label;

  static ProductCategory? fromString(String value) {
    return ProductCategory.values.cast<ProductCategory?>().firstWhere(
      (c) => c!.label == value,
      orElse: () => null,
    );
  }
}
