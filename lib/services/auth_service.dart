// File: lib/services/auth_service.dart (UPDATED WITH DEBUG)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static SharedPreferences? _sharedPreferences; // ✅ FIX: Private variable

  // ✅ FIX: Singleton pattern for SharedPreferences
  static Future<SharedPreferences> get sharedPreferences async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  // Current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Email/Password Authentication
  static Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('🔵 AuthService.signInWithEmailAndPassword called');
    print('📧 Email: $email');

    try {
      print('⏳ Calling Firebase signInWithEmailAndPassword...');

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ Firebase signin successful');

      if (result.user != null) {
        print('👤 User object received: ${result.user!.email}');
        print('📧 Email verified: ${result.user!.emailVerified}');

        // Check email verification
        if (!result.user!.emailVerified) {
          print('❌ Email not verified, sending verification email');
          await result.user!.sendEmailVerification();
          return AuthResult.emailNotVerified();
        }

        print('⏳ Loading user data to local storage...');
        // ✅ FIX: Load user data into local storage
        await _loadUserDataToLocal(result.user!);

        print('⏳ Updating last login...');
        // Update last login
        await _updateLastLogin(result.user!.uid);

        print('✅ Sign-in process completed successfully');
        return AuthResult.success(result.user!);
      }

      print('❌ No user object in result');
      return AuthResult.failure("Login failed");
    } on FirebaseAuthException catch (e) {
      print('🔥 FirebaseAuthException: ${e.code} - ${e.message}');
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      print('💥 Unexpected error during sign-in: $e');
      return AuthResult.failure("An unexpected error occurred: $e");
    }
  }

  /// Register with Email/Password
  static Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String zipCode,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        // Send email verification
        await result.user!.sendEmailVerification();

        // Create user document
        await _createUserDocument(
          user: result.user!,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          zipCode: zipCode,
        );

        return AuthResult.success(result.user!);
      }
      return AuthResult.failure("Registration failed");
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure("An unexpected error occurred: $e");
    }
  }

  /// Send Password Reset Email
  static Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null, message: "Password reset email sent");
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure("Failed to send password reset email: $e");
    }
  }

  /// Resend Email Verification
  static Future<AuthResult> resendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return AuthResult.success(null, message: "Verification email sent");
      }
      return AuthResult.failure("User not found or already verified");
    } catch (e) {
      return AuthResult.failure("Failed to send verification email: $e");
    }
  }

  /// Sign Out
  static Future<void> signOut() async {
    // ✅ ADD: Debug logging to find what's calling signOut
    print('🚪 AuthService.signOut() called');
    print('📍 Stack trace:');
    print(StackTrace.current);

    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Clear local data
      await _clearLocalData();

      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      // Even if there's an error, try to clear local data
      await _clearLocalData();
      rethrow;
    }
  }

  /// ✅ FIX: Load user data from Firestore to local storage
  static Future<void> _loadUserDataToLocal(User user) async {
    try {
      print('⏳ Loading user data from Firestore for: ${user.uid}');

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        print('✅ User document found in Firestore');
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('📄 User data keys: ${data.keys.toList()}');
        print('🔧 User types from Firestore: ${data['userTypes']}');

        await saveUserDataLocally(
          uid: user.uid,
          email: data['email'] ?? user.email ?? '',
          name: data['displayName'] ?? '',
          photoUrl: data['profileImageUrl'] ?? user.photoURL ?? '',
          userTypes: List<String>.from(data['userTypes'] ?? []),
          currentRole: data['currentRole'] ?? '',
        );

        print('✅ User data saved locally');
      } else {
        print('❌ User document not found in Firestore - saving basic data');
        // Save basic user data anyway
        await saveUserDataLocally(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          photoUrl: user.photoURL ?? '',
          userTypes: [],
          currentRole: '',
        );
        print('✅ Basic user data saved locally');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      // Don't throw - continue with basic data
      try {
        await saveUserDataLocally(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          photoUrl: user.photoURL ?? '',
          userTypes: [],
          currentRole: '',
        );
        print('✅ Fallback user data saved');
      } catch (e2) {
        print('💥 Failed to save fallback user data: $e2');
      }
    }
  }

  /// Create user document in Firestore
  static Future<void> _createUserDocument({
    required User user,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String zipCode,
  }) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'emailVerified': user.emailVerified,
        'displayName': '$firstName $lastName',
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'phoneVerified': false,
        'zipCode': zipCode,
        'profileImageUrl': user.photoURL ?? '',
        'address': '',
        'latitude': 0.0,
        'longitude': 0.0,
        'status': 'active',
        'isVerified': false,
        'userTypes': [],
        'currentRole': null,
        'fcmToken': '',
        'pushNotificationsEnabled': false,
        'emailNotificationsEnabled': true,
        'smsNotificationsEnabled': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  /// Update last login timestamp
  static Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  /// Get user data from Firestore
  static Future<AppUser?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Save user data locally
  static Future<void> saveUserDataLocally({
    required String uid,
    required String email,
    required String name,
    required String photoUrl,
    required List<String> userTypes,
    required String currentRole,
  }) async {
    try {
      final prefs = await sharedPreferences;

      await prefs.setString("uid", uid);
      await prefs.setString("email", email);
      await prefs.setString("name", name);
      await prefs.setString("photoUrl", photoUrl);
      await prefs.setStringList("userTypes", userTypes);
      await prefs.setString("currentRole", currentRole);
      await prefs.setBool("isLoggedIn", true);

      print(
          '💾 Saved to local storage - userTypes: $userTypes, currentRole: $currentRole');
    } catch (e) {
      print('Error saving user data locally: $e');
    }
  }

  /// Update user role
  static Future<void> updateUserRole(String newRole) async {
    try {
      final prefs = await sharedPreferences;
      await prefs.setString("currentRole", newRole);

      // Update in Firestore too
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          'currentRole': newRole,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating user role: $e');
    }
  }

  /// Get current role
  static Future<String?> getCurrentRole() async {
    try {
      final prefs = await sharedPreferences;
      String? role = prefs.getString("currentRole");
      print('📖 Retrieved current role: $role');
      return role;
    } catch (e) {
      print('Error getting current role: $e');
      return null;
    }
  }

  /// Get user types
  static Future<List<String>?> getUserTypes() async {
    try {
      final prefs = await sharedPreferences;
      List<String>? userTypes = prefs.getStringList("userTypes");
      print('📖 Retrieved user types: $userTypes');
      return userTypes;
    } catch (e) {
      print('Error getting user types: $e');
      return null;
    }
  }

  /// Clear local data
  static Future<void> _clearLocalData() async {
    try {
      final prefs = await sharedPreferences;
      await prefs.clear();
      print('Local data cleared successfully');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  /// Convert Firebase errors to user-friendly messages
  static String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

/// Authentication Result Class
class AuthResult {
  final bool success;
  final String? message;
  final User? user;

  AuthResult._({
    required this.success,
    this.message,
    this.user,
  });

  factory AuthResult.success(User? user, {String? message}) {
    return AuthResult._(
      success: true,
      user: user,
      message: message,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      success: false,
      message: message,
    );
  }

  factory AuthResult.emailNotVerified() {
    return AuthResult._(
      success: false,
      message: 'Please verify your email address before signing in.',
    );
  }
}
