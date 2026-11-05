import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../router/app_router.dart';
import 'auth_api_service.dart';
import 'notification_api_service.dart';

/// Top-level background message handler for FCM (Android & iOS)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('FCM Background message received: ${message.messageId}');
  } catch (e) {
    debugPrint('Error handling FCM background message: $e');
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'fdp_order_updates',
    'FDP Order & Delivery Updates',
    description:
        'Notifications regarding your active orders, delivery tracking, and exclusive discounts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static bool _isInitialized = false;
  static Future<void>? _initFuture;

  /// Initializes Firebase and Push Notification Listeners safely.
  /// If called multiple times or concurrently, reuses the in-flight initialization.
  static Future<void> initialize() {
    _initFuture ??= _doInitialize();
    return _initFuture!;
  }

  static Future<void> _doInitialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase Core with DefaultFirebaseOptions
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      debugPrint(
        'Firebase Core initialized successfully with DefaultFirebaseOptions (${Firebase.app().name}).',
      );

      // 2. Register background handler on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler,
          );
        } catch (e) {
          debugPrint('Notice registering background handler: $e');
        }
      }

      // 3. Initialize Flutter Local Notifications for foreground banners
      try {
        const androidInit =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosInit = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

        const initSettings = InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        );

        await _localNotifications.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (response) {
            if (response.payload != null && response.payload!.isNotEmpty) {
              try {
                final data =
                    jsonDecode(response.payload!) as Map<String, dynamic>;
                _handleNotificationPayload(data);
              } catch (e) {
                debugPrint('Error parsing notification payload: $e');
              }
            }
          },
        );

        if (!kIsWeb && Platform.isAndroid) {
          final androidPlugin = _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          if (androidPlugin != null) {
            await androidPlugin.createNotificationChannel(_defaultChannel);
          }
        }
      } catch (e) {
        debugPrint('Local notifications init notice: $e');
      }

      // 4. Request notification permissions (Android 13+ & iOS)
      try {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        debugPrint(
          'FCM Notification permission status: ${settings.authorizationStatus}',
        );

        // Enable foreground display options on iOS safely
        if (!kIsWeb && Platform.isIOS) {
          try {
            await messaging.setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            ).timeout(const Duration(seconds: 2));
          } catch (_) {}
        }

        // 5. Handle Foreground Messages (show heads-up banner)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint(
            'FCM Foreground Message received: ${message.notification?.title}',
          );
          _showForegroundNotification(message);
        });

        // 6. Handle notification click when app is opened from background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('FCM Notification tapped from background: ${message.data}');
          _handleNotificationPayload(message.data);
        });

        // 7. Check if app was launched from terminated state via notification click
        try {
          final initialMessage = await messaging.getInitialMessage().timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
          if (initialMessage != null) {
            debugPrint(
              'App launched from terminated state via FCM: ${initialMessage.data}',
            );
            _handleNotificationPayload(initialMessage.data);
          }
        } catch (_) {}

        // 8. Listen for token refreshes
        messaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token refreshed: $newToken');
          syncTokenWithBackend(newToken);
        });
      } catch (e) {
        debugPrint('FCM Messaging setup notice: $e');
      }

      _isInitialized = true;

      // Sync token with backend if user is already logged in
      if (authApiService.hasSession) {
        await syncTokenWithBackend();
      }
    } catch (e, stack) {
      debugPrint('PushNotificationService initialization notice: $e\n$stack');
    }
  }

  /// Displays foreground banner using flutter_local_notifications
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _defaultChannel.id,
      _defaultChannel.name,
      channelDescription: _defaultChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title ?? 'FDP Update',
      body: notification.body ?? '',
      notificationDetails: platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Deep link router based on notification data payload
  static void _handleNotificationPayload(Map<String, dynamic> data) {
    final String? orderId = data['orderId']?.toString();
    final String? route = data['route']?.toString();
    final String? type = data['type']?.toString();

    if (orderId != null && orderId.isNotEmpty) {
      if (type == 'DELIVERED') {
        appRouter.push('/order-delivered/$orderId');
      } else {
        appRouter.push('/order-tracking/$orderId');
      }
    } else if (route != null && route.isNotEmpty) {
      appRouter.push(route);
    } else {
      appRouter.push('/notifications');
    }
  }

  /// Safely retrieves the device FCM token without hanging on iOS Simulator
  static Future<String?> getToken() async {
    try {
      if (Firebase.apps.isEmpty) return null;
      if (!kIsWeb && Platform.isIOS) {
        // On iOS, an APNs token must exist before getToken() can succeed
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken().timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
        if (apnsToken == null && !kReleaseMode) {
          debugPrint('Notice: APNs token not yet available on this iOS device/simulator.');
          return null;
        }
      }
      return await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('Notice fetching FCM token: $e');
      return null;
    }
  }

  /// Obtains the current device FCM token and syncs it with the backend API
  /// POST /notifications/device-token
  static Future<void> syncTokenWithBackend([String? tokenOverride]) async {
    try {
      // Ensure initialization has finished before attempting to get token
      if (!_isInitialized) {
        await initialize();
      }

      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase not available on this platform. Skipping token sync.');
        return;
      }

      final token = tokenOverride ?? await getToken();
      if (token == null || token.isEmpty) return;

      final detectedPlatform = Platform.isIOS
          ? 'IOS'
          : Platform.isAndroid
              ? 'ANDROID'
              : 'WEB';

      await notificationApiService.registerDeviceToken(
        token: token,
        platform: detectedPlatform,
      );
      debugPrint('FCM Token successfully registered with backend: $token');
    } catch (e) {
      debugPrint('Notice during FCM syncTokenWithBackend: $e');
    }
  }

  /// Unregisters FCM token on customer logout
  /// DELETE /notifications/device-token
  static Future<void> unregisterOnLogout() async {
    try {
      if (Firebase.apps.isEmpty) return;

      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        await notificationApiService.unregisterDeviceToken(token);
        try {
          await FirebaseMessaging.instance.deleteToken().timeout(
            const Duration(seconds: 2),
          );
        } catch (_) {}
        debugPrint('FCM Token unregistered and deleted on logout.');
      }
    } catch (e) {
      debugPrint('Notice during FCM unregisterOnLogout: $e');
    }
  }
}
