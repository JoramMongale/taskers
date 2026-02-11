import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_dialog.dart';

class RoleSelectionScreen extends StatefulWidget {
  final User user;

  const RoleSelectionScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  List<String> selectedRoles = [];
  bool _disposed = false; // ✅ FIX: Track disposal

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void toggleRole(String role) {
    if (_disposed) return; // ✅ FIX: Check disposal

    setState(() {
      if (selectedRoles.contains(role)) {
        selectedRoles.remove(role);
      } else {
        selectedRoles.add(role);
      }
    });
  }

  Future<void> saveRolesAndContinue() async {
    if (_disposed || !mounted) return; // ✅ FIX: Check state

    if (selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one role"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ FIX: Use context check before showing dialog
    if (!mounted || _disposed) return;

    showDialog(
      context: context,
      barrierDismissible: false, // ✅ FIX: Prevent dismissal during loading
      builder: (c) {
        return const LoadingDialog(
          message: "Setting up your account...",
        );
      },
    );

    try {
      // Update user roles in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.user.uid)
          .update({
        "userTypes": selectedRoles,
        "currentRole": selectedRoles.first, // Default to first selected role
        "lastActive": FieldValue.serverTimestamp(),
      });

      // Update local storage
      await AuthService.saveUserDataLocally(
        uid: widget.user.uid,
        email: widget.user.email!,
        name: widget.user.displayName ?? '', // ✅ FIX: Handle null displayName
        photoUrl: widget.user.photoURL ?? '', // ✅ FIX: Handle null photoURL
        userTypes: selectedRoles,
        currentRole: selectedRoles.first,
      );

      // ✅ FIX: Safe navigation with state checks
      if (mounted && !_disposed) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (error) {
      // ✅ FIX: Safe error handling
      if (mounted && !_disposed) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00A651),
              Color(0xFF4CAF50),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "What would you like to do?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Select all that apply:",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Post Tasks Option
                GestureDetector(
                  onTap: () => toggleRole("poster"),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedRoles.contains("poster")
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_task,
                          size: 40,
                          color: selectedRoles.contains("poster")
                              ? const Color(0xFF00A651)
                              : Colors.white,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Post Tasks",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: selectedRoles.contains("poster")
                                      ? const Color(0xFF00A651)
                                      : Colors.white,
                                ),
                              ),
                              Text(
                                "I need help with tasks",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: selectedRoles.contains("poster")
                                      ? const Color(0xFF00A651).withOpacity(0.7)
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selectedRoles.contains("poster"))
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 30,
                          ),
                      ],
                    ),
                  ),
                ),

                // Complete Tasks Option
                GestureDetector(
                  onTap: () => toggleRole("tasker"),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedRoles.contains("tasker")
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.handyman,
                          size: 40,
                          color: selectedRoles.contains("tasker")
                              ? const Color(0xFF00A651)
                              : Colors.white,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Complete Tasks",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: selectedRoles.contains("tasker")
                                      ? const Color(0xFF00A651)
                                      : Colors.white,
                                ),
                              ),
                              Text(
                                "I want to earn money doing tasks",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: selectedRoles.contains("tasker")
                                      ? const Color(0xFF00A651).withOpacity(0.7)
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selectedRoles.contains("tasker"))
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 30,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        selectedRoles.isNotEmpty ? saveRolesAndContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: selectedRoles.isNotEmpty
                            ? const Color(0xFF00A651)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (selectedRoles.isNotEmpty)
                  Text(
                    "You can always change this later in settings",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
