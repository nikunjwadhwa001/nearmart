import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/shop_provider.dart';
import '../widgets/shop_card.dart';
import '../widgets/home_header.dart';

// ConsumerStatefulWidget because we need:
// - State (StatefulWidget) for location loading on init
// - Riverpod access (Consumer) for providers
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  void initState() {
    super.initState();
    // initState runs ONCE when screen first appears
    // Perfect place to start location fetching
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      // Step 1 — Check if location services are enabled on the device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      // Step 2 — Check if we have permission
      LocationPermission permission = await Geolocator.checkPermission();

      // Step 3 — If not determined yet, ask the user
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      // Step 4 — Get actual position
      // accuracy: low uses cell towers — fast and battery friendly
      // accuracy: high uses GPS — slower but precise
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Step 5 — Update the provider with location
      // This triggers nearbyShopsProvider to fetch shops automatically
      ref.read(customerLocationProvider.notifier).state = (
        lat: position.latitude,
        lng: position.longitude,
      );

    } catch (e) {
      // Location failed — show mock location for development
      // Chandigarh coordinates so you can test with real shops later
      ref.read(customerLocationProvider.notifier).state = (
        lat: 30.7333,
        lng: 76.7794,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch nearby shops — automatically shows loading/error/data
    final shopsAsync = ref.watch(nearbyShopsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          // Pull down to refresh — calls _getLocation again
          onRefresh: () async => _getLocation(),
          color: AppTheme.primary,
          child: CustomScrollView(
            // CustomScrollView lets you mix different scroll behaviors
            // SliverList, SliverGrid, SliverAppBar all work together
            slivers: [

              // Header with greeting and search bar
              const SliverToBoxAdapter(
                child: HomeHeader(),
              ),

              // Section title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nearby Stores',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      // Shows how many shops found
                      shopsAsync.maybeWhen(
                        data: (shops) => Text(
                          '${shops.length} found',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        orElse: () => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),

              // Shop list — handles all three states
              shopsAsync.when(

                // LOADING STATE — show shimmer placeholders
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const ShopCardSkeleton(),
                    childCount: 4, // Show 4 placeholder cards
                  ),
                ),

                // ERROR STATE — show error message
                error: (error, stack) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppTheme.error),
                          const SizedBox(height: 16),
                          const Text(
                            'Could not load nearby shops',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _getLocation,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // DATA STATE — show actual shops
                data: (shops) {
                  // No shops found — customer friendly message
                  if (shops.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.store_outlined,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No stores nearby',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'We haven\'t launched in your area yet.\nCheck back soon!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Show shop cards
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ShopCard(shop: shops[index]),
                      childCount: shops.length,
                    ),
                  );
                },
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}