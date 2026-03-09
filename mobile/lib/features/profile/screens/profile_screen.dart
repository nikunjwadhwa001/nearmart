import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user.dart';
import '../../auth/providers/auth_provider.dart' as auth;
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user profile data from database
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.surface,
      ),
      body: userProfileAsync.when(
        data: (userProfile) => _buildProfileContent(context, ref, userProfile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error loading profile: $error'),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, User? userProfile) {
    return ListView(
      // ListView is like a Column but scrollable
      // Perfect for settings/profile screens
      children: [
        const SizedBox(height: 24),

        // Profile header
        Center(
          child: Column(
            children: [
              // Avatar circle
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  // Show first letter of name as avatar
                  userProfile?.fullName.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Show full name
              Text(
                userProfile?.fullName ?? 'User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Show email
              if (userProfile?.email != null)
                Text(
                  userProfile!.email!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              // Customer badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  userProfile?.role.toUpperCase() ?? 'CUSTOMER',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Settings section
        const _SectionTitle(title: 'Account'),

        _ProfileTile(
          icon: Icons.logout_rounded,
          label: 'Log Out',
          color: AppTheme.textPrimary,
          onTap: () => _showLogoutDialog(context, ref),
        ),

        const SizedBox(height: 8),

        // Danger zone
        const _SectionTitle(title: 'Danger Zone'),

        _ProfileTile(
          icon: Icons.delete_forever_rounded,
          label: 'Delete My Account',
          color: AppTheme.error,
          onTap: () => _showDeleteDialog(context, ref),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // LOGOUT DIALOG
  // Always confirm before logging out — prevents accidental taps
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      // barrierDismissible — can user tap outside to close?
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Log Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to log out?',
            ),
            const SizedBox(height: 24),
            // Cancel button — full width, outlined
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 12),
            // Confirm logout button — full width, filled
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                onPressed: () async {
                  // Close dialog first
                  Navigator.pop(dialogContext);
                  // Call logout in auth provider
                  await ref.read(auth.authNotifierProvider.notifier).signOut();
                  // Navigate to login — remove all previous routes
                  // 'go' replaces current route
                  // We use go here because after logout there's
                  // no "back" — user must log in again
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DELETE ACCOUNT DIALOG
  // Extra confirmation — this is irreversible
  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false, // Must explicitly choose — no accidental dismiss
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.error, size: 24),
             SizedBox(width: 8),
             Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will permanently delete your account and all your data including orders and addresses.\n\nThis cannot be undone.',
            ),
            const SizedBox(height: 24),
            // Cancel button — full width, outlined
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 12),
            // Delete button — full width, filled with error color
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  // Show loading dialog
                  _showLoadingDialog(context);
                  await ref
                      .read(auth.authNotifierProvider.notifier)
                      .deleteAccount(context);
                },
                child: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Listen for errors after dialog is shown
    ref.listen<auth.AuthState>(auth.authNotifierProvider, (previous, next) {
      if (next.error != null && !next.isLoading) {
        // Close loading dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });
  }

  // Loading dialog for delete operation
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Deleting your account...'),
          ],
        ),
      ),
    );
  }
}

// Reusable section title widget
// Private class — only used inside this file
// The underscore _ makes it private to this file
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Reusable profile tile — like a settings row
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  // VoidCallback is a Dart type for functions that take no
  // arguments and return nothing — () => void in TypeScript

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        // ListTile — Flutter's built in row widget for settings/menus
        // Has icon, title, subtitle, trailing all built in
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}