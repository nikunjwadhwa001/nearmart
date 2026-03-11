import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Common email domain typos → correct domain
  static const _domainTypos = {
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

  /// Returns a typo suggestion if the domain looks like a common misspelling
  String? _checkDomainTypo(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return null;
    final domain = parts[1].toLowerCase();
    final correctDomain = _domainTypos[domain];
    if (correctDomain != null) {
      return '${parts[0]}@$correctDomain';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen for OTP sent — navigate to OTP screen
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.otpSent && !(previous?.otpSent ?? false)) {
        context.go('/otp', extra: {
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo and branding
                Center(
                  child: Column(
                    children: [
                      // App icon — styled to match actual icon design
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha:0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shopping_basket_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'NearMart',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your neighbourhood store, online',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Welcome text
                Text(
                  'Welcome 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your details to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),

                const SizedBox(height: 32),

                // Name field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'John Doe',
                    helperText: 'Optional — you can update this later',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    // Name is optional - only validate if user entered something
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    // Proper email validation regex
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    // Check for common domain typos
                    final suggestion = _checkDomainTypo(value.trim());
                    if (suggestion != null) {
                      return 'Did you mean $suggestion?';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Error message
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: const TextStyle(
                                color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (authState.error != null) const SizedBox(height: 16),

                // Submit button
                ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            await ref
                                .read(authNotifierProvider.notifier)
                                .sendOtp(
                                  _emailController.text.trim(),
                                  _nameController.text.trim(),
                                );
                          }
                        },
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Send OTP'),
                ),

                const SizedBox(height: 24),

                // Terms
                Center(
                  child: Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}