import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user from Supabase auth
    final user = Supabase.instance.client.auth.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        // Only round bottom corners — top is at screen edge
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Top row — greeting and profile icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // Show email before @ symbol as name
                    // user?.email is null-safe — won't crash if null
                    user?.email?.split('@')[0] ?? 'there',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                ],
              ),
              // Profile avatar
              CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: const  Icon(
                  Icons.person_outline,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search bar — not functional yet, we'll add it later
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                 SizedBox(width: 8),
                Text(
                  'Search groceries...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Helper method — returns greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    // hour is 0-23
    if (hour < 12) return 'Good morning 🌅';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }
}