import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/app_async_state.dart';
import '../../../core/widgets/app_dialogs.dart';
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
        loading: () => const AppLoadingState(),
        error: (error, _) => Center(
          child: AppErrorState(
            title: 'Unable to load profile',
            message: 'Please check your connection',
            action: AppRetryButton(
              onPressed: () => ref.invalidate(userProfileProvider),
              label: 'Retry',
              icon: Icons.refresh,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, User? userProfile) {
    final safeDisplayName = _safeDisplayName(userProfile?.fullName);

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
                  _safeAvatarInitial(userProfile?.fullName),
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
                safeDisplayName,
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
          icon: Icons.receipt_long_outlined,
          label: 'My Orders',
          color: AppTheme.textPrimary,
          onTap: () => context.push(AppRoutes.orders),
        ),

        _ProfileTile(
          icon: Icons.edit_outlined,
          label: 'Edit Profile',
          color: AppTheme.textPrimary,
          onTap: () => _showEditNameDialog(context, ref, userProfile),
        ),

        _ProfileTile(
          icon: Icons.logout_rounded,
          label: 'Log Out',
          color: AppTheme.textPrimary,
          onTap: () => _showLogoutDialog(context, ref),
        ),

        const SizedBox(height: 8),

        // Account removal section
        const _SectionTitle(title: 'Account Deletion'),

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

  String _safeAvatarInitial(String? fullName) {
    final safeName = _safeDisplayName(fullName, fallback: '');
    if (safeName.isEmpty) return '?';
    return String.fromCharCode(safeName.runes.first).toUpperCase();
  }

  String _safeDisplayName(String? fullName, {String fallback = 'User'}) {
    final raw = (fullName ?? '').trim();
    if (raw.isEmpty) return fallback;

    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      if (rune < 0xD800 || rune > 0xDFFF) {
        buffer.writeCharCode(rune);
      }
    }

    final cleaned = buffer.toString().trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  // EDIT NAME DIALOG
  // Let user update their full name
  void _showEditNameDialog(BuildContext context, WidgetRef ref, User? userProfile) {
    final nameController = TextEditingController(text: userProfile?.fullName ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: AppFormValidators.requiredFullName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  // Update name in database
                  await ref
                      .read(userUpdateProvider)
                      .updateFullName(nameController.text.trim());
                  
                  // Close dialog
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  
                  // Show success message
                  if (context.mounted) {
                    showAppSuccessSnackBar(context, 'Profile updated successfully');
                  }
                } catch (e) {
                  // Show error
                  if (context.mounted) {
                    showAppErrorSnackBar(
                      context,
                      'Unable to update profile. Please check your connection and try again.',
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // LOGOUT DIALOG
  // Always confirm before logging out — prevents accidental taps
  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showAppConfirmDialog(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmText: 'Log Out',
    );

    if (!shouldLogout) return;

    await ref.read(auth.authNotifierProvider.notifier).signOut();
    if (context.mounted) context.go(AppRoutes.login);
  }

  // DELETE ACCOUNT DIALOG
  // Extra confirmation — this is irreversible
  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showAppConfirmDialog(
      context,
      title: 'Delete Account',
      message:
          'This will permanently delete your account and all your data including '
          'orders and addresses.\n\nThis cannot be undone.',
      confirmText: 'Delete Account',
      confirmColor: AppTheme.error,
      barrierDismissible: false,
      titlePrefix: const Icon(Icons.warning_rounded, color: AppTheme.error, size: 24),
    );

    if (!shouldDelete) return;
    if (!context.mounted) return;

    showAppLoadingDialog(context, message: 'Deleting your account...');
    await ref.read(auth.authNotifierProvider.notifier).deleteAccount(context);

    if (!context.mounted) return;

    final authState = ref.read(auth.authNotifierProvider);
    if (authState.error != null && !authState.isLoading) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      showAppErrorSnackBar(context, authState.error!);
    }
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