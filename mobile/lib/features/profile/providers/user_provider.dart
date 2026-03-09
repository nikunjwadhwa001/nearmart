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
