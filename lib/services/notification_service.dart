// lib/services/notification_service.dart - Complete Production Ready
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Navigation key for handling notification taps
  static GlobalKey<NavigatorState>? navigatorKey;

  // Initialize notification service
  static Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    print('🔔 Initializing notification service...');
    navigatorKey = navKey;

    try {
      // Skip FCM token for web in development
      if (kIsWeb && kDebugMode) {
        print('⚠️ Running on web in debug mode - skipping FCM initialization');
        await _initializeLocalNotifications();
        return;
      }

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications (mobile only)
      if (!kIsWeb) {
        await _initializeLocalNotifications();
      }

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Get and save FCM token (mobile only)
      if (!kIsWeb) {
        await _saveDeviceToken();
      }

      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      // Don't throw - allow app to continue working
    }
  }

  // Request notification permissions
  static Future<void> _requestPermissions() async {
    print('📱 Requesting notification permissions...');

    try {
      // Request Firebase messaging permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📋 Permission status: ${settings.authorizationStatus}');

      // Request local notification permissions (Android 13+)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.request();
        print('📱 Android notification permission: $status');
      }
    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  // Initialize local notifications (mobile only)
  static Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) return;

    print('🔧 Setting up local notifications...');

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _createNotificationChannel();
      }

      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  // Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'taskers_channel',
      'Taskers Notifications',
      description: 'Notifications for Taskers app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Initialize Firebase messaging
  static Future<void> _initializeFirebaseMessaging() async {
    if (kIsWeb && kDebugMode) return; // Skip for web in development

    print('🔥 Setting up Firebase messaging...');

    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app is terminated
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      print('✅ Firebase messaging initialized');
    } catch (e) {
      print('❌ Error initializing Firebase messaging: $e');
    }
  }

  // Save device FCM token to Firestore (mobile only)
  static Future<void> _saveDeviceToken() async {
    if (kIsWeb) return; // Skip for web

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? token;

      // Get token based on platform
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // For iOS, we need to get APNs token first
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          token = await _firebaseMessaging.getToken();
        }
      } else {
        token = await _firebaseMessaging.getToken();
      }

      if (token == null) {
        print('⚠️ Failed to get FCM token');
        return;
      }

      print('💾 Saving FCM token: ${token.substring(0, 20)}...');

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      });

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM token refreshed');
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      });

      print('✅ FCM token saved successfully');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
      // Don't throw - this is not critical
    }
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('🔔 Background message received: ${message.messageId}');
    if (!kIsWeb) {
      await _showLocalNotification(message);
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 Foreground message received: ${message.messageId}');
    if (!kIsWeb) {
      await _showLocalNotification(message);
    }
  }

  // Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('👆 Notification tapped: ${message.messageId}');

    final data = message.data;
    final type = data['type'];

    // Wait a bit for app to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    switch (type) {
      case 'new_message':
        final conversationId = data['conversationId'];
        if (conversationId != null && navigatorKey?.currentContext != null) {
          // Navigate to chat screen
          navigatorKey!.currentState?.pushNamed(
            '/chat',
            arguments: {'conversationId': conversationId},
          );
        }
        break;
      case 'task_application':
        final taskId = data['taskId'];
        if (taskId != null && navigatorKey?.currentContext != null) {
          // Navigate to task details
          navigatorKey!.currentState?.pushNamed(
            '/task-detail',
            arguments: {'taskId': taskId},
          );
        }
        break;
      case 'task_update':
        final taskId = data['taskId'];
        if (taskId != null && navigatorKey?.currentContext != null) {
          // Navigate to task details
          navigatorKey!.currentState?.pushNamed(
            '/task-detail',
            arguments: {'taskId': taskId},
          );
        }
        break;
      case 'payment_update':
        // Navigate to transactions
        navigatorKey?.currentState?.pushNamed('/transactions');
        break;
    }
  }

  // Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        // Parse payload (assuming it's a simple type:id format)
        final parts = response.payload!.split(':');
        if (parts.length == 2) {
          final type = parts[0];
          final id = parts[1];

          switch (type) {
            case 'conversation':
              navigatorKey?.currentState?.pushNamed(
                '/chat',
                arguments: {'conversationId': id},
              );
              break;
            case 'task':
              navigatorKey?.currentState?.pushNamed(
                '/task-detail',
                arguments: {'taskId': id},
              );
              break;
          }
        }
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  // Show local notification (mobile only)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    try {
      final notification = message.notification;
      if (notification == null) return;

      const androidDetails = AndroidNotificationDetails(
        'taskers_channel',
        'Taskers Notifications',
        channelDescription: 'Notifications for Taskers app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF00A651),
        playSound: true,
        enableVibration: true,
        ticker: 'ticker',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Create payload for tap handling
      String? payload;
      if (message.data['type'] == 'new_message' &&
          message.data['conversationId'] != null) {
        payload = 'conversation:${message.data['conversationId']}';
      } else if (message.data['taskId'] != null) {
        payload = 'task:${message.data['taskId']}';
      }

      await _localNotifications.show(
        message.hashCode,
        notification.title ?? 'Taskers',
        notification.body ?? 'You have a new notification',
        details,
        payload: payload,
      );

      print('✅ Local notification shown');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📤 Sending notification to user: $userId');

      // Save notification to Firestore for persistence
      await _saveNotificationToFirestore(userId, title, body, type, data);

      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];
      final pushEnabled = userData?['pushNotificationsEnabled'] ?? true;

      if (!pushEnabled) {
        print('⚠️ User has disabled push notifications');
        return;
      }

      if (fcmToken == null || kIsWeb) {
        print('⚠️ No FCM token found or running on web');
        return;
      }

      // In production, you would send this to your backend server
      // which would then send the notification via FCM Admin SDK
      // For now, we'll just save to Firestore

      // Create a cloud function trigger document
      await _firestore.collection('notification_queue').add({
        'token': fcmToken,
        'title': title,
        'body': body,
        'data': {
          'type': type,
          ...?data,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      print('✅ Notification queued for sending');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  // Save notification to Firestore for persistence
  static Future<void> _saveNotificationToFirestore(
    String userId,
    String title,
    String body,
    String type,
    Map<String, dynamic>? data,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification saved to Firestore');
    } catch (e) {
      print('❌ Error saving notification to Firestore: $e');
    }
  }

  // Send message notification
  static Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageContent,
    required String conversationId,
  }) async {
    // Truncate message if too long
    final truncatedMessage = messageContent.length > 100
        ? '${messageContent.substring(0, 97)}...'
        : messageContent;

    await sendNotificationToUser(
      userId: receiverId,
      title: senderName,
      body: truncatedMessage,
      type: 'new_message',
      data: {
        'conversationId': conversationId,
        'senderName': senderName,
      },
    );
  }

  // Send task application notification
  static Future<void> sendTaskApplicationNotification({
    required String posterId,
    required String taskerName,
    required String taskTitle,
    required String taskId,
  }) async {
    await sendNotificationToUser(
      userId: posterId,
      title: 'New Task Application',
      body: '$taskerName applied for: $taskTitle',
      type: 'task_application',
      data: {
        'taskId': taskId,
        'taskerName': taskerName,
      },
    );
  }

  // Send task status update notification
  static Future<void> sendTaskStatusNotification({
    required String userId,
    required String taskTitle,
    required String status,
    required String taskId,
  }) async {
    String body;
    switch (status) {
      case 'assigned':
        body = 'Your task "$taskTitle" has been assigned';
        break;
      case 'completed':
        body = 'Task "$taskTitle" has been completed';
        break;
      case 'cancelled':
        body = 'Task "$taskTitle" has been cancelled';
        break;
      case 'payment_received':
        body = 'Payment received for "$taskTitle"';
        break;
      default:
        body = 'Task "$taskTitle" status updated';
    }

    await sendNotificationToUser(
      userId: userId,
      title: 'Task Update',
      body: body,
      type: 'task_update',
      data: {
        'taskId': taskId,
        'status': status,
      },
    );
  }

  // Send payment notification
  static Future<void> sendPaymentNotification({
    required String userId,
    required String title,
    required String body,
    required String transactionId,
    String type = 'payment_update',
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: {
        'transactionId': transactionId,
      },
    );
  }

  // Get user notifications
  static Stream<List<Map<String, dynamic>>> getUserNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

      print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  // Get unread notifications count
  static Stream<int> getUnreadNotificationsCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Clear old notifications (older than 30 days)
  static Future<void> clearOldNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final oldNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Old notifications cleared');
    } catch (e) {
      print('❌ Error clearing old notifications: $e');
    }
  }

  // Subscribe to topic for general announcements
  static Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return; // Skip for web

    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return; // Skip for web

    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  // Subscribe to user role topics
  static Future<void> subscribeToRoleTopics(List<String> userTypes) async {
    if (kIsWeb) return;

    for (final role in userTypes) {
      await subscribeToTopic('role_$role');
    }

    // Subscribe to general announcements
    await subscribeToTopic('all_users');
  }

  // Handle app lifecycle changes
  static Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!kIsWeb) {
          await _saveDeviceToken(); // Refresh token when app resumes
        }
        // Update user online status
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'isOnline': true,
            'lastSeen': FieldValue.serverTimestamp(),
          });
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Update user offline status
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
        }
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.messageId}');

  // Initialize Firebase if needed
  await Firebase.initializeApp();

  // You can update Firestore or perform other background tasks here
  // but don't try to update UI or navigate
}
