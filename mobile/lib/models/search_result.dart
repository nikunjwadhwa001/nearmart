class SearchResult {
  final String shopId;
  final String shopName;
  final String productId;
  final String productName;
  final String categoryName;
  final String brandName;
  final String variantId;
  final String variantName;
  final double price;
  final String? unit;
  final String stockStatus;
  final String? imageUrl;
  final double distanceKm;

  const SearchResult({
    required this.shopId,
    required this.shopName,
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.brandName,
    required this.variantId,
    required this.variantName,
    required this.price,
    this.unit,
    required this.stockStatus,
    this.imageUrl,
    required this.distanceKm,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      shopId: json['shop_id'] as String,
      shopName: json['shop_name'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      categoryName: json['category_name'] as String,
      brandName: json['brand_name'] as String,
      variantId: json['variant_id'] as String,
      variantName: json['variant_name'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String?,
      stockStatus: json['stock_status'] as String? ?? 'in_stock',
      imageUrl: json['image_url'] as String?,
      distanceKm: (json['distance_km'] as num).toDouble(),
    );
  }
}
