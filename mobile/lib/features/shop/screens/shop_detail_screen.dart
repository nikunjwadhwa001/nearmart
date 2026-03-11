import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/shop.dart';
import '../providers/shop_detail_provider.dart';
import '../widgets/product_card.dart';
import '../../cart/providers/cart_provider.dart';

class ShopDetailScreen extends ConsumerWidget {
  // Shop object passed from home screen when user taps a shop card
  final Shop shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch inventory for THIS specific shop using .family
    // Every time shopId changes, this automatically re-fetches
    final inventoryAsync = ref.watch(shopInventoryProvider(shop.id));

    // Watch cart count — rebuilds floating button when cart changes
    final cartCount = ref.watch(cartItemCountProvider);

    // Watch cart total — rebuilds floating button label when total changes
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        // CustomScrollView lets us mix SliverAppBar + SliverList
        // in one smooth scrollable area
        slivers: [

          // SliverAppBar — collapses as user scrolls down
          // expandedHeight — how tall it is when fully expanded
          // pinned: true — stays visible as a small bar when collapsed
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              // Title shows when header is collapsed
              title: Text(
                shop.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // Background shows when header is expanded
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.store_rounded,
                    size: 64,
                    // withOpacity — makes icon semi-transparent
                    // so it feels like a watermark, not a focal point
                    color: Colors.white.withValues(alpha : 0.3),
                  ),
                ),
              ),
            ),
          ),

          // Shop info strip — open status + distance + phone
          SliverToBoxAdapter(
            // SliverToBoxAdapter wraps a normal widget so it can
            // live inside a CustomScrollView alongside Slivers
            child: Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Open/Closed badge with colored background
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: shop.isOpen
                          ? Colors.green.withValues(alpha:0.1)
                          : Colors.red.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: shop.isOpen ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shop.isOpen ? 'Open Now' : 'Closed',
                          style: TextStyle(
                            color: shop.isOpen ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Distance from customer
                  if (shop.distance != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${shop.distance!.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                  // Spacer pushes phone button to the right
                  const Spacer(),

                  if (shop.phone != null)
                    IconButton(
                      icon: const Icon(Icons.phone_outlined),
                      color: AppTheme.primary,
                      onPressed: () {
                        // Phone call — will add later
                      },
                    ),
                ],
              ),
            ),
          ),

          // Product catalog — handles all 3 async states
          inventoryAsync.when(
            // LOADING — simple centered spinner
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

            // ERROR — show message with error details
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Could not load products: $e'),
                ),
              ),
            ),

            // DATA — show products grouped by category
            data: (inventory) {
              if (inventory.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Text('No products available yet'),
                    ),
                  ),
                );
              }

              // Get list of category names to iterate over
              final categories = inventory.keys.toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Each index is one category section
                    final category = categories[index];
                    final products = inventory[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category name header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            category,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                        ),

                        // All products under this category
                        // ...spread operator expands the list inline
                        // without it we'd have a List inside a Column
                        // which Flutter doesn't allow
                        ...products.map(
                          (product) => ProductCard(
                            product: product,
                            shopId: shop.id,
                          ),
                        ),
                      ],
                    );
                  },
                  // How many sections — one per category
                  childCount: categories.length,
                ),
              );
            },
          ),

          // Bottom padding so last product isn't hidden
          // behind the floating cart button
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Floating cart button — only visible when cart has items
      // cartCount > 0 means: show button only after first item added
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              // context.push adds cart on top — back button returns here
              onPressed: () => context.push('/cart'),
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
              ),
              // Shows item count and running total
              // toStringAsFixed(0) — no decimal places for rupees
              label: Text(
                '$cartCount items · ₹${cartTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null, // null means no floating button shown
    );
  }
}