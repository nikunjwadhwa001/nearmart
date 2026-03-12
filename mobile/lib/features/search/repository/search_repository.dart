import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/search_result.dart';
import '../../../core/cache/query_cache.dart';

class SearchRepository {
  final _supabase = Supabase.instance.client;
  // Shared cache utility reused across repository calls.
  final _cache = QueryCache.instance;

  Future<List<SearchResult>> searchProducts({
    required String query,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final userId = _supabase.auth.currentUser?.id ?? 'anon';
    // Normalize query so "Milk" and "milk" reuse the same cache entry.
    final normalizedQuery = query.trim().toLowerCase();
    // Include location + radius so results are only reused in comparable context.
    final key =
        'search_products:v1:user:$userId:q:$normalizedQuery:lat:${latitude.toStringAsFixed(3)}:lng:${longitude.toStringAsFixed(3)}:r:${radiusKm.toStringAsFixed(1)}';

    final response = await _cache.getOrFetch<List<dynamic>>(
      key: key,
      // Search is highly dynamic while typing, so cache window stays very short.
      ttl: const Duration(seconds: 90),
      fetcher: () async {
        final result = await _supabase.rpc(
          'search_products',
          params: {
            'query_text': normalizedQuery,
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

    return response
        .map((json) => SearchResult.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }
}
