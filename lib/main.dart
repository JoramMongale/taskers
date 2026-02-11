// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/dashboard/home_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// Remove the url_launcher_web import - it's not needed and causes issues on mobile

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const TaskersApp());
}

class TaskersApp extends StatelessWidget {
  const TaskersApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00A651),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A651),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A651),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00A651), width: 2),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        print(
            '🔄 Auth state: ${snapshot.connectionState}, User: ${snapshot.data?.email ?? 'null'}');

        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ Waiting for auth state...');
          return const SplashScreen();
        }

        // Handle stream errors gracefully
        if (snapshot.hasError) {
          print('❌ Auth stream error: ${snapshot.error}');
          return const AuthScreen();
        }

        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('✅ User authenticated: ${user.email}');

          // Check if email is verified
          if (!user.emailVerified) {
            print('📧 Email not verified, showing verification screen');
            return EmailVerificationScreen(user: user);
          }

          // Check BOTH local storage AND Firestore for user types
          return FutureBuilder<Map<String, dynamic>>(
            future: _loadCompleteUserData(user.uid),
            builder: (context, userDataSnapshot) {
              if (userDataSnapshot.connectionState == ConnectionState.waiting) {
                print('⏳ Loading complete user data...');
                return const SplashScreen();
              }

              if (userDataSnapshot.hasError) {
                print('❌ User data error: ${userDataSnapshot.error}');
                return RoleSelectionScreen(user: user);
              }

              Map<String, dynamic>? userData = userDataSnapshot.data;
              List<String>? userTypes = userData?['userTypes'];

              print('👤 Complete user data loaded - userTypes: $userTypes');

              if (userTypes == null || userTypes.isEmpty) {
                print('🔄 No user types found, showing role selection');
                return RoleSelectionScreen(user: user);
              }

              print('🏠 User has roles, showing home screen');
              return const HomeScreen();
            },
          );
        }

        // User is not logged in
        print('🔓 No user - showing auth screen');
        return const AuthScreen();
      },
    );
  }

  /// Load complete user data from both local storage and Firestore
  Future<Map<String, dynamic>> _loadCompleteUserData(String userId) async {
    try {
      // First, try to get from local storage
      List<String>? localUserTypes = await AuthService.getUserTypes();
      String? localCurrentRole = await AuthService.getCurrentRole();

      print(
          '📱 Local storage - userTypes: $localUserTypes, currentRole: $localCurrentRole');

      // If we have complete local data, use it
      if (localUserTypes != null && localUserTypes.isNotEmpty) {
        print('✅ Using local storage data');
        return {
          'userTypes': localUserTypes,
          'currentRole': localCurrentRole,
          'source': 'local'
        };
      }

      // Otherwise, wait for Firestore data to be loaded
      print('⏳ Waiting for Firestore data...');

      // Give a moment for the sign-in process to complete Firestore loading
      await Future.delayed(const Duration(milliseconds: 1000));

      // Check local storage again after delay
      localUserTypes = await AuthService.getUserTypes();
      localCurrentRole = await AuthService.getCurrentRole();

      print(
          '📱 After delay - userTypes: $localUserTypes, currentRole: $localCurrentRole');

      if (localUserTypes != null && localUserTypes.isNotEmpty) {
        print('✅ Using delayed local storage data');
        return {
          'userTypes': localUserTypes,
          'currentRole': localCurrentRole,
          'source': 'delayed_local'
        };
      }

      // If still no data, return empty (will show role selection)
      print('❌ No user data found after delay');
      return {'userTypes': <String>[], 'currentRole': null, 'source': 'none'};
    } catch (e) {
      print('💥 Error loading user data: $e');
      return {'userTypes': <String>[], 'currentRole': null, 'source': 'error'};
    }
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00A651),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.task_alt,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "taskers",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A651),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Get things done in South Africa",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A651)),
            ),
          ],
        ),
      ),
    );
  }
}
