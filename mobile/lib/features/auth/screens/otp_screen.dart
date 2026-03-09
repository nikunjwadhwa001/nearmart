import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../profile/providers/user_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String name;
  const OtpScreen({super.key, required this.email, required this.name});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  // Single controller and focus node — one hidden TextField drives everything
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _controller.text;
    if (otp.length != 6) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    // Hide keyboard
    _focusNode.unfocus();

    final error = await ref
        .read(authNotifierProvider.notifier)
        .verifyOtp(widget.email, otp, widget.name);

    if (!mounted) return;

    if (error == null) {
      ref.invalidate(userProfileProvider);
      context.go('/home');
    } else {
      // Map technical errors to user-friendly messages
      String friendlyError;
      if (error.toLowerCase().contains('expired') ||
          error.toLowerCase().contains('invalid')) {
        friendlyError = 'This code has expired or is incorrect. Please tap "Resend OTP" to get a new code.';
      } else if (error.toLowerCase().contains('network') ||
          error.toLowerCase().contains('connection')) {
        friendlyError = 'Please check your internet connection and try again.';
      } else {
        friendlyError = 'Something went wrong. Please try again or request a new code.';
      }
      setState(() {
        _isVerifying = false;
        _error = friendlyError;
      });
      // Re-focus so user can retry
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Text(
                'Check your email 📬',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to\n${widget.email}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),

              const SizedBox(height: 40),

              // OTP input — single hidden TextField with visual digit boxes
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Stack(
                  children: [
                    // Hidden real TextField that captures all keyboard input
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        height: 56,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          readOnly: _isVerifying,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            // Rebuild the visual boxes
                            setState(() {});
                            // Auto-submit when 6 digits entered
                            if (value.length == 6 && !_isVerifying) {
                              _verifyOtp();
                            }
                          },
                        ),
                      ),
                    ),

                    // Visual digit boxes drawn on top
                    IgnorePointer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final text = _controller.text;
                          final hasDigit = index < text.length;
                          final isActive = index == text.length;

                          return Container(
                            width: 48,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? AppTheme.primary
                                    : hasDigit
                                        ? AppTheme.primary.withValues(alpha: 0.5)
                                        : Colors.grey.shade200,
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              hasDigit ? text[index] : '',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error
              if (_error != null)
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
                          _error!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_error != null) const SizedBox(height: 16),

              // Verify button
              ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Verify OTP'),
              ),

              const SizedBox(height: 16),

              // Resend
              Center(
                child: TextButton(
                  onPressed: _isVerifying
                      ? null
                      : () {
                          ref
                              .read(authNotifierProvider.notifier)
                              .sendOtp(widget.email, widget.name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:  Text('OTP resent!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}