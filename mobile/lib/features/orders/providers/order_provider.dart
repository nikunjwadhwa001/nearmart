import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/order.dart';
import '../../../models/cart_item.dart';
import '../repository/order_repository.dart';

final orderRepositoryProvider = Provider((ref) => OrderRepository());

/// Place an order — returns the new order ID.
final placeOrderProvider = FutureProvider.family<String, PlaceOrderParams>(
  (ref, params) async {
    final repo = ref.read(orderRepositoryProvider);
    return repo.placeOrder(
      shopId: params.shopId,
      items: params.items,
      notes: params.notes,
    );
  },
);

/// Fetch all orders for the current user.
final myOrdersProvider = FutureProvider<List<Order>>((ref) {
  final repo = ref.read(orderRepositoryProvider);
  return repo.getMyOrders();
});

/// Fetch a single order by ID.
final orderDetailProvider = FutureProvider.family<Order, String>(
  (ref, orderId) {
    final repo = ref.read(orderRepositoryProvider);
    return repo.getOrder(orderId);
  },
);

/// Simple parameter class for place order.
class PlaceOrderParams {
  final String shopId;
  final List<CartItem> items;
  final String? notes;

  const PlaceOrderParams({
    required this.shopId,
    required this.items,
    this.notes,
  });
}
