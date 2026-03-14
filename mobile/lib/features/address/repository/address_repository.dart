import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/address.dart';
import '../../../core/cache/query_cache.dart';

class AddressRepository {
  final _supabase = Supabase.instance.client;
  // Shared cache utility reused across repository calls.
  final _cache = QueryCache.instance;

  /// Fetch all addresses for the current user.
  Future<List<Address>> getMyAddresses() async {
    final userId = _supabase.auth.currentUser!.id;
    // Addresses are user-specific and relatively static.
    final key = 'addresses:v1:user:$userId';

    final response = await _cache.getOrFetch<List<dynamic>>(
      key: key,
      // Long TTL is fine because writes explicitly invalidate this key.
      ttl: const Duration(hours: 24),
      fetcher: () async {
        final result = await _supabase
            .from('addresses')
            .select()
            .eq('user_id', userId)
            .order('is_default', ascending: false);
        return (result as List).cast<dynamic>();
      },
      decode: (raw) => (raw as List).cast<dynamic>(),
      encode: (value) => value,
    );

    return response
        .map((json) => Address.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  /// Add a new address. Returns the created address.
  Future<Address> addAddress({
    required String addressLine,
    String label = 'Home',
    String? city,
    String? pincode,
    double? latitude,
    double? longitude,
    String? phone,
    bool isDefault = false,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // If this is default, unset existing defaults first
    if (isDefault) {
      await _supabase
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', userId)
          .eq('is_default', true);
    }

    final response = await _supabase
        .from('addresses')
        .insert({
          'user_id': userId,
          'label': label,
          'address_line': addressLine,
          'city': city,
          'pincode': pincode,
          'latitude': latitude,
          'longitude': longitude,
          'phone': phone,
          'is_default': isDefault,
        })
        .select()
        .single();

      // Address list changed; force next read to refetch fresh data.
    await _cache.invalidate('addresses:v1:user:$userId');

    return Address.fromJson(response);
  }

  /// Delete an address by ID.
  Future<void> deleteAddress(String addressId) async {
    final userId = _supabase.auth.currentUser!.id;

    final deletedAddress = await _supabase
        .from('addresses')
        .delete()
        .eq('id', addressId)
        .eq('user_id', userId)
        .select('id')
        .maybeSingle();

    if (deletedAddress == null) {
      throw StateError('Address not found for the current user.');
    }

    // Address list changed; force next read to refetch fresh data.
    await _cache.invalidate('addresses:v1:user:$userId');
  }
}
