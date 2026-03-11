
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth state — what the UI needs to know
class AuthState {
  final bool isLoading;
  final String? error;
  final bool otpSent;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.otpSent = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? otpSent,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpSent: otpSent ?? this.otpSent,
    );
  }
}

// Auth notifier — handles all auth logic
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _supabase = Supabase.instance.client;

  // Step 1 — send OTP to email with user metadata
  Future<void> sendOtp(String email, String fullName) async {
    state = state.copyWith(isLoading: true, error: null, otpSent: false);

    try {
      // Send OTP with user metadata so trigger can create user with proper name
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
        emailRedirectTo: null, // no redirect — forces OTP code instead of magic link
        data: fullName.isNotEmpty ? {
          'full_name': fullName,
          'role': 'customer',
        } : null,
      );
      state = state.copyWith(isLoading: false, otpSent: true);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  // Step 2 — verify OTP and ensure user exists in public.users
  Future<String?> verifyOtp(String email, String otp, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session != null) {
        // User is now logged in — ensure they exist in public.users
        // The trigger may have created them, or they may have been deleted previously
        await _ensureUserInDatabase(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
        );

        state = state.copyWith(isLoading: false);
        return null; // null means success
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid OTP. Please try again.',
        );
        return 'Invalid OTP. Please try again.';
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return e.message;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return 'Something went wrong. Please try again.';
    }
  }

  // Ensure user has a row in public.users with correct name
  Future<void> _ensureUserInDatabase({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    try {
      // Check if user exists in public.users
      final existing = await _supabase
          .from('users')
          .select('id, full_name')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        // User doesn't exist — create them
        // This happens if trigger failed or user was previously deleted
        await _supabase.from('users').insert({
          'id': userId,
          'email': email,
          'full_name': fullName.isNotEmpty ? fullName : 'User',
          'role': 'customer',
          'is_active': true,
        });
        debugPrint('Created user in public.users: $fullName');
      } else if (fullName.isNotEmpty) {
        // User exists — update name if they provided one and current is default
        final currentName = existing['full_name'] as String;
        if (currentName == 'New User' || currentName == 'User' || currentName.isEmpty) {
          await _supabase
              .from('users')
              .update({'full_name': fullName})
              .eq('id', userId);
          debugPrint('Updated user name to: $fullName');
        }
      }
    } catch (e) {
      debugPrint('Error ensuring user in database: $e');
      // Don't fail the login — user can still use the app
    }
  }

  

  // LOGOUT
// Signs out from Supabase — clears local session
// After this, currentSession returns null
// The router redirect detects this and sends user to /login
Future<void> signOut() async {
  await _supabase.auth.signOut();
  state = const AuthState(); // Reset all state
}

// DELETE ACCOUNT
// Calls Supabase Edge Function to properly delete from both:
// - auth.users (requires service role)
// - public.users (triggers CASCADE deletion of related data)
Future<void> deleteAccount(BuildContext context) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Try to call Edge Function to delete account
      // This function has service role permissions to delete from auth.users
      final response = await _supabase.functions.invoke('delete-account');

      if (response.status != 200) {
        throw Exception(response.data['error'] ?? 'Failed to delete account');
      }
    } catch (e) {
      debugPrint('Edge function error: $e');
      
      // Fallback: If Edge Function fails (e.g., user not in public.users),
      // try direct deletion from public.users and sign out
      try {
        await _supabase
            .from('users')
            .delete()
            .eq('id', userId);
      } catch (dbError) {
        debugPrint('Database delete error (user may not exist): $dbError');
        // Continue anyway - user might not be in public.users
      }
    }

    // Sign out locally
    await _supabase.auth.signOut();

    state = state.copyWith(isLoading: false);

    // Close loading dialog and navigate to login
    if (context.mounted) {
      // Pop any open dialogs first
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      context.go('/login');
    }

  } catch (e) {
    // Log the actual error for debugging
    debugPrint('Delete account error: $e');
    
    state = state.copyWith(
      isLoading: false,
      error: 'Could not delete account. Please try again later.',
    );
  }
}

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});