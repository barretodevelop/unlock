// lib/services/notification_service.dart - ENHANCED VERSION
// ✅ MELHORADO: Integração com FCM + Background Service

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static bool _initialized = false;

  // ✅ Inicialização completa
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kDebugMode) {
        print('🔄 NotificationService: Inicializando...');
      }

      // 1. Inicializar notificações locais
      await _initializeLocalNotifications();

      // 2. Configurar FCM
      await _configureFCM();

      // 3. Solicitar permissões
      await _requestPermissions();

      _initialized = true;
      if (kDebugMode) {
        print('✅ NotificationService: Inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ NotificationService: Erro na inicialização: $e');
      }
    }
  }

  // ✅ Configurar notificações locais
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      // ✅ Removido: onDidReceiveLocalNotification
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (kDebugMode) {
      print('✅ NotificationService: Notificações locais configuradas');
    }
  }

  // ✅ Configurar FCM
  static Future<void> _configureFCM() async {
    // Configurar settings do FCM
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Obter token FCM
    final token = await _fcm.getToken();
    if (token != null) {
      if (kDebugMode) {
        print('✅ FCM Token: ${token.substring(0, 20)}...');
      }
      await _saveFCMToken(token);
    }

    // Listener para mudanças no token
    _fcm.onTokenRefresh.listen(_saveFCMToken);

    if (kDebugMode) {
      print('✅ NotificationService: FCM configurado');
    }
  }

  // ✅ Solicitar permissões
  static Future<void> _requestPermissions() async {
    // Permissões FCM
    final fcmSettings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('✅ FCM Permission: ${fcmSettings.authorizationStatus}');
    }

    // Permissões de notificação (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (kDebugMode) {
      print('✅ NotificationService: Permissões solicitadas');
    }
  }

  // ✅ Handler para mensagens em foreground

  // ✅ Mostrar notificação local a partir de FCM

  // ✅ Callbacks de notificações locais

  static Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    if (kDebugMode) {
      print('👆 Notificação tocada: ${response.payload}');
    }
  }

  // ✅ Helpers

  static Future<void> _saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    if (kDebugMode) {
      print('✅ FCM Token salvo');
    }

    // await _sendTokenToServer(token);
  }

  // ✅ Status e getters
  static bool get isInitialized => _initialized;

  static Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  static Future<String?> getStoredFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}

// ✅ Handler para mensagens FCM em background (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('📨 Mensagem FCM em background: ${message.messageId}');
  }

  // Processar mensagem em background se necessário
  final data = message.data;
  final type = data['type'];

  switch (type) {
    case 'pet_critical':
      // Executar verificação imediata de pets
      if (kDebugMode) {
        print('🚨 Executando verificação crítica de pets');
      }
      break;
    case 'force_check':
      // Forçar verificação manual
      if (kDebugMode) {
        print('🔄 Forçando verificação manual de pets');
      }
      break;
  }
}
