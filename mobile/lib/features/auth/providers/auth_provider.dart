
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/cache/query_cache.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';

class _ParsedAuthError {
  final String code;
  final String message;

  const _ParsedAuthError({
    required this.code,
    required this.message,
  });
}

_ParsedAuthError _parseAuthError(AuthException e) {
  final raw = e.message.trim();

  if (raw.startsWith('{') && raw.endsWith('}')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final code = (decoded['code'] as String? ?? '').toLowerCase();
        final message = (decoded['message'] as String?)?.trim() ?? raw;
        return _ParsedAuthError(code: code, message: message);
      }
    } catch (_) {
      // Fall through and use the original message.
    }
  }

  return _ParsedAuthError(code: '', message: raw);
}

String _friendlySendOtpError(AuthException e) {
  final parsed = _parseAuthError(e);
  final msg = parsed.message.toLowerCase();
  final code = parsed.code;

  if (msg.contains('invalid email')) {
    return 'Please enter a valid email address.';
  }

  if (code.contains('rate') || msg.contains('rate limit')) {
    return 'Too many OTP requests. Please wait a moment and try again.';
  }

  if (code == 'unexpected_failure' || msg.contains('error sending magic link email')) {
    return 'Unable to send OTP right now. Please try again in a few minutes.';
  }

  if (msg.contains('network') || msg.contains('socket') || msg.contains('lookup')) {
    return 'Network issue. Please check your internet connection and try again.';
  }

  return 'Unable to send OTP right now. Please try again.';
}

String _friendlyVerifyOtpError(AuthException e) {
  final parsed = _parseAuthError(e);
  final msg = parsed.message.toLowerCase();
  final code = parsed.code;

  if (msg.contains('expired')) {
    return 'This OTP has expired. Please request a new one.';
  }

  if (msg.contains('invalid') || msg.contains('token')) {
    return 'Invalid OTP. Please try again.';
  }

  if (code.contains('rate') || msg.contains('rate limit')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }

  if (msg.contains('network') || msg.contains('socket') || msg.contains('lookup')) {
    return 'Network issue. Please check your internet connection and try again.';
  }

  return 'Unable to verify OTP. Please try again.';
}

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
      // Send OTP with user metadata for later use in _ensureUserInDatabase
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
      state = state.copyWith(
        isLoading: false,
        error: _friendlySendOtpError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppMessages.genericTryAgain,
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
        // User is now logged in — create/update their public.users row
        // This is the ONLY place users get created (no database trigger)
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
          error: AppMessages.invalidOtp,
        );
        return AppMessages.invalidOtp;
      }
    } on AuthException catch (e) {
      final friendlyError = _friendlyVerifyOtpError(e);
      state = state.copyWith(isLoading: false, error: friendlyError);
      return friendlyError;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppMessages.genericTryAgain,
      );
      return AppMessages.genericTryAgain;
    }
  }

  // Create or update user in public.users after verified login
  // This runs ONLY after successful OTP verification — no ghost users
  Future<void> _ensureUserInDatabase({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    final normalizedFullName = fullName.trim();

    try {
      // Check if user already exists (returning user)
      final existing = await _supabase
          .from('users')
          .select('id, full_name')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        // New verified user — create their profile
        await _supabase.from('users').insert({
          'id': userId,
          'email': email,
          'full_name': normalizedFullName.isNotEmpty ? normalizedFullName : 'User',
          'role': 'customer',
          'is_active': true,
        });
        debugPrint('Created user in public.users: $normalizedFullName');
      } else if (normalizedFullName.isNotEmpty) {
        // Returning user — sync name from login input when it changed.
        final currentName = (existing['full_name'] ?? '').toString().trim();
        if (currentName != normalizedFullName) {
          await _supabase
              .from('users')
              .update({'full_name': normalizedFullName})
              .eq('id', userId);

          // Keep auth metadata aligned with app profile name.
          await _supabase.auth.updateUser(
            UserAttributes(data: {'full_name': normalizedFullName}),
          );
          debugPrint('Updated user name to: $normalizedFullName');
        }
      }
    } catch (e) {
      debugPrint('Error ensuring user in database: $e');
      // Fallback for returning users: try direct name sync even if earlier checks failed.
      if (normalizedFullName.isNotEmpty) {
        try {
          await _supabase
              .from('users')
              .update({'full_name': normalizedFullName})
              .eq('id', userId);

          await _supabase.auth.updateUser(
            UserAttributes(data: {'full_name': normalizedFullName}),
          );

          debugPrint('Fallback name sync succeeded: $normalizedFullName');
        } catch (fallbackError) {
          debugPrint('Fallback name sync failed: $fallbackError');
        }
      }
      // Do not fail login on profile sync issues.
    } finally {
      // Always force a fresh profile read after OTP login.
      await QueryCache.instance.invalidate(AppCacheKeys.userProfile(userId));
    }
  }

  

  // LOGOUT
