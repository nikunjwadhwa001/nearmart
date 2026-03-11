import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../models/user.dart';

// Fetch current user profile from public.users table
// This gets the full profile data, not just auth info
final userProfileProvider = FutureProvider<User?>((ref) async {
  final supabase = Supabase.instance.client;
  final authUser = supabase.auth.currentUser;
  
  // If not logged in, return null
  if (authUser == null) return null;

  try {
    // Fetch user data from public.users table
    final response = await supabase
        .from('users')
        .select()
        .eq('id', authUser.id)
        .single();

    return User.fromJson(response);
  } catch (e) {
    // If user doesn't exist in public.users yet (rare edge case), return null
    return null;
  }
});

// Provider to update user profile
final userUpdateProvider = Provider<UserUpdate>((ref) {
  return UserUpdate(ref);
});

class UserUpdate {
  final Ref ref;
  UserUpdate(this.ref);

  final _supabase = Supabase.instance.client;

  // Update user's full name in both public.users and auth.users
  Future<void> updateFullName(String newName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // Update public.users (our app table)
    await _supabase
        .from('users')
        .update({'full_name': newName})
        .eq('id', userId);

    // Update auth.users metadata (Supabase auth table)
    await _supabase.auth.updateUser(
      UserAttributes(data: {'full_name': newName}),
    );

    // Refresh the profile provider to show updated data
    ref.invalidate(userProfileProvider);
  }
}
