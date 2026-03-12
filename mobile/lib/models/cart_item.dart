class CartItem {
  final String variantId;
  final String shopId;
  final String shopName;
  final String productName;
  final String brandName;
  final String variantName;
  final double price;
  final int quantity;
  final String? imageUrl;

  const CartItem({
    required this.variantId,
    required this.shopId,
    required this.shopName,
    required this.productName,
    required this.brandName,
    required this.variantName,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  double get total => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      variantId: variantId,
      shopId: shopId,
      shopName: shopName,
      productName: productName,
      brandName: brandName,
      variantName: variantName,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }
}