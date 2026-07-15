import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_airsoft_stock/domain/entities/product_category.dart';

void main() {
  group('ProductCategory.fromString', () {
    test('string exacto → devuelve categoría', () {
      expect(ProductCategory.fromString('Insumos'), ProductCategory.insumos);
      expect(ProductCategory.fromString('Marcadoras AEG'), ProductCategory.marcadorasAEG);
      expect(ProductCategory.fromString('Accesorios'), ProductCategory.accesorios);
      expect(ProductCategory.fromString('Indumentaria'), ProductCategory.indumentaria);
      expect(ProductCategory.fromString('Marcadoras GBB'), ProductCategory.marcadorasGBB);
      expect(ProductCategory.fromString('Magazines'), ProductCategory.magazines);
      expect(ProductCategory.fromString('Repuestos'), ProductCategory.repuestos);
      expect(ProductCategory.fromString('Baterías'), ProductCategory.baterias);
      expect(ProductCategory.fromString('Mantenimiento'), ProductCategory.mantenimiento);
    });

    test('string sin acento → coincide con categoría acentuada', () {
      expect(ProductCategory.fromString('Baterias'), ProductCategory.baterias);
    });

    test('mayúsculas/minúsculas ignoradas', () {
      expect(ProductCategory.fromString('insumos'), ProductCategory.insumos);
      expect(ProductCategory.fromString('INSUMOS'), ProductCategory.insumos);
      expect(ProductCategory.fromString('marcadoras aeg'), ProductCategory.marcadorasAEG);
    });

    test('espacios extremos ignorados', () {
      expect(ProductCategory.fromString('  Insumos  '), ProductCategory.insumos);
    });

    test('categoría inválida → devuelve null', () {
      expect(ProductCategory.fromString('Pistolas'), isNull);
      expect(ProductCategory.fromString(''), isNull);
      expect(ProductCategory.fromString('xxx'), isNull);
    });

    test('todas las categorías están mapeadas (9 categorías)', () {
      expect(ProductCategory.values.length, 9);
    });
  });
}
