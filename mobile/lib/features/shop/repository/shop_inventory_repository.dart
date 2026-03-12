import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product.dart';
import '../../../core/cache/query_cache.dart';

class ShopInventoryRepository {
  // Get the Supabase client — our connection to the database
  final _supabase = Supabase.instance.client;
  // Shared cache utility reused across repository calls.
  final _cache = QueryCache.instance;

  Future<Map<String, List<Product>>> getShopInventory(String shopId) async {
    final userId = _supabase.auth.currentUser?.id ?? 'anon';
    // Per-shop key keeps inventories isolated and safe across accounts.
    final key = 'shop_inventory:v1:user:$userId:shop:$shopId';

    final response = await _cache.getOrFetch<List<dynamic>>(
      key: key,
      // Inventory changes relatively often; keep TTL shorter than nearby shops.
      ttl: const Duration(minutes: 2),
      fetcher: () async {
        final result = await _supabase.rpc(
          'get_shop_inventory',
          params: {'shop_id_input': shopId},
        );
        return (result as List).cast<dynamic>();
      },
      decode: (raw) => (raw as List).cast<dynamic>(),
      encode: (value) => value,
    );

    // response is a flat list of rows like this:
    // [{product_id: x, variant_id: a, price: 50}, 
    //  {product_id: x, variant_id: b, price: 80},  ← same product, diff variant
    //  {product_id: y, variant_id: c, price: 30}]
    // We need to group rows with the same product_id together

    // Step 1 — Group rows by product_id
    // Map<productId, List of rows belonging to that product>
    final Map<String, List<Map<String, dynamic>>> productRows = {};

    for (final row in response) {
      final rowMap = Map<String, dynamic>.from(row as Map);
      final productId = rowMap['product_id'] as String;
      // putIfAbsent — if key doesn't exist, create empty list
      // if key exists, do nothing — just return existing list
      productRows.putIfAbsent(productId, () => []);
      // Add this row to that product's list
      productRows[productId]!.add(rowMap);
    }

    // Step 2 — Convert each group into a Product object with its variants
    final List<Product> products = productRows.values.map((rows) {
      // All rows for the same product share the same product info
      // Only variant info (variant_id, price etc) differs per row
      final firstRow = rows.first;

      return Product(
        id: firstRow['product_id'] as String,
        name: firstRow['product_name'] as String,
        categoryId: firstRow['category_id'] as String,
        categoryName: firstRow['category_name'] as String,
        brandName: firstRow['brand_name'] as String?,
        imageUrl: firstRow['image_url'] as String?,
        // Each row represents one variant — convert all rows to variants
        variants: rows
            .map((row) => ProductVariant.fromJson(row))
            .toList(),
      );
    }).toList();

    // Step 3 — Group products by category name
    // Final result: {'Dairy & Eggs': [Product1, Product2], 'Snacks': [...]}
    final Map<String, List<Product>> grouped = {};

    for (final product in products) {
      grouped.putIfAbsent(product.categoryName, () => []);
      grouped[product.categoryName]!.add(product);
    }

    return grouped;
  }
}