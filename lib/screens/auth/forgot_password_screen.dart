import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/taskrabbit_text_field.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/error_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    AuthResult result = await AuthService.sendPasswordResetEmail(
      emailController.text,
    );

    setState(() => isLoading = false);

    if (result.success) {
      showDialog(
        context: context,
        builder: (c) => SuccessDialog(
          title: "Email Sent",
          message: "Password reset instructions have been sent to your email.",
          onOk: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Go back to login
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (c) => ErrorDialog(message: result.message!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reset Password",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset,
                  size: 60,
                  color: Color(0xFF00A651),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Forgot your password?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Enter your email address and we'll send you instructions to reset your password.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: TaskRabbitTextField(
                  controller: emailController,
                  hintText: "Email Address",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return "Email is required";
                    if (!value!.contains("@")) return "Enter a valid email";
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : handlePasswordReset,
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        "Send Reset Instructions",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
