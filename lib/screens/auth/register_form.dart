import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/taskrabbit_text_field.dart';
import '../../widgets/error_dialog.dart';
import 'email_verification_screen.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();

  bool isLoading = false;
  String selectedCountryCode = "+27"; // South Africa default

  @override
  void dispose() {
    // Clean up controllers
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    zipCodeController.dispose();
    super.dispose();
  }

  Future<void> handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return; // Check if widget is still mounted

    setState(() => isLoading = true);

    AuthResult result = await AuthService.registerWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      phoneNumber: "$selectedCountryCode${phoneController.text.trim()}",
      zipCode: zipCodeController.text,
    );

    if (!mounted) return; // Check again before calling setState

    setState(() => isLoading = false);

    if (result.success && result.user != null) {
      // Navigate to email verification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (c) => EmailVerificationScreen(user: result.user!),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TaskRabbitTextField(
            controller: firstNameController,
            hintText: "First Name",
            validator: (value) {
              if (value?.isEmpty ?? true) return "First name is required";
              return null;
            },
          ),
          const SizedBox(height: 16),
          TaskRabbitTextField(
            controller: lastNameController,
            hintText: "Last Name",
            validator: (value) {
              if (value?.isEmpty ?? true) return "Last name is required";
              return null;
            },
          ),
          const SizedBox(height: 16),
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
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🇿🇦", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      selectedCountryCode,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TaskRabbitTextField(
                  controller: phoneController,
                  hintText: "Phone Number",
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true)
                      return "Phone number is required";
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TaskRabbitTextField(
            controller: passwordController,
            hintText: "Password",
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return "Password is required";
              if (value!.length < 6)
                return "Password must be at least 6 characters";
              return null;
            },
          ),
          const SizedBox(height: 16),
          TaskRabbitTextField(
            controller: zipCodeController,
            hintText: "Zip Code",
            validator: (value) {
              if (value?.isEmpty ?? true) return "Zip code is required";
              return null;
            },
          ),
          const SizedBox(height: 24),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              children: [
                const TextSpan(
                    text:
                        "By clicking below and creating an account, I agree to Taskers' "),
                TextSpan(
                  text: "Terms of Service",
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                const TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy",
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                const TextSpan(text: "."),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : handleSignUp,
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
                    "Create account",
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
