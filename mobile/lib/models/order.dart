class Order {
  final String id;
  final String customerId;
  final String shopId;
  final String? shopName;
  final String status;
  final double subtotal;
  final double commissionRate;
  final double commissionAmount;
  final double totalAmount;
  final String? notes;
  final DateTime placedAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final List<OrderItem>? items;
  final String? deliveryAddress;
  final String? deliveryPhone;

  const Order({
    required this.id,
    required this.customerId,
    required this.shopId,
    this.shopName,
    required this.status,
    required this.subtotal,
    required this.commissionRate,
    required this.commissionAmount,
    required this.totalAmount,
    this.notes,
    required this.placedAt,
    this.confirmedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    this.items,
    this.deliveryAddress,
    this.deliveryPhone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Shop name comes from join: orders joined with shops
    final shopData = json['shops'];
    // Address comes from join: orders joined with addresses
    final addrData = json['addresses'];

    return Order(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      shopId: json['shop_id'] as String,
      shopName: shopData is Map ? shopData['name'] as String? : null,
      status: json['status'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      commissionRate: (json['commission_rate'] as num).toDouble(),
      commissionAmount: (json['commission_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      placedAt: DateTime.parse(json['placed_at'] as String),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      items: json['order_items'] != null
          ? (json['order_items'] as List)
              .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      deliveryAddress: addrData is Map
          ? [
              addrData['address_line'],
              addrData['city'],
              addrData['pincode'],
            ].where((s) => s != null && (s as String).isNotEmpty).join(', ')
          : null,
      deliveryPhone: addrData is Map ? addrData['phone'] as String? : null,
    );
  }

  // Human-readable status label
  String get statusLabel {
    switch (status) {
      case 'placed':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String? inventoryId;
  final String productName;
  final String brandName;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.orderId,
    this.inventoryId,
    required this.productName,
    required this.brandName,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      inventoryId: json['inventory_id'] as String?,
      productName: json['product_name'] as String,
      brandName: json['brand_name'] as String,
      variantName: json['variant_name'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }
}
