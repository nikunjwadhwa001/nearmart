import 'package:supabase_flutter/supabase_flutter.dart';

// Global accessor — use anywhere in the app
// Example: supabase.from('products').select()
final supabase = Supabase.instance.client;