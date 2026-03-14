class AppMessages {
  AppMessages._();

  static const genericTryAgain = 'Something went wrong. Please try again.';
  static const networkTryAgain =
      'Please check your internet connection and try again.';
  static const invalidOtp = 'Invalid OTP. Please try again.';
  static const otpExpiredOrIncorrect =
      'This code has expired or is incorrect. Please tap "Resend OTP" to get a new code.';
  static const otpVerificationFallback =
      'Something went wrong. Please try again or request a new code.';
}

class AppLimits {
  AppLimits._();

  static const otpLength = 6;
}

class AppCacheKeys {
  AppCacheKeys._();

  static String userProfile(String userId) => 'profile:v1:user:$userId';
}

class AppTtl {
  AppTtl._();

  static const userProfile = Duration(hours: 24);
}
