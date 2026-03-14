class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const home = '/home';
  static const profile = '/profile';
  static const cart = '/cart';
  static const orders = '/orders';
  static const search = '/search';

  static const shopDetailPattern = '/shop/:shopId';
  static const orderConfirmationPattern = '/order-confirmation/:orderId';
  static const orderDetailPattern = '/order/:orderId';

  static String shopDetail(String shopId) => '/shop/$shopId';
  static String orderConfirmation(String orderId) => '/order-confirmation/$orderId';
  static String orderDetail(String orderId) => '/order/$orderId';
}
