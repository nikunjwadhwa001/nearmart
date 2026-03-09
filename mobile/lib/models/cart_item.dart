class CartItem {
  final String variantId;
  final String shopId;
  final String productName;
  final String variantName;
  final double price;
  final int quantity;
  final String? imageUrl;

  const CartItem({
    required this.variantId,
    required this.shopId,
    required this.productName,
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
      productName: productName,
      variantName: variantName,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }
}