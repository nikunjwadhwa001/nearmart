import 'package:flutter/material.dart';
import '../utils/order_status_style.dart';

class OrderStatusChip extends StatelessWidget {
  final String status;
  final String label;

  const OrderStatusChip({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final style = getOrderStatusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.foregroundColor,
        ),
      ),
    );
  }
}

class OrderStatusBanner extends StatelessWidget {
  final String status;
  final String label;

  const OrderStatusBanner({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final style = getOrderStatusStyle(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(style.icon, color: style.foregroundColor, size: 28),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: style.foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
