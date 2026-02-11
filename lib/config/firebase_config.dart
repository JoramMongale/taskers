import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // These will be loaded from environment variables in production
  static const String _webApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'your-default-key-here',
  );

  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'taskers-default',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _webApiKey,
    appId: '1:767941023108:web:4dc9ed9ce4ec67019cb9d1',
    messagingSenderId: '767941023108',
    projectId: _projectId,
    authDomain: '$_projectId.firebaseapp.com',
    storageBucket: '$_projectId.firebasestorage.app',
    measurementId: 'G-Z0F2P565ET',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _webApiKey,
    appId: '1:767941023108:android:ANDROID_APP_ID',
    messagingSenderId: '767941023108',
    projectId: _projectId,
    storageBucket: '$_projectId.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _webApiKey,
    appId: '1:767941023108:ios:IOS_APP_ID',
    messagingSenderId: '767941023108',
    projectId: _projectId,
    storageBucket: '$_projectId.firebasestorage.app',
    iosBundleId: 'com.taskers.app',
  );
}
