import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../models/cart_item.dart';
import '../../cart/providers/cart_provider.dart';

class AddToCartSheet extends ConsumerStatefulWidget {
  final Product product;
  final String shopId;

  const AddToCartSheet({
    super.key,
    required this.product,
    required this.shopId,
  });

  @override
  ConsumerState<AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends ConsumerState<AddToCartSheet> {
  // 'late' means we'll initialize this in initState, not here
  // We can't initialize it here because widget.product isn't
  // available yet at declaration time
  late ProductVariant _selectedVariant;

  // How many units the customer wants to add — starts at 1
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Default to first variant when sheet opens
    _selectedVariant = widget.product.variants.first;
  }

  @override
  Widget build(BuildContext context) {
    // MediaQuery gives us device screen information
    // We use it to make sheet height relative to screen size
    // so it looks good on all phone sizes
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      // Sheet takes max 60% of screen height
      constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
      decoration: const BoxDecoration(
        color: Colors.white,
        // Only round top corners — bottom touches edge of screen
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        // mainAxisSize.min — column only takes as much space
        // as its children need, not the full sheet height
        mainAxisSize: MainAxisSize.min,
        children: [

          // Handle bar — visual cue that sheet can be dragged down
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Flexible allows content to scroll if it overflows
          // the available space inside the sheet
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Product name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  // Brand — only show if exists
                  if (widget.product.brandName != null)
                    Text(
                      widget.product.brandName!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Variant selector — only show if product has
                  // multiple variants (e.g. 100g, 500g, 1kg)
                  // The '...' spread adds both widgets to the column
                  // if condition is true, adds nothing if false
                  if (widget.product.variants.length > 1) ...[
                    const Text(
                      'Select Size',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Horizontal scrolling row of variant chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.product.variants.map((variant) {
                          final isSelected = variant.id == _selectedVariant.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                '${variant.variantName} — ₹${variant.price.toStringAsFixed(0)}',
                              ),
                              selected: isSelected,
                              selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                              onSelected: (_) {
                                setState(() => _selectedVariant = variant);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Quantity selector
                  Row(
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      // Minus button
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppTheme.primary,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Plus button
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppTheme.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final item = CartItem(
                          variantId: _selectedVariant.id,
                          shopId: widget.shopId,
                          productName: widget.product.name,
                          variantName: _selectedVariant.variantName,
                          price: _selectedVariant.price,
                          quantity: _quantity,
                          imageUrl: widget.product.imageUrl,
                        );
                        ref.read(cartProvider.notifier).addItem(item);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Add to Cart — ₹${(_selectedVariant.price * _quantity).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}