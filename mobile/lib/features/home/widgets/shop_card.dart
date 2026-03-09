import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/shop.dart';

// ShopCard — displays one shop in the list
// Takes a Shop object as input
class ShopCard extends StatelessWidget {
  final Shop shop;

  // Constructor — requires a shop to display
  const ShopCard({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // InkWell adds ripple effect on tap
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // context.push adds shop detail on top of home screen
            // back button will return customer to home
            // state.extra passes the full Shop object to the detail screen
            // so we don't need to fetch it again
            context.push('/shop/${shop.id}', extra: shop);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Shop logo
                _buildLogo(),
                const SizedBox(width: 12),

                // Shop info
                Expanded(
                  // Expanded fills remaining space
                  // Without this, text might overflow
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop name
                      Text(
                        shop.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        // Truncate with ... if too long
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Description
                      if (shop.description != null)
                        Text(
                          shop.description!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 8),

                      // Distance and open status row
                      Row(
                        children: [
                          // Distance badge
                          if (shop.distance != null)
                            _buildBadge(
                              icon: Icons.location_on_outlined,
                              label: '${shop.distance!.toStringAsFixed(1)} km',
                              color: AppTheme.primary,
                            ),
                          const SizedBox(width: 8),

                          // Open/Closed badge
                          _buildBadge(
                            icon: shop.isOpen
                                ? Icons.circle
                                : Icons.circle_outlined,
                            label: shop.isOpen ? 'Open' : 'Closed',
                            color: shop.isOpen ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow icon
               const  Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper — builds the shop logo or a fallback icon
  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: shop.logoUrl != null
          // CachedNetworkImage — downloads and CACHES the image
          // Next time the same image loads instantly from cache
          ? CachedNetworkImage(
              imageUrl: shop.logoUrl!,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Show spinner while loading
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              // Show icon if image fails
              errorWidget: (context, url, error) => const Icon(
                Icons.store_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            )
          // No logo — show store icon
          : const Icon(
              Icons.store_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
    );
  }

  // Helper — builds a small badge with icon and label
  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Only take up needed space
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// SKELETON — shown while shops are loading
// Uses shimmer effect (grey animated placeholder)
class ShopCardSkeleton extends StatelessWidget {
  const ShopCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      // Shimmer wraps everything and makes it animate
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,   // Light grey
        highlightColor: Colors.grey.shade50, // Almost white — the shimmer flash
        child: Row(
          children: [
            // Logo placeholder
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Each Container is a "fake text line"
                  Container(height: 16, width: 140, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 80, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}