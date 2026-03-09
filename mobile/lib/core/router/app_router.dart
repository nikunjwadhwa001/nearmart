
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

// Routes as constants — no magic strings anywhere
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const home = '/home';
  static const profile = '/profile';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final currentPath = state.matchedLocation;

      // Never redirect away from OTP screen — user needs to verify the code
      if (currentPath == AppRoutes.otp) return null;

      final isOnAuthScreen =
          currentPath == AppRoutes.login ||
          currentPath == AppRoutes.splash;

      // If logged in and trying to access auth screens, go home
      if (isLoggedIn && isOnAuthScreen) return AppRoutes.home;

      // If not logged in and trying to access protected screens, go login
      if (!isLoggedIn && !isOnAuthScreen) return AppRoutes.login;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          // Extract email and name from extra parameter
          final extra = state.extra;
          final email = extra is Map ? (extra['email'] as String? ?? '') : (extra as String? ?? '');
          final name = extra is Map ? (extra['name'] as String? ?? '') : '';
          return OtpScreen(email: email, name: name);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});