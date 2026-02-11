// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:taskers/models/transaction_model.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_h6i0poheiujW_jsRGBy5I7QUffLetoM',
    appId: '1:767941023108:web:4dc9ed9ce4ec67019cb9d1',
    messagingSenderId: '767941023108',
    projectId: 'taskers---connect',
    authDomain: 'taskers---connect.firebaseapp.com',
    storageBucket: 'taskers---connect.firebasestorage.app',
    measurementId: 'G-Z0F2P565ET',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD_h6i0poheiujW_jsRGBy5I7QUffLetoM',
    appId:
        '1:767941023108:android:YOUR_ANDROID_APP_ID', // Get from google-services.json
    messagingSenderId: '767941023108',
    projectId: 'taskers---connect',
    storageBucket: 'taskers---connect.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD_h6i0poheiujW_jsRGBy5I7QUffLetoM',
    appId: '1:767941023108:ios:IOS_APP_ID',
    messagingSenderId: '767941023108',
    projectId: 'taskers---connect',
    storageBucket: 'taskers---connect.firebasestorage.app',
    iosBundleId: 'com.example.taskers',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD_h6i0poheiujW_jsRGBy5I7QUffLetoM',
    appId: '1:767941023108:macos:MACOS_APP_ID',
    messagingSenderId: '767941023108',
    projectId: 'taskers---connect',
    storageBucket: 'taskers---connect.firebasestorage.app',
    iosBundleId: 'com.example.taskers',
  );

  // Test function to verify payment calculations
  void testPaymentCalculations() {
    print('=== PAYMENT CALCULATIONS TEST ===');

    final testAmounts = [500.0, 1000.0, 2500.0];

    for (final amount in testAmounts) {
      final fees = TransactionModel.calculateFees(amount);
      print('\nTask Amount: R${amount.toStringAsFixed(2)}');
      print('Service Fee: R${fees['service_fee']!.toStringAsFixed(2)}');
      print('Trust Fee: R${fees['trust_fee']!.toStringAsFixed(2)}');
      print('Processing Fee: R${fees['processing_fee']!.toStringAsFixed(2)}');
      print('Total Poster Pays: R${fees['total_amount']!.toStringAsFixed(2)}');
      print('Tasker Receives: R${fees['tasker_amount']!.toStringAsFixed(2)}');

      // Verify math
      final verification = fees['tasker_amount']! +
          fees['service_fee']! +
          fees['trust_fee']! +
          fees['processing_fee']!;
      print(
          'Verification: R${verification.toStringAsFixed(2)} = R${fees['total_amount']!.toStringAsFixed(2)} ✓');
    }
  }
}
