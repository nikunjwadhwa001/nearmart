import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/order.dart';
import '../../../models/cart_item.dart';
import '../../../core/cache/query_cache.dart';

class OrderRepository {
  final _supabase = Supabase.instance.client;
  // Shared cache utility reused across repository calls.
  final _cache = QueryCache.instance;

  /// Place an order using the atomic RPC function.
  /// Returns the new order's UUID.
  Future<String> placeOrder({
    required String shopId,
    required List<CartItem> items,
    String? deliveryAddressId,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    // Build the items array that the RPC expects
    final itemsJson = items.map((item) => {
      'variant_id': item.variantId,
      'product_name': item.productName,
      'brand_name': item.brandName,
      'variant_name': item.variantName,
      'quantity': item.quantity,
      'unit_price': item.price,
    }).toList();

    final orderId = await _supabase.rpc(
      'place_order',
      params: {
        'p_shop_id': shopId,
        'p_items': itemsJson,
        'p_delivery_address_id': deliveryAddressId,
        'p_notes': notes,
      },
    );

    // Order placement mutates timeline + totals, so invalidate relevant reads.
    if (userId != null) {
      await _cache.invalidate('orders_list:v2:user:$userId');
      await _cache.invalidatePrefix('order_detail:v2:user:$userId:');
    }

    return orderId as String;
  }

  /// Fetch all orders for the current customer, newest first.
  Future<List<Order>> getMyOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // User-scoped key avoids sharing order history between accounts.
    final key = 'orders_list:v2:user:$userId';

    final response = await _cache.getOrFetch<List<dynamic>>(
      key: key,
      // Short TTL keeps order list fresh while still reducing repeated calls.
      ttl: const Duration(seconds: 45),
      fetcher: () async {
        final result = await _supabase
            .from('orders')
            .select('*, shops(name), order_items(*), addresses(address_line, city, pincode, phone)')
            .eq('customer_id', userId)
            .order('placed_at', ascending: false);
        return (result as List).cast<dynamic>();
      },
      decode: (raw) => (raw as List).cast<dynamic>(),
      encode: (value) => value,
    );

    return response
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single order with its items.
  Future<Order> getOrder(String orderId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not logged in');
    }

    // One cache entry per order, per user.
    final key = 'order_detail:v2:user:$userId:order:$orderId';

    final response = await _cache.getOrFetch<Map<String, dynamic>>(
      key: key,
      // Detail view refreshes frequently after placement/status updates.
      ttl: const Duration(seconds: 30),
      fetcher: () async {
        final result = await _supabase
            .from('orders')
            .select('*, shops(name), order_items(*), addresses(address_line, city, pincode, phone)')
            .eq('id', orderId)
            .eq('customer_id', userId)
            .single();
        return Map<String, dynamic>.from(result as Map);
      },
      decode: (raw) => Map<String, dynamic>.from(raw as Map),
      encode: (value) => value,
    );

    return Order.fromJson(response);
  }
}
