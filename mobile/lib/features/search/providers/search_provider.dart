import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/search_result.dart';
import '../repository/search_repository.dart';
import '../../home/providers/shop_provider.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository();
});

// Debounced search query — updated from the search screen
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// Fetches search results when query changes
final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final location = ref.watch(customerLocationProvider);

  if (query.trim().length < 2 || location == null) return [];

  final repository = ref.read(searchRepositoryProvider);
  return repository.searchProducts(
    query: query.trim(),
    latitude: location.lat,
    longitude: location.lng,
  );
});
