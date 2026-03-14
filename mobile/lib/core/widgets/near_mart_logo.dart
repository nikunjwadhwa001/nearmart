import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NearMartLogoMark extends StatelessWidget {
  final double iconSize;
  final Color iconColor;

  const NearMartLogoMark({
    super.key,
    this.iconSize = 50,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.shopping_bag_rounded,
      color: iconColor,
      size: iconSize,
    );
  }
}

class NearMartLogoTile extends StatelessWidget {
  final double size;
  final double iconSize;

  const NearMartLogoTile({
    super.key,
    this.size = 100,
    this.iconSize = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: NearMartLogoMark(
        iconSize: iconSize,
        iconColor: Colors.white,
      ),
    );
  }
}
