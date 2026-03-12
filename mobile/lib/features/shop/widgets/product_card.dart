import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import 'add_to_cart_sheet.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final String shopId;
  final String shopName;

  const ProductCard({
    super.key,
    required this.product,
    required this.shopId,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product icon placeholder
            // We'll replace with real image when products have images
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            // Product info — Expanded fills remaining horizontal space
            // without it, text would overflow outside the card
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  // Brand name — only show if it exists
                  if (product.brandName != null)
                    Text(
                      product.brandName!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                  const SizedBox(height: 4),

                  // Price — show "from ₹X" if multiple variants
                  // because each variant has a different price
                  Text(
                    product.variants.length > 1
                        ? 'from ₹${product.variants.first.price.toStringAsFixed(0)}'
                        : '₹${product.variants.first.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Add button — opens bottom sheet on tap
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                // minimumSize controls button dimensions
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // showModalBottomSheet — slides a sheet up from bottom
                // isScrollControlled: true — allows sheet to be taller
                // than default 50% screen height limit
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  // transparent so our Container's borderRadius shows
                  backgroundColor: Colors.transparent,
                  builder: (sheetContext) => AddToCartSheet(
                    product: product,
                    shopId: shopId,
                    shopName: shopName,
                  ),
                );
              },
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}