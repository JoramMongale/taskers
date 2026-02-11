// File: lib/screens/auth/login_form.dart (FIXED)

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/taskrabbit_text_field.dart';
import '../../widgets/error_dialog.dart';
import 'forgot_password_screen.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    // Clean up controllers
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    print('🔵 Login attempt started');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    if (!mounted) {
      print('❌ Widget not mounted at start');
      return;
    }

    setState(() => isLoading = true);
    print('⏳ Login loading state set to true');

    try {
      print('📧 Attempting login with: ${emailController.text}');

      AuthResult result = await AuthService.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      print(
          '🔄 Login result: success=${result.success}, message=${result.message}');

      // ✅ FIX: Only handle UI updates if widget is still mounted
      if (mounted) {
        setState(() => isLoading = false);

        if (!result.success) {
          print('❌ Login failed: ${result.message}');
          showDialog(
            context: context,
            builder: (c) => ErrorDialog(message: result.message!),
          );
        } else {
          print('✅ Login successful! User: ${result.user?.email}');
          // ✅ Don't manually navigate - let AuthWrapper handle it
          // The AuthWrapper will detect the auth state change and navigate automatically
        }
      } else {
        // ✅ Widget was disposed (user navigated away) - this is normal!
        print('✅ Widget disposed after successful login (this is expected)');
      }
    } catch (e) {
      print('💥 Login exception: $e');

      // Only show error dialog if widget is still mounted
      if (mounted) {
        setState(() => isLoading = false);
        showDialog(
          context: context,
          builder: (c) => ErrorDialog(message: 'Login error: $e'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TaskRabbitTextField(
            controller: emailController,
            hintText: "Email Address",
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return "Email is required";
              if (!value!.contains("@")) return "Enter a valid email";
              return null;
            },
          ),
          const SizedBox(height: 16),
          TaskRabbitTextField(
            controller: passwordController,
            hintText: "Password",
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return "Password is required";
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  color: Color(0xFF00A651),
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    "Sign In",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
