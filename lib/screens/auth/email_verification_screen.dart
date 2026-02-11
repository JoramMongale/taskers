import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/error_dialog.dart';

class EmailVerificationScreen extends StatefulWidget {
  final User user;

  const EmailVerificationScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isLoading = false;
  Timer? _timer;
  Timer? _checkTimer;
  bool canResendEmail = false;
  int countdown = 60;
  bool isEmailVerified = false;
  bool _disposed = false; // ✅ FIX: Track disposal state

  @override
  void initState() {
    super.initState();
    isEmailVerified = widget.user.emailVerified;

    if (!isEmailVerified) {
      startCountdown();
      startEmailVerificationCheck();
    }
  }

  @override
  void dispose() {
    // ✅ FIX: Proper cleanup to prevent memory leaks
    _disposed = true;
    _timer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  void startEmailVerificationCheck() {
    // ✅ FIX: Check disposal before creating timer
    if (_disposed) return;

    _checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // ✅ FIX: Always check if disposed and mounted
      if (_disposed || !mounted) {
        timer.cancel();
        return;
      }

      try {
        await widget.user.reload();
        final user = FirebaseAuth.instance.currentUser;

        if (user != null && user.emailVerified) {
          if (mounted && !_disposed) {
            setState(() {
              isEmailVerified = true;
            });
          }
          timer.cancel();

          // ✅ FIX: Safe navigation with proper checks
          if (mounted && !_disposed) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/role-selection',
              (route) => false,
            );
          }
        }
      } catch (e) {
        print('Error checking email verification: $e');
        // ✅ FIX: Cancel timer on error to prevent infinite checks
        if (!_disposed) {
          timer.cancel();
        }
      }
    });
  }

  void startCountdown() {
    // ✅ FIX: Check disposal before creating timer
    if (_disposed || !mounted) return;

    setState(() {
      canResendEmail = false;
      countdown = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // ✅ FIX: Always check disposal and mounted state
      if (_disposed || !mounted) {
        timer.cancel();
        return;
      }

      if (countdown > 0) {
        setState(() => countdown--);
      } else {
        setState(() => canResendEmail = true);
        timer.cancel();
      }
    });
  }

  Future<void> resendVerificationEmail() async {
    // ✅ FIX: Check state before proceeding
    if (_disposed || !mounted) return;

    setState(() => isLoading = true);

    try {
      await widget.user.sendEmailVerification();

      if (mounted && !_disposed) {
        showDialog(
          context: context,
          builder: (c) => const SuccessDialog(
            title: "Email Sent",
            message: "Verification email has been sent to your inbox.",
          ),
        );
        startCountdown();
      }
    } catch (e) {
      if (mounted && !_disposed) {
        showDialog(
          context: context,
          builder: (c) =>
              ErrorDialog(message: "Failed to send verification email"),
        );
      }
    } finally {
      if (mounted && !_disposed) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> checkEmailManually() async {
    if (_disposed || !mounted) return;

    try {
      await widget.user.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        if (mounted && !_disposed) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/role-selection',
            (route) => false,
          );
        }
      } else {
        if (mounted && !_disposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email not yet verified. Please check your inbox."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error checking verification: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 80,
                  color: Color(0xFF00A651),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Verify your email",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "We've sent a verification email to:\n${widget.user.email}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Please check your inbox and click the verification link to continue.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Check verification status button
              ElevatedButton(
                onPressed: checkEmailManually,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "I've verified my email",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 20),

              // Resend email button
              TextButton(
                onPressed: canResendEmail && !isLoading
                    ? resendVerificationEmail
                    : null,
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        canResendEmail
                            ? "Resend Verification Email"
                            : "Resend in ${countdown}s",
                        style: TextStyle(
                          color: canResendEmail
                              ? const Color(0xFF00A651)
                              : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
              ),

              const SizedBox(height: 40),

              // Back to login button
              OutlinedButton(
                onPressed: () async {
                  await AuthService.signOut();
                  if (mounted && !_disposed) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/auth',
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Back to Login",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
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
