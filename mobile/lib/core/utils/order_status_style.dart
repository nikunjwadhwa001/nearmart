import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OrderStatusStyle {
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  const OrderStatusStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });
}

OrderStatusStyle getOrderStatusStyle(String status) {
  switch (status) {
    case 'placed':
      return OrderStatusStyle(
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade700,
        icon: Icons.receipt_outlined,
      );
    case 'confirmed':
      return OrderStatusStyle(
        backgroundColor: Colors.orange.shade50,
        foregroundColor: Colors.orange.shade700,
        icon: Icons.thumb_up_outlined,
      );
    case 'preparing':
      return OrderStatusStyle(
        backgroundColor: Colors.orange.shade50,
        foregroundColor: Colors.orange.shade700,
        icon: Icons.kitchen_outlined,
      );
    case 'out_for_delivery':
      return OrderStatusStyle(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        foregroundColor: AppTheme.primary,
        icon: Icons.delivery_dining,
      );
    case 'delivered':
      return OrderStatusStyle(
        backgroundColor: Colors.green.shade50,
        foregroundColor: Colors.green.shade700,
        icon: Icons.check_circle_outline,
      );
    case 'cancelled':
      return OrderStatusStyle(
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
        icon: Icons.cancel_outlined,
      );
    default:
      return OrderStatusStyle(
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.grey.shade700,
        icon: Icons.info_outline,
      );
  }
}
