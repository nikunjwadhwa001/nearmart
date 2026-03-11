import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/cart_item.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the full cart list — rebuilds when any item changes
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('My Cart'),
        // Shows how many unique items are in cart
        // e.g. "My Cart (3 items)"
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),

      body: cartItems.isEmpty
          // EMPTY STATE — cart has nothing in it
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add items from a nearby store',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    // Go back to home to browse shops
                    onPressed: () => context.go('/home'),
                    child: const Text('Browse Stores'),
                  ),
                ],
              ),
            )

          // CART HAS ITEMS — show list + order summary
          : Column(
              children: [
                // Cart items list — scrollable
                Expanded(
                  // Expanded fills all available space above
                  // the order summary at the bottom
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    // itemCount — how many items to render
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return CartItemCard(item: item);
                    },
                  ),
                ),

                // Order summary — fixed at bottom
                _OrderSummary(
                  total: cartTotal,
                ),
              ],
            ),
    );
  }
}

// Individual cart item row
class CartItemCard extends ConsumerWidget {
  final CartItem item;
  const CartItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Product icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Product name and variant
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  item.variantName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                // Price per unit
                Text(
                  '₹${item.price.toStringAsFixed(0)} each',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Right side — quantity controls + total + remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Line total — price × quantity
              Text(
                '₹${item.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              // Quantity controls row
              Row(
                children: [
                  // Minus — removes item if quantity reaches 0
                  _SmallButton(
                    icon: item.quantity == 1
                        ? Icons.delete_outline  // show delete icon at qty 1
                        : Icons.remove,
                    color: item.quantity == 1
                        ? AppTheme.error
                        : AppTheme.textPrimary,
                    onTap: () {
                      if (item.quantity == 1) {
                        // Remove item completely
                        ref
                            .read(cartProvider.notifier)
                            .removeItem(item.variantId);
                      } else {
                        // Decrease quantity by 1
                        ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.variantId, item.quantity - 1);
                      }
                    },
                  ),

                  // Current quantity
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  // Plus — increase quantity
                  _SmallButton(
                    icon: Icons.add,
                    color: AppTheme.primary,
                    onTap: () {
                      ref
                          .read(cartProvider.notifier)
                          .updateQuantity(item.variantId, item.quantity + 1);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Order summary card at bottom of screen
class _OrderSummary extends ConsumerWidget {
  final double total;

  const _OrderSummary({
    required this.total,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Customer only sees what they pay — clean and simple
          _SummaryRow(
            label: 'Total',
            value: '₹${total.toStringAsFixed(0)}',
            isBold: true,
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              // Order placement logic — coming next
            },
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }
}

// Reusable row for summary — label on left, value on right
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Small circular button used for quantity controls
class _SmallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}