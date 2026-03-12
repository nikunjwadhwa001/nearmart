import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 28,
                    color: AppTheme.error.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load order details',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please check your connection and try again',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (order) => _buildContent(context, order),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Order order) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status banner
        _StatusBanner(order: order),

        const SizedBox(height: 16),

        // Shop info
        _SectionCard(
          title: 'Shop',
          child: Text(
            order.shopName ?? 'Shop',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Delivery address
        if (order.deliveryAddress != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SectionCard(
              title: 'Delivery Address',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.deliveryAddress!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (order.deliveryPhone != null) ...[                    const SizedBox(height: 4),
                    Text(
                      order.deliveryPhone!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // Items
        _SectionCard(
          title: 'Items',
          child: Column(
            children: [
              if (order.items != null)
                ...order.items!.map((item) => _ItemRow(item: item)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Order total
        _SectionCard(
          title: 'Payment',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Notes (if any)
        if (order.notes != null && order.notes!.isNotEmpty)
          _SectionCard(
            title: 'Notes',
            child: Text(
              order.notes!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Timeline
        _SectionCard(
          title: 'Timeline',
          child: Column(
            children: [
              _TimelineRow(
                label: 'Placed',
                time: order.placedAt,
                isActive: true,
              ),
              if (order.confirmedAt != null)
                _TimelineRow(
                  label: 'Confirmed',
                  time: order.confirmedAt!,
                  isActive: true,
                ),
              if (order.deliveredAt != null)
                _TimelineRow(
                  label: 'Delivered',
                  time: order.deliveredAt!,
                  isActive: true,
                ),
              if (order.cancelledAt != null)
                _TimelineRow(
                  label: 'Cancelled',
                  time: order.cancelledAt!,
                  isActive: true,
                  isError: true,
                ),
            ],
          ),
        ),

        if (order.cancellationReason != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Cancellation Reason',
            child: Text(
              order.cancellationReason!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.error,
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Order order;
  const _StatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (order.status) {
      case 'placed':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        icon = Icons.receipt_outlined;
        break;
      case 'confirmed':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        icon = Icons.thumb_up_outlined;
        break;
      case 'preparing':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        icon = Icons.kitchen_outlined;
        break;
      case 'out_for_delivery':
        bg = AppTheme.primary.withValues(alpha: 0.1);
        fg = AppTheme.primary;
        icon = Icons.delivery_dining;
        break;
      case 'delivered':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(width: 12),
          Text(
            order.statusLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Quantity badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + variant
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (item.variantName != null)
                  Text(
                    item.variantName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // Price
          Text(
            '₹${item.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool isActive;
  final bool isError;

  const _TimelineRow({
    required this.label,
    required this.time,
    this.isActive = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppTheme.error : (isActive ? AppTheme.primary : AppTheme.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Text(
            _formatTime(time),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final ist = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final hour12 = ist.hour == 0 ? 12 : (ist.hour > 12 ? ist.hour - 12 : ist.hour);
    final amPm = ist.hour >= 12 ? 'PM' : 'AM';
    final minute = ist.minute.toString().padLeft(2, '0');

    return '${ist.day} ${months[ist.month - 1]}, ${ist.year} • $hour12:$minute $amPm ';
  }
}
