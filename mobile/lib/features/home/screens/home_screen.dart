import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/shop_provider.dart';
import '../widgets/shop_card.dart';
import '../widgets/home_header.dart';
import '../../cart/providers/cart_provider.dart';

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
    final cartCount = ref.watch(cartItemCountProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final shopName = ref.watch(cartShopNameProvider);

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

                // ERROR STATE — friendly network/generic error
                error: (error, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            size: 36,
                            color: AppTheme.error.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Unable to load stores',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please check your internet connection\nand try again',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _getLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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

              // Bottom padding so last item isn't hidden behind cart bar
              SliverToBoxAdapter(
                child: SizedBox(height: cartCount > 0 ? 80 : 24),
              ),
            ],
          ),
        ),
      ),
      // Floating cart bar — only visible when cart has items
      bottomNavigationBar: cartCount > 0
          ? GestureDetector(
              onTap: () => context.push('/cart'),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cart icon + item count badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$cartCount',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shop name + item count text
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopName ?? 'Your Cart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$cartCount ${cartCount == 1 ? 'item' : 'items'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total price + arrow
                    Text(
                      '₹${cartTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}