import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/shop_inventory_repository.dart';
import '../../../models/product.dart';

// Provides a single instance of ShopInventoryRepository
// Provider — simplest type, just holds a value, no state changes
// ref.read(shopInventoryRepositoryProvider) gives you the repository
final shopInventoryRepositoryProvider =
    Provider<ShopInventoryRepository>((ref) {
  // Every time this is read, same instance is returned
  // not a new one — Riverpod caches it
  return ShopInventoryRepository();
});

// FutureProvider.family — fetches async data that needs a parameter
// Without .family, every shop would share the same provider instance
// With .family, each shopId gets its OWN provider instance
// Think of it like a function: shopInventoryProvider('shop-uuid') 
// returns a unique provider for that specific shop
final shopInventoryProvider =
    FutureProvider.family<Map<String, List<Product>>, String>(
        (ref, shopId) async {
  // ref.read because we're inside a callback — not a build method
  // We don't need to watch the repository — it never changes
  final repository = ref.read(shopInventoryRepositoryProvider);

  // Fetch and return inventory for this specific shop
  // Riverpod automatically handles loading/error/data states
  return repository.getShopInventory(shopId);
});