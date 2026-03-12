import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/shop.dart';
import '../../../core/cache/query_cache.dart';

// Repository pattern — one class responsible for all shop database operations
// The rest of the app never directly calls Supabase
// They just call ShopRepository methods
class ShopRepository {
  // Get the Supabase client
  // This is our connection to the database
  final _supabase = Supabase.instance.client;
  // Shared cache utility reused across repository calls.
  final _cache = QueryCache.instance;

  // Fetch approved shops near a location
  // latitude, longitude — customer's current position
  // radiusKm — how far to search (default 5km)
  Future<List<Shop>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final userId = _supabase.auth.currentUser?.id ?? 'anon';
    // Rounded lat/lng prevent generating a new key for tiny GPS jitter.
    // user is included to avoid cross-account cache bleed.
    final key =
        'nearby_shops:v1:user:$userId:lat:${latitude.toStringAsFixed(3)}:lng:${longitude.toStringAsFixed(3)}:r:${radiusKm.toStringAsFixed(1)}';

    final response = await _cache.getOrFetch<List<dynamic>>(
      key: key,
      // Nearby shops can tolerate short staleness while user navigates.
      ttl: const Duration(minutes: 5),
      fetcher: () async {
        final result = await _supabase.rpc(
          'get_nearby_shops',
          params: {
            'lat': latitude,
            'lng': longitude,
            'radius_km': radiusKm,
          },
        );
        return (result as List).cast<dynamic>();
      },
      decode: (raw) => (raw as List).cast<dynamic>(),
      encode: (value) => value,
    );

    // response is a List of Maps from the database
    // We convert each Map into a Shop object using Shop.fromJson
    // .map() transforms each item in the list
    // .toList() converts the result back to a List
    return response
        .map((json) => Shop.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }
}