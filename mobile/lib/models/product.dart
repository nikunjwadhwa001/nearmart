class ProductVariant {
  final String id;
  final String productId;
  final String variantName;
  final double price;
  final String? unit;
  final String stockStatus;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.variantName,
    required this.price,
    this.unit,
    required this.stockStatus,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['variant_id'] as String,
      productId: json['product_id'] as String,
      variantName: json['variant_name'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String?,
      stockStatus: json['stock_status'] as String? ?? 'in_stock',
    );
  }
}

class Product {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String? brandName;
  final String? imageUrl;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.brandName,
    this.imageUrl,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id'] as String,
      name: json['product_name'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      brandName: json['brand_name'] as String?,
      imageUrl: json['image_url'] as String?,
      variants: (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(v))
          .toList(),
    );
  }
}