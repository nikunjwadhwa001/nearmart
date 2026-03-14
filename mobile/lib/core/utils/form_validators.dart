class AppFormValidators {
  AppFormValidators._();

  static const Map<String, String> _domainTypos = {
    'gnail.com': 'gmail.com',
    'gmial.com': 'gmail.com',
    'gmal.com': 'gmail.com',
    'gmai.com': 'gmail.com',
    'gamil.com': 'gmail.com',
    'gmail.co': 'gmail.com',
    'gmail.con': 'gmail.com',
    'gmaill.com': 'gmail.com',
    'yaho.com': 'yahoo.com',
    'yahooo.com': 'yahoo.com',
    'yahoo.con': 'yahoo.com',
    'yhaoo.com': 'yahoo.com',
    'hotmal.com': 'hotmail.com',
    'hotmai.com': 'hotmail.com',
    'hotmail.con': 'hotmail.com',
    'outlok.com': 'outlook.com',
    'outloo.com': 'outlook.com',
    'outlook.con': 'outlook.com',
    'iclud.com': 'icloud.com',
    'icoud.com': 'icloud.com',
    'icloud.con': 'icloud.com',
  };

  static String? optionalFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return null;
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? requiredFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Please enter your name';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? emailWithTypoSuggestion(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    final suggestion = suggestEmailDomain(email);
    if (suggestion != null) {
      return 'Did you mean $suggestion?';
    }

    return null;
  }

  static String? suggestEmailDomain(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return null;

    final domain = parts[1].toLowerCase();
    final correctDomain = _domainTypos[domain];
    if (correctDomain == null) return null;

    return '${parts[0]}@$correctDomain';
  }

  static String? requiredAddressLine(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your exact address';
    }
    return null;
  }

  static String? requiredIndianMobile(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return 'Phone number is required for delivery';
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }
}