import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Step 1 — send OTP to email
  Future<void> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
        emailRedirectTo: null, // no redirect — forces OTP code instead of magic link
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

  // Step 2 — verify OTP
  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session != null) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid OTP. Please try again.',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
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