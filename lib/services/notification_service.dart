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
  static bool _notificationsEnabled = true; // Estado padrão

  // ✅ Inicialização completa
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kDebugMode) {
        print('🔄 NotificationService: Inicializando...');
      }

      // Carregar preferência de notificações
      await _loadNotificationPreference();

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

    // ✅ NOVO: Listener para mensagens FCM em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode)
        print('📨 Mensagem FCM em foreground: ${message.messageId}');
      _showLocalNotificationFromFCM(message);
    });

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

  // ✅ NOVO: Mostrar notificação local a partir de uma mensagem FCM
  static Future<void> _showLocalNotificationFromFCM(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      // Simplesmente para o exemplo, ajuste conforme sua estrutura de FCM
      await showSimpleLocalNotification(
        title: notification.title ?? 'Nova Mensagem',
        body: notification.body ?? 'Você recebeu uma nova mensagem.',
        payload:
            message.data['payload']?.toString() ??
            message.messageId, // Exemplo de payload
      );
    } else if (notification != null) {
      // Fallback se não houver detalhes específicos do Android
      await showSimpleLocalNotification(
        title: notification.title ?? 'Nova Mensagem',
        body: notification.body ?? 'Você recebeu uma nova mensagem.',
        payload: message.data['payload']?.toString() ?? message.messageId,
      );
    }
  }

  // ✅ NOVO: Método público para mostrar uma notificação local simples
  static Future<void> showSimpleLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsEnabled) return; // Não mostra se desabilitado

    const androidDetails = AndroidNotificationDetails(
      'unlock_channel_id', // ID do canal
      'Unlock Notificações', // Nome do canal
      channelDescription: 'Canal principal para notificações do app Unlock.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher', // Certifique-se que este ícone existe
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    if (kDebugMode) print('🔔 Notificação local simples exibida: $title');
  }

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

  static Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    if (kDebugMode)
      print('🔔 Preferência de Notificação Carregada: $_notificationsEnabled');
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    if (kDebugMode)
      print('🔔 Preferência de Notificação Salva: $_notificationsEnabled');
  }

  static bool get notificationsEnabled => _notificationsEnabled;

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
    case 'Unlock_critical':
      // Executar verificação imediata de Unlocks
      if (kDebugMode) {
        print('🚨 Executando verificação crítica de Unlocks');
      }
      break;
    case 'force_check':
      // Forçar verificação manual
      if (kDebugMode) {
        print('🔄 Forçando verificação manual de Unlocks');
      }
      break;
  }
}