// Signs out from Supabase — clears local session
// After this, currentSession returns null
// The router redirect detects this and sends user to /login
Future<void> signOut() async {
  await _supabase.auth.signOut();
  // Drop all cached API data so next login starts with clean user-scoped state.
  await QueryCache.instance.clearAll();
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
    if (userId == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Session expired. Please log in again.',
      );
      return;
    }

    // Refresh the session to guarantee a fresh, non-expired JWT before
    // invoking the edge function (stale tokens cause 401 Unauthorized).
    String? freshToken;
    try {
      final refreshed = await _supabase.auth.refreshSession();
      freshToken = refreshed.session?.accessToken;
    } catch (refreshError) {
      debugPrint('Session refresh before delete-account failed: $refreshError');
    }
    // Fall back to the current session token if refresh failed.
    freshToken ??= _supabase.auth.currentSession?.accessToken;

    if (freshToken == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Session expired. Please log in again.',
      );
      return;
    }

    // Keep the functions client in sync with the refreshed access token.
    // FunctionsClient caches Authorization headers, so update it explicitly.
    _supabase.functions.setAuth(freshToken);

    // Debug: confirm the token looks like a Supabase JWT (starts with "eyJ")
    debugPrint(
      'delete-account: token prefix="${freshToken.substring(0, freshToken.length.clamp(0, 6))}"',
    );

    // Delete account via secure Edge Function.
    final response = await _supabase.functions.invoke('delete-account');
    if (response.status != 200) {
      final data = response.data;
      String functionError = 'Failed to delete account';
      if (data is Map && data['error'] is String) {
        functionError = data['error'] as String;
      }
      throw Exception(functionError);
    }

    // Sign out locally (token might already be invalid after auth user deletion).
    try {
      await _supabase.auth.signOut();
    } catch (signOutError) {
      debugPrint('Sign out after account deletion failed: $signOutError');
    }

    // Account is gone; clear cached data to avoid stale reads on reused device.
    await QueryCache.instance.clearAll();

    state = state.copyWith(isLoading: false);

    // Close loading dialog and navigate to login
    if (context.mounted) {
      // Pop any open dialogs first
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      context.go(AppRoutes.login);
    }

  } on FunctionException catch (e) {
    debugPrint(
      'Delete account function error: status=${e.status}, '
      'details=${e.details}, reason=${e.reasonPhrase}',
    );

    // Surface DB constraint details in debug builds to make FK errors visible.
    if (e.details is Map) {
      final d = e.details as Map;
      debugPrint(
        'delete-account DB error detail="${d['detail']}" '
        'hint="${d['hint']}" code="${d['code']}"',
      );
    }

    var errorMessage = 'Could not delete account. Please try again later.';
    if (e.status == 401) {
      errorMessage = 'Session expired. Please log in again.';
    } else if (e.details is Map) {
      final details = e.details as Map;
      if (details['error'] is String) {
        errorMessage = details['error'] as String;
      } else if (details['message'] is String) {
        errorMessage = details['message'] as String;
      }
    }

    state = state.copyWith(
      isLoading: false,
      error: errorMessage,
    );
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