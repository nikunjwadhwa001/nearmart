import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/app_async_state.dart';
import '../../../core/widgets/order_status_widgets.dart';
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
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => Center(
          child: AppErrorState(
            title: 'Unable to load order details',
            message: 'Please check your connection and try again',
            action: AppRetryButton(
              onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
              label: 'Retry',
              icon: Icons.refresh,
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
                formatPrice(order.totalAmount),
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
    return OrderStatusBanner(
      status: order.status,
      label: order.statusLabel,
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
            formatPrice(item.totalPrice),
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
