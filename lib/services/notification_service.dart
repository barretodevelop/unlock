// lib/services/notification_service.dart - Com Analytics Integrado
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

/// Serviço de notificações com analytics integrado
///
/// Gerencia notificações push (Firebase) e locais, com tracking completo
/// de métricas de engajamento e performance.
class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static String? _fcmToken;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _backgroundSubscription;

  // Controle de analytics
  static int _notificationsSent = 0;
  static int _notificationsReceived = 0;
  static int _notificationsOpened = 0;
  static final Map<String, DateTime> _notificationTimestamps = {};

  /// Inicializar serviço de notificações
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('📢 Inicializando Notification Service...');

      // Rastrear tempo de inicialização
      final stopwatch = Stopwatch()..start();

      // Solicitar permissões
      await _requestPermissions();

      // Configurar notificações locais
      await _setupLocalNotifications();

      // Configurar Firebase Messaging
      await _setupFirebaseMessaging();

      // Configurar handlers de background/foreground
      await _setupMessageHandlers();

      // Obter token FCM
      await _getFCMToken();

      stopwatch.stop();

      _isInitialized = true;

      AppLogger.info(
        '✅ Notification Service inicializado',
        data: {
          'initTime': '${stopwatch.elapsedMilliseconds}ms',
          'fcmToken': _fcmToken!.substring(0, 10) + '...',
        },
      );

      // Analytics: Serviço inicializado
      await _trackEvent('notification_service_initialized', {
        'init_time_ms': stopwatch.elapsedMilliseconds,
        'has_fcm_token': _fcmToken != null,
        'platform': Platform.operatingSystem,
      });
    } catch (e) {
      AppLogger.error('❌ Erro ao inicializar Notification Service: $e');

      // Analytics: Erro na inicialização
      await _trackEvent('notification_service_init_failed', {
        'error': e.toString(),
        'platform': Platform.operatingSystem,
      });

      rethrow;
    }
  }

  /// Solicitar permissões de notificação
  static Future<bool> _requestPermissions() async {
    try {
      AppLogger.debug('📢 Solicitando permissões de notificação...');

      // Permissão do sistema
      final permission = await Permission.notification.request();

      // Permissão do Firebase (iOS)
      final fcmSettings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      final hasPermission =
          permission.isGranted &&
          fcmSettings.authorizationStatus == AuthorizationStatus.authorized;

      AppLogger.info(
        '📢 Permissões de notificação',
        data: {
          'systemPermission': permission.toString(),
          'fcmPermission': fcmSettings.authorizationStatus.toString(),
          'hasPermission': hasPermission,
        },
      );

      // Analytics: Status de permissão
      await _trackEvent('notification_permission_requested', {
        'granted': hasPermission,
        'system_permission': permission.toString(),
        'fcm_permission': fcmSettings.authorizationStatus.toString(),
      });

      return hasPermission;
    } catch (e) {
      AppLogger.error('❌ Erro ao solicitar permissões: $e');

      await _trackEvent('notification_permission_error', {
        'error': e.toString(),
      });

      return false;
    }
  }

  /// Configurar notificações locais
  static Future<void> _setupLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      );

      AppLogger.debug('✅ Notificações locais configuradas');
    } catch (e) {
      AppLogger.error('❌ Erro ao configurar notificações locais: $e');
      rethrow;
    }
  }

  /// Configurar Firebase Messaging
  static Future<void> _setupFirebaseMessaging() async {
    try {
      // Configurar para receber mensagens quando app está em foreground
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      AppLogger.debug('✅ Firebase Messaging configurado');
    } catch (e) {
      AppLogger.error('❌ Erro ao configurar Firebase Messaging: $e');
      rethrow;
    }
  }

  /// Configurar handlers de mensagens
  static Future<void> _setupMessageHandlers() async {
    try {
      // Handler para quando app está em foreground
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _onForegroundMessage,
      );

      // Handler para quando usuário toca na notificação (app em background)
      _backgroundSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _onBackgroundMessageOpened,
      );

      // Handler para quando app é aberto por notificação (app morto)
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _onAppOpenedFromNotification(initialMessage);
      }

      AppLogger.debug('✅ Message handlers configurados');
    } catch (e) {
      AppLogger.error('❌ Erro ao configurar message handlers: $e');
      rethrow;
    }
  }

  /// Obter token FCM
  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        AppLogger.info(
          '📢 FCM Token obtido',
          data: {'tokenPrefix': _fcmToken!.substring(0, 10)},
        );

        // Analytics: Token obtido
        await _trackEvent('fcm_token_obtained', {
          'token_length': _fcmToken!.length,
        });
      }

      // Escutar mudanças no token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        AppLogger.info('📢 FCM Token atualizado');

        _trackEvent('fcm_token_refreshed', {'token_length': newToken.length});
      });
    } catch (e) {
      AppLogger.error('❌ Erro ao obter FCM token: $e');
    }
  }

  /// Handler para mensagens em foreground
  static void _onForegroundMessage(RemoteMessage message) {
    AppLogger.info(
      '📢 Mensagem recebida (foreground)',
      data: {
        'messageId': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      },
    );

    _notificationsReceived++;

    // Analytics: Notificação recebida
    _trackEvent('notification_received', {
      'type': 'foreground',
      'has_notification': message.notification != null,
      'has_data': message.data.isNotEmpty,
      'message_id': message.messageId,
    });

    // Mostrar notificação local se necessário
    _showLocalNotification(message);
  }

  /// Handler para quando usuário toca notificação (background)
  static void _onBackgroundMessageOpened(RemoteMessage message) {
    AppLogger.info(
      '📢 Notificação aberta (background)',
      data: {'messageId': message.messageId, 'data': message.data},
    );

    _notificationsOpened++;

    // Analytics: Notificação aberta
    _trackEvent('notification_opened', {
      'type': 'background',
      'message_id': message.messageId,
      'has_data': message.data.isNotEmpty,
    });

    // Processar ação da notificação
    _processNotificationAction(message);
  }

  /// Handler para quando app é aberto por notificação (app morto)
  static void _onAppOpenedFromNotification(RemoteMessage message) {
    AppLogger.info(
      '📢 App aberto por notificação',
      data: {'messageId': message.messageId, 'data': message.data},
    );

    _notificationsOpened++;

    // Analytics: App aberto por notificação
    _trackEvent('app_opened_from_notification', {
      'message_id': message.messageId,
      'has_data': message.data.isNotEmpty,
    });

    // Processar ação da notificação
    _processNotificationAction(message);
  }

  /// Handler para notificações locais
  static void _onLocalNotificationTapped(NotificationResponse response) {
    AppLogger.info(
      '📢 Notificação local tocada',
      data: {'id': response.id, 'payload': response.payload},
    );

    _notificationsOpened++;

    // Analytics: Notificação local aberta
    _trackEvent('local_notification_opened', {
      'notification_id': response.id,
      'has_payload': response.payload != null,
    });

    // Processar payload se existir
    if (response.payload != null) {
      _processLocalNotificationPayload(response.payload!);
    }
  }

  /// Mostrar notificação local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Notificações',
        channelDescription: 'Canal principal de notificações',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        details,
        payload: jsonEncode(message.data),
      );

      _notificationsSent++;

      AppLogger.debug('📢 Notificação local mostrada');

      // Analytics: Notificação local mostrada
      await _trackEvent('local_notification_shown', {
        'title_length': notification.title?.length ?? 0,
        'body_length': notification.body?.length ?? 0,
        'has_data': message.data.isNotEmpty,
      });
    } catch (e) {
      AppLogger.error('❌ Erro ao mostrar notificação local: $e');

      await _trackEvent('local_notification_error', {'error': e.toString()});
    }
  }

  /// Processar ação da notificação
  static void _processNotificationAction(RemoteMessage message) {
    final data = message.data;

    if (data.isEmpty) return;

    AppLogger.debug('📢 Processando ação da notificação', data: data);

    // Analytics: Ação processada
    _trackEvent('notification_action_processed', {
      'action_type': data['type'] ?? 'unknown',
      'has_screen': data.containsKey('screen'),
      'has_data': data.containsKey('data'),
    });

    // TODO: Implementar navegação baseada nos dados
    // Por exemplo:
    // if (data['screen'] == 'profile') {
    //   NavigationService.navigateToProfile(data['userId']);
    // }
  }

  /// Processar payload de notificação local
  static void _processLocalNotificationPayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      AppLogger.debug('📢 Processando payload local', data: data);

      // Analytics: Payload processado
      _trackEvent('local_notification_payload_processed', {
        'payload_keys': data.keys.toList(),
      });

      // TODO: Implementar lógica baseada no payload
    } catch (e) {
      AppLogger.error('❌ Erro ao processar payload: $e');
    }
  }

  // ========== MÉTODOS PÚBLICOS ==========

  /// Enviar notificação local
  static Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('⚠️ NotificationService não inicializado');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'local_channel',
        'Notificações Locais',
        channelDescription: 'Notificações geradas pelo app',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId =
          id ?? DateTime.now().millisecondsSinceEpoch % 100000;

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: data != null ? jsonEncode(data) : null,
      );

      _notificationsSent++;

      AppLogger.info(
        '📢 Notificação local enviada',
        data: {'id': notificationId, 'title': title, 'hasData': data != null},
      );

      // Analytics: Notificação local enviada
      await _trackEvent('local_notification_sent', {
        'title_length': title.length,
        'body_length': body.length,
        'has_data': data != null,
        'data_keys_count': data?.keys.length ?? 0,
      });
    } catch (e) {
      AppLogger.error('❌ Erro ao enviar notificação local: $e');

      await _trackEvent('local_notification_send_error', {
        'error': e.toString(),
      });
    }
  }

  /// Cancelar notificação local
  static Future<void> cancelLocalNotification(int id) async {
    try {
      await _localNotifications.cancel(id);

      AppLogger.debug('📢 Notificação local cancelada: $id');

      await _trackEvent('local_notification_cancelled', {
        'notification_id': id,
      });
    } catch (e) {
      AppLogger.error('❌ Erro ao cancelar notificação: $e');
    }
  }

  /// Cancelar todas as notificações locais
  static Future<void> cancelAllLocalNotifications() async {
    try {
      await _localNotifications.cancelAll();

      AppLogger.debug('📢 Todas as notificações locais canceladas');

      await _trackEvent('all_local_notifications_cancelled');
    } catch (e) {
      AppLogger.error('❌ Erro ao cancelar todas as notificações: $e');
    }
  }

  /// Obter token FCM
  static String? get fcmToken => _fcmToken;

  /// Verificar se está inicializado
  static bool get isInitialized => _isInitialized;

  /// Obter estatísticas
  static Map<String, dynamic> getStats() {
    return {
      'isInitialized': _isInitialized,
      'fcmToken': _fcmToken?.substring(0, 10),
      'notificationsSent': _notificationsSent,
      'notificationsReceived': _notificationsReceived,
      'notificationsOpened': _notificationsOpened,
      'openRate': _notificationsReceived > 0
          ? (_notificationsOpened / _notificationsReceived * 100)
                    .toStringAsFixed(1) +
                '%'
          : '0%',
    };
  }

  // ========== ANALYTICS HELPERS ==========

  /// Enviar evento para analytics
  static Future<void> _trackEvent(
    String eventName, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          'notification_$eventName',
          parameters: {'service': 'notification', ...?data},
          category: EventCategory.system,
        );
      }
    } catch (e) {
      AppLogger.debug('Erro ao enviar analytics de notificação: $e');
    }
  }

  /// Gerar relatório de engajamento
  static Map<String, dynamic> getEngagementReport() {
    final openRate = _notificationsReceived > 0
        ? _notificationsOpened / _notificationsReceived
        : 0.0;

    return {
      'total_sent': _notificationsSent,
      'total_received': _notificationsReceived,
      'total_opened': _notificationsOpened,
      'open_rate': openRate,
      'open_rate_percentage': '${(openRate * 100).toStringAsFixed(1)}%',
      'engagement_level': _getEngagementLevel(openRate),
    };
  }

  static String _getEngagementLevel(double openRate) {
    if (openRate >= 0.5) return 'high';
    if (openRate >= 0.25) return 'medium';
    return 'low';
  }

  // ========== DISPOSE ==========

  /// Limpar recursos
  static Future<void> dispose() async {
    AppLogger.info('🧹 Fazendo dispose do Notification Service');

    await _foregroundSubscription?.cancel();
    await _backgroundSubscription?.cancel();

    _notificationTimestamps.clear();
    _isInitialized = false;

    await _trackEvent('service_disposed');
  }
}
