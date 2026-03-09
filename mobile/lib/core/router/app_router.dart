import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/shop/screens/shop_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../models/shop.dart';

// All route paths as constants
// Never type '/login' as a raw string anywhere else in the app
// Always use AppRoutes.login — typos become compile errors
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const home = '/home';
  static const shopDetail = '/shop';
  static const profile = '/profile';
  static const cart = '/cart';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,

    // redirect runs before EVERY navigation
    // it's a security guard checking auth state
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      // These are the only screens accessible without login
      final isOnAuthScreen =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.otp ||
          state.matchedLocation == AppRoutes.splash;

      // Logged in but trying to access auth screens → go home
      if (isLoggedIn && isOnAuthScreen) return AppRoutes.home;

      // Not logged in but trying to access protected screens → go login
      if (!isLoggedIn && !isOnAuthScreen) return AppRoutes.login;

      // null means — continue to the intended route
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
          // Login screen passes a Map with email and name
          final extra = state.extra as Map<String, dynamic>;
          return OtpScreen(
            email: extra['email'] as String,
            name: extra['name'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/shop/:shopId',
        builder: (context, state) {
          // state.extra carries the full Shop object
          // passed from ShopCard when user taps it
          final shop = state.extra as Shop;
          return ShopDetailScreen(shop: shop);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});