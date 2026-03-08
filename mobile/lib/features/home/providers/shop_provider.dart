import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/shop_repository.dart';
import '../../../models/shop.dart';

// This provides a single instance of ShopRepository
// 'Provider' means it just holds a value — no state changes
final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository();
});

// This holds the customer's current location
// StateProvider is for simple values that can change
// We start with null because we don't know location yet
final customerLocationProvider = StateProvider<({double lat, double lng})?>((ref) {
  return null;
  // ({double lat, double lng}) is a Dart 'record' — a lightweight data holder
  // Like a mini class with no methods
  // We use it instead of creating a whole LatLng class
});

// This fetches nearby shops based on current location
// FutureProvider handles async operations automatically
// It has three states built in: loading, error, data
final nearbyShopsProvider = FutureProvider<List<Shop>>((ref) async {
  // Watch the location — if location changes, this re-runs automatically
  final location = ref.watch(customerLocationProvider);

  // If we don't have location yet, return empty list
  if (location == null) return [];

  // Get the repository and fetch shops
  final repository = ref.read(shopRepositoryProvider);
  return repository.getNearbyShops(
    latitude: location.lat,
    longitude: location.lng,
  );
});