import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/shop.dart';

// Repository pattern — one class responsible for all shop database operations
// The rest of the app never directly calls Supabase
// They just call ShopRepository methods
class ShopRepository {
  // Get the Supabase client
  // This is our connection to the database
  final _supabase = Supabase.instance.client;

  // Fetch approved shops near a location
  // latitude, longitude — customer's current position
  // radiusKm — how far to search (default 5km)
  Future<List<Shop>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    // This is a PostgreSQL function that calculates distance
    // using the Haversine formula (great-circle distance)
    // We call it as a Supabase RPC (Remote Procedure Call)
    final response = await _supabase.rpc(
      'get_nearby_shops',
      params: {
        'lat': latitude,
        'lng': longitude,
        'radius_km': radiusKm,
      },
    );

    // response is a List of Maps from the database
    // We convert each Map into a Shop object using Shop.fromJson
    // .map() transforms each item in the list
    // .toList() converts the result back to a List
    return (response as List)
        .map((json) => Shop.fromJson(json))
        .toList();
  }
}