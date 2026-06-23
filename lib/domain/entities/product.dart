import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_category.dart';

const int lowStockThreshold = 5;

class ProductImage {
  final String imageUrl;
  final String imagePath;

  const ProductImage({required this.imageUrl, required this.imagePath});
}

class Product {
  final String id;
  final String name;
  final double price;
  final double discount;
  final double finalPrice;
  final int stock;
  final ProductCategory category;
  final String description;
  final List<ProductImage> images;
  final String cover;
  final bool paused;
  final DateTime createdAt;
  final double costPrice;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.discount,
    required this.finalPrice,
    required this.stock,
    required this.category,
    required this.description,
    required this.images,
    required this.cover,
    required this.paused,
    required this.createdAt,
    this.costPrice = 0.0,
  });

  bool get isLowStock => stock <= lowStockThreshold;

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final categoryStr = data['category'] as String? ?? '';
    final category = ProductCategory.fromString(categoryStr);
    if (category == null) {
      throw FormatException('Categoría inválida: $categoryStr');
    }

    final rawImages = data['images'] as List<dynamic>? ?? [];
    final images = rawImages
        .map((img) {
          if (img is Map<String, dynamic>) {
            return ProductImage(
              imageUrl: img['imageUrl'] as String? ?? '',
              imagePath: img['imagePath'] as String? ?? '',
            );
          }
          return null;
        })
        .whereType<ProductImage>()
        .toList();

    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0,
      finalPrice: () {
        final v = (data['finalPrice'] as num?)?.toDouble() ?? 0.0;
        return v.isNaN ? ((data['price'] as num?)?.toDouble() ?? 0.0) : v;
      }(),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      category: category,
      description: data['description'] as String? ?? '',
      images: images,
      cover: data['cover'] as String? ?? '',
      paused: data['paused'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000),
      costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
