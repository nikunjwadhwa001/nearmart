import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/address.dart';
import '../repository/address_repository.dart';

final addressRepositoryProvider = Provider((ref) => AddressRepository());

/// Fetch all addresses for the current user.
final myAddressesProvider = FutureProvider<List<Address>>((ref) {
  final repo = ref.read(addressRepositoryProvider);
  return repo.getMyAddresses();
});
