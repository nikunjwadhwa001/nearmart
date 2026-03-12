import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../models/cart_item.dart';
import '../../cart/providers/cart_provider.dart';

class VariantTile extends ConsumerWidget {
  final ProductVariant variant;
  final String shopId;
  final String shopName;
  final String productName;
  final String? brandName;
  final String? imageUrl;

  const VariantTile({
    super.key,
    required this.variant,
    required this.shopId,
    required this.shopName,
    required this.productName,
    this.brandName,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find this variant's quantity in cart (0 if not in cart)
    final cartItems = ref.watch(cartProvider);
    final inCart = cartItems.where((i) => i.variantId == variant.id);
    final qty = inCart.isEmpty ? 0 : inCart.first.quantity;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Variant info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.variantName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (variant.unit != null)
                  Text(
                    variant.unit!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Price
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              '₹${variant.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),

          // Add button or quantity controls
          if (qty == 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                ref.read(cartProvider.notifier).addItem(
                  CartItem(
                    variantId: variant.id,
                    shopId: shopId,
                    shopName: shopName,
                    productName: productName,
                    brandName: brandName ?? '',
                    variantName: variant.variantName,
                    price: variant.price,
                    quantity: 1,
                    imageUrl: imageUrl,
                  ),
                );
              },
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Minus
                  InkWell(
                    onTap: () {
                      ref.read(cartProvider.notifier).updateQuantity(
                        variant.id,
                        qty - 1,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  // Count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$qty',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  // Plus
                  InkWell(
                    onTap: () {
                      ref.read(cartProvider.notifier).updateQuantity(
                        variant.id,
                        qty + 1,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
