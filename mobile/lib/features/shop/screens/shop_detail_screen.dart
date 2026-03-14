import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/app_async_state.dart';
import '../../../models/shop.dart';
import '../providers/shop_detail_provider.dart';
import '../widgets/variant_tile.dart';
import '../../cart/providers/cart_provider.dart';

class ShopDetailScreen extends ConsumerStatefulWidget {
  final Shop shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  // Track which products are expanded — all start expanded
  final Set<String> _expandedProducts = {};
  bool _initialized = false;

  Future<void> _callShop(String? phone) async {
    final rawPhone = phone?.trim() ?? '';
    if (rawPhone.isEmpty) {
      if (!mounted) return;
      showAppInfoSnackBar(context, 'Shop phone number is not available.');
      return;
    }

    final normalizedPhone = _normalizePhone(rawPhone);
    if (normalizedPhone.isEmpty) {
      if (!mounted) return;
      showAppInfoSnackBar(context, 'Shop phone number is not available.');
      return;
    }

    final dialerUris = <Uri>[
      Uri(scheme: 'tel', path: normalizedPhone),
      Uri.parse('tel://$normalizedPhone'),
      if (defaultTargetPlatform == TargetPlatform.iOS)
        Uri.parse('telprompt:$normalizedPhone'),
    ];

    for (final uri in dialerUris) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (launched) return;
      } catch (_) {
        // Try the next URI fallback.
      }
    }

    if (!mounted) return;
    showAppErrorSnackBar(
      context,
      'Unable to open dialer on this device. Please call $rawPhone manually.',
    );
  }

  String _normalizePhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1).replaceAll('+', '');
      return digits.isEmpty ? '' : '+$digits';
    }
    return cleaned.replaceAll('+', '');
  }

  void _initExpanded(Map<String, List<dynamic>> inventory) {
    if (_initialized) return;
    _initialized = true;
    for (final products in inventory.values) {
      for (final product in products) {
        _expandedProducts.add(product.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final ref = this.ref;
    // Watch inventory for THIS specific shop using .family
    // Every time shopId changes, this automatically re-fetches
    final inventoryAsync = ref.watch(shopInventoryProvider(shop.id));

    // Watch cart count — rebuilds floating button when cart changes
    final cartCount = ref.watch(cartItemCountProvider);

    // Watch cart total — rebuilds floating button label when total changes
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate provider to force a refresh
          ref.invalidate(shopInventoryProvider(shop.id));
          // Wait for the new data to load
          await ref.read(shopInventoryProvider(shop.id).future);
        },
        child: CustomScrollView(
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
                        onPressed: () => _callShop(shop.phone),
                      ),
                  ],
                ),
              ),
            ),

            // Product catalog — handles all 3 async states
            inventoryAsync.when(
              // LOADING — simple centered spinner
              loading: () => const SliverToBoxAdapter(
                child: AppLoadingState(padding: EdgeInsets.all(48)),
              ),

              // ERROR — show user-friendly network error
              error: (e, _) => SliverToBoxAdapter(
                child: AppErrorState(
                  title: 'Unable to load products',
                  message: 'Please check your internet connection\nand try again',
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  iconContainerSize: 80,
                  iconSize: 36,
                  titleSize: 16,
                  centerContent: false,
                  action: AppRetryButton(
                    onPressed: () => ref.invalidate(shopInventoryProvider(shop.id)),
                    expand: true,
                  ),
                ),
              ),

              // DATA — show products grouped by category
              data: (inventory) {
                if (inventory.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products available yet',
                      message: 'This shop has not added items to its catalog yet.',
                      padding: EdgeInsets.all(48),
                      iconSize: 56,
                    ),
                  );
                }

                _initExpanded(inventory);

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

                          // Products as sub-headings with expand/collapse
                          ...products.expand(
                            (product) {
                              final isExpanded = _expandedProducts.contains(product.id);
                              return [
                                // Tappable product sub-heading with arrow
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedProducts.remove(product.id);
                                      } else {
                                        _expandedProducts.add(product.id);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons.keyboard_arrow_down_rounded,
                                          color: AppTheme.textSecondary,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Variant rows — only shown when expanded
                                if (isExpanded)
                                  ...product.variants.map(
                                    (variant) => VariantTile(
                                      variant: variant,
                                      shopId: shop.id,
                                      shopName: shop.name,
                                      productName: product.name,
                                      brandName: product.brandName,
                                      imageUrl: product.imageUrl,
                                    ),
                                  ),
                              ];
                            },
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
      ),
      // Floating action button to view cart
      // Only shows if cart is not empty
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.cart),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(
                'View Cart ($cartCount) • ₹${cartTotal.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}