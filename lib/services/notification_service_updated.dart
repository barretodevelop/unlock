// lib/services/notification_service_updated.dart
// NotificationService expandido com sistema inteligente de notificações

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlock/core/utils/logger.dart';

/// Serviço expandido de notificações com sistema inteligente
class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Estado do serviço
  static bool _isInitialized = false;
  static String? _fcmToken;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _backgroundSubscription;

  // Controle de analytics e timing
  static int _notificationsSent = 0;
  static int _notificationsReceived = 0;
  static int _notificationsOpened = 0;
  static final Map<String, DateTime> _lastSentByType = {};
  static final Map<String, int> _sentCountByType = {};

  // Configurações inteligentes
  static const int _maxNotificationsPerDay = 5;
  static const int _minIntervalBetweenNotifications = 2; // horas
  static const String _prefsKey = 'notification_service_prefs';

  /// Inicializa o serviço completo de notificações
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('📢 Inicializando NotificationService expandido...');
      final stopwatch = Stopwatch()..start();

      // Inicialização sequencial
      await _requestPermissions();
      await _setupLocalNotifications();
      await _setupFirebaseMessaging();
      await _setupMessageHandlers();
      await _getFCMToken();
      await _loadPreferences();

      stopwatch.stop();
      _isInitialized = true;

      AppLogger.info(
        '✅ NotificationService inicializado',
        data: {
          'initTime': '${stopwatch.elapsedMilliseconds}ms',
          'hasToken': _fcmToken != null,
          'totalSentToday': _getTotalSentToday(),
        },
      );

      // Agenda limpeza diária
      _scheduleDailyCleanup();
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Falha na inicialização do NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Verifica se tem permissões
  static Future<bool> hasPermissions() async {
    final permission = await Permission.notification.status;
    final fcmSettings = await _firebaseMessaging.getNotificationSettings();

    return permission.isGranted &&
        fcmSettings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Solicita permissões
  static Future<bool> requestPermissions() async {
    try {
      AppLogger.info('📱 Solicitando permissões de notificação...');

      // Permissão do sistema
      final permission = await Permission.notification.request();

      // Permissão do Firebase
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
        '📱 Permissões de notificação',
        data: {
          'granted': hasPermission,
          'systemPermission': permission.toString(),
          'fcmPermission': fcmSettings.authorizationStatus.toString(),
        },
      );

      return hasPermission;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao solicitar permissões',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Envia notificação local inteligente
  static Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? type,
    int? id,
    bool forceShow = false,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('⚠️ NotificationService não inicializado');
      return;
    }

    try {
      // Verificações inteligentes
      if (!forceShow && !_shouldSendNotification(type)) {
        AppLogger.debug(
          '🚫 Notificação suprimida',
          data: {'type': type, 'reason': 'intelligent_throttling'},
        );
        return;
      }

      // Configuração da notificação
      final androidDetails = AndroidNotificationDetails(
        'smart_channel',
        'Notificações Inteligentes',
        channelDescription: 'Notificações personalizadas do Unlock',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
          summaryText: 'Unlock',
          htmlFormatSummaryText: false,
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );

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

      // Atualiza estatísticas
      _notificationsSent++;
      if (type != null) {
        _lastSentByType[type] = DateTime.now();
        _sentCountByType[type] = (_sentCountByType[type] ?? 0) + 1;
      }

      await _savePreferences();

      AppLogger.info(
        '📤 Notificação local enviada',
        data: {
          'id': notificationId,
          'type': type,
          'title': title,
          'totalSentToday': _getTotalSentToday(),
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao enviar notificação local',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Agenda notificação para horário específico
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledFor,
    Map<String, dynamic>? data,
    String? type,
    int? id,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('⚠️ NotificationService não inicializado');
      return;
    }

    try {
      final notificationId =
          id ?? DateTime.now().millisecondsSinceEpoch % 100000;

      await _localNotifications.zonedSchedule(
        notificationId,
        title,
        body,
        _convertToTZDateTime(scheduledFor),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scheduled_channel',
            'Notificações Agendadas',
            channelDescription: 'Notificações agendadas do Unlock',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: data != null ? jsonEncode(data) : null,
      );

      AppLogger.info(
        '⏰ Notificação agendada',
        data: {
          'id': notificationId,
          'type': type,
          'scheduledFor': scheduledFor.toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao agendar notificação',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Envia notificação de streak inteligente
  static Future<void> sendStreakReminder({
    required int currentStreak,
    required bool hasLoggedToday,
    int? nextMilestone,
    int? daysToMilestone,
  }) async {
    if (!_shouldSendNotification('streak_reminder')) return;

    String title, body;

    if (hasLoggedToday) {
      title = '🔥 Streak mantido!';
      body =
          'Você já logou hoje e manteve sua sequência de $currentStreak dias!';

      if (nextMilestone != null &&
          daysToMilestone != null &&
          daysToMilestone <= 3) {
        body +=
            ' Faltam apenas $daysToMilestone dias para alcançar $nextMilestone dias!';
      }
    } else {
      title = '⚡ Mantenha seu streak!';

      if (currentStreak == 0) {
        body = 'Que tal começar uma nova sequência de login hoje?';
      } else {
        body =
            'Não perca sua sequência de $currentStreak dias! Faça login no Unlock agora.';

        if (nextMilestone != null && daysToMilestone != null) {
          if (daysToMilestone <= 1) {
            body += ' Você está quase alcançando $nextMilestone dias!';
          } else if (daysToMilestone <= 3) {
            body +=
                ' Faltam apenas $daysToMilestone dias para $nextMilestone dias!';
          }
        }
      }
    }

    await sendLocalNotification(
      title: title,
      body: body,
      type: 'streak_reminder',
      data: {
        'type': 'streak_reminder',
        'currentStreak': currentStreak,
        'hasLoggedToday': hasLoggedToday,
        'nextMilestone': nextMilestone,
        'daysToMilestone': daysToMilestone,
        'action': 'open_app',
      },
    );
  }

  /// Envia notificação de convite para jogo
  static Future<void> sendGameInvite({
    required String fromUserId,
    required String fromUserName,
    required String gameRoomId,
    String? fromUserAvatar,
  }) async {
    final title = '🎮 Novo convite para jogar!';
    final body =
        '$fromUserName te convidou para um quiz. Aceite e descubram mais um sobre o outro!';

    await sendLocalNotification(
      title: title,
      body: body,
      type: 'game_invite',
      forceShow: true, // Convites são sempre importantes
      data: {
        'type': 'game_invite',
        'gameRoomId': gameRoomId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromUserAvatar': fromUserAvatar,
        'action': 'open_game',
      },
    );
  }

  /// Envia notificação de conexão formada
  static Future<void> sendConnectionFormed({
    required String withUserId,
    required String withUserName,
    required int revealPercentage,
    String? withUserAvatar,
  }) async {
    final title = '💕 Nova conexão formada!';
    final body =
        'Você e $withUserName se conectaram! Revelação: $revealPercentage%';

    await sendLocalNotification(
      title: title,
      body: body,
      type: 'connection_formed',
      forceShow: true,
      data: {
        'type': 'connection_formed',
        'withUserId': withUserId,
        'withUserName': withUserName,
        'revealPercentage': revealPercentage,
        'withUserAvatar': withUserAvatar,
        'action': 'open_connections',
      },
    );
  }

  /// Envia notificação de conquista desbloqueada
  static Future<void> sendAchievementUnlocked({
    required String achievementId,
    required String achievementTitle,
    required String achievementDescription,
    required int reward,
    String? achievementEmoji,
  }) async {
    final title = '🏆 Conquista desbloqueada!';
    final body =
        '${achievementEmoji ?? '⭐'} $achievementTitle - $achievementDescription (+$reward moedas)';

    await sendLocalNotification(
      title: title,
      body: body,
      type: 'achievement_unlocked',
      forceShow: true,
      data: {
        'type': 'achievement_unlocked',
        'achievementId': achievementId,
        'achievementTitle': achievementTitle,
        'reward': reward,
        'action': 'open_achievements',
      },
    );
  }

  /// Envia notificação de atividade/engajamento
  static Future<void> sendEngagementNotification() async {
    if (!_shouldSendNotification('engagement')) return;

    final messages = [
      {
        'title': '🎯 Novas descobertas te esperam!',
        'body': 'Que tal conhecer alguém novo hoje?',
      },
      {
        'title': '💫 Hora de se conectar!',
        'body': 'Seus matches estão curiosos sobre você!',
      },
      {
        'title': '🎮 Vamos jogar?',
        'body': 'Um quiz rápido pode revelar coisas incríveis!',
      },
      {
        'title': '🌟 Unlock te espera!',
        'body': 'Descubra novas conexões e ganhe recompensas!',
      },
      {
        'title': '🔍 Explore novos perfis!',
        'body': 'Talvez sua próxima conexão especial esteja esperando!',
      },
    ];

    final random = Random();
    final selectedMessage = messages[random.nextInt(messages.length)];

    await sendLocalNotification(
      title: selectedMessage['title']!,
      body: selectedMessage['body']!,
      type: 'engagement',
      data: {
        'type': 'engagement',
        'messageIndex': random.nextInt(100),
        'action': 'open_app',
      },
    );
  }

  /// Envia resumo semanal
  static Future<void> sendWeeklyDigest({
    required Map<String, dynamic> stats,
  }) async {
    final gamesPlayed = stats['gamesPlayed'] ?? 0;
    final connectionsFormed = stats['connectionsFormed'] ?? 0;
    final streakRecord = stats['streakRecord'] ?? 0;

    final title = '📊 Seu resumo semanal';
    final body =
        'Esta semana: $gamesPlayed jogos, $connectionsFormed conexões, recorde de $streakRecord dias!';

    await sendLocalNotification(
      title: title,
      body: body,
      type: 'weekly_digest',
      data: {'type': 'weekly_digest', 'stats': stats, 'action': 'open_stats'},
    );
  }

  /// Verifica se deve enviar notificação (lógica inteligente)
  static bool _shouldSendNotification(String? type) {
    if (type == null) return true;

    final now = DateTime.now();

    // Verifica limite diário
    if (_getTotalSentToday() >= _maxNotificationsPerDay) {
      AppLogger.debug('🚫 Limite diário de notificações atingido');
      return false;
    }

    // Verifica intervalo mínimo entre notificações
    final lastSent = _lastSentByType[type];
    if (lastSent != null) {
      final hoursSinceLastSent = now.difference(lastSent).inHours;
      if (hoursSinceLastSent < _minIntervalBetweenNotifications) {
        AppLogger.debug('🚫 Intervalo mínimo não atingido para $type');
        return false;
      }
    }

    // Verifica horário silencioso (22h às 8h)
    final hour = now.hour;
    if (hour >= 22 || hour <= 8) {
      // Exceções para notificações urgentes
      final urgentTypes = [
        'game_invite',
        'connection_formed',
        'achievement_unlocked',
      ];
      if (!urgentTypes.contains(type)) {
        AppLogger.debug('🚫 Horário silencioso para $type');
        return false;
      }
    }

    // Limite específico por tipo
    final sentToday = _getSentTodayByType(type);
    final maxByType = _getMaxDailyByType(type);
    if (sentToday >= maxByType) {
      AppLogger.debug('🚫 Limite diário por tipo atingido para $type');
      return false;
    }

    return true;
  }

  /// Retorna total de notificações enviadas hoje
  static int _getTotalSentToday() {
    final today = DateTime.now();
    return _sentCountByType.entries
        .where((entry) {
          final lastSent = _lastSentByType[entry.key];
          return lastSent != null && _isSameDay(lastSent, today);
        })
        .fold(0, (sum, entry) => sum + entry.value);
  }

  /// Retorna notificações enviadas hoje por tipo
  static int _getSentTodayByType(String type) {
    final lastSent = _lastSentByType[type];
    final today = DateTime.now();

    if (lastSent == null || !_isSameDay(lastSent, today)) {
      return 0;
    }

    return _sentCountByType[type] ?? 0;
  }

  /// Retorna limite máximo diário por tipo
  static int _getMaxDailyByType(String type) {
    switch (type) {
      case 'streak_reminder':
        return 1;
      case 'game_invite':
        return 5;
      case 'connection_formed':
        return 3;
      case 'achievement_unlocked':
        return 3;
      case 'engagement':
        return 1;
      case 'weekly_digest':
        return 1;
      default:
        return 2;
    }
  }

  /// Verifica se duas datas são do mesmo dia
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Agenda limpeza diária dos contadores
  static void _scheduleDailyCleanup() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      final now = DateTime.now();

      // Limpeza à meia-noite
      if (now.hour == 0 && now.minute < 5) {
        _resetDailyCounters();
      }
    });
  }

  /// Reseta contadores diários
  static void _resetDailyCounters() {
    _sentCountByType.clear();
    _savePreferences();
    AppLogger.info('🧹 Contadores diários resetados');
  }

  // Métodos privados de configuração
  static Future<void> _requestPermissions() async {
    // Implementação já incluída no método público requestPermissions()
  }

  static Future<void> _setupLocalNotifications() async {
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

    // Criar canais de notificação no Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  static Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'smart_channel',
        'Notificações Inteligentes',
        description: 'Notificações personalizadas e inteligentes',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'scheduled_channel',
        'Notificações Agendadas',
        description: 'Notificações agendadas para horários específicos',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'urgent_channel',
        'Notificações Urgentes',
        description: 'Convites de jogos e conexões importantes',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<void> _setupFirebaseMessaging() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _setupMessageHandlers() async {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _onForegroundMessage,
    );
    _backgroundSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _onBackgroundMessageOpened,
    );

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _onAppOpenedFromNotification(initialMessage);
    }
  }

  static Future<void> _getFCMToken() async {
    _fcmToken = await _firebaseMessaging.getToken();
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      AppLogger.info('🔄 FCM Token atualizado');
    });
  }

  // Handlers de eventos
  static void _onForegroundMessage(RemoteMessage message) {
    _notificationsReceived++;
    AppLogger.info(
      '📥 Mensagem recebida (foreground)',
      data: {
        'messageId': message.messageId,
        'title': message.notification?.title,
      },
    );

    _showLocalNotification(message);
  }

  static void _onBackgroundMessageOpened(RemoteMessage message) {
    _notificationsOpened++;
    AppLogger.info(
      '📱 Notificação aberta (background)',
      data: {'messageId': message.messageId},
    );

    _processNotificationAction(message);
  }

  static void _onAppOpenedFromNotification(RemoteMessage message) {
    _notificationsOpened++;
    AppLogger.info(
      '📱 App aberto via notificação',
      data: {'messageId': message.messageId},
    );

    _processNotificationAction(message);
  }

  static void _onLocalNotificationTapped(NotificationResponse response) {
    _notificationsOpened++;
    AppLogger.info(
      '📱 Notificação local tocada',
      data: {'id': response.id, 'hasPayload': response.payload != null},
    );

    if (response.payload != null) {
      _processLocalNotificationPayload(response.payload!);
    }
  }

  // Métodos auxiliares
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await sendLocalNotification(
      title: notification.title ?? 'Unlock',
      body: notification.body ?? '',
      data: message.data,
      type: message.data['type'],
      forceShow: true,
    );
  }

  static void _processNotificationAction(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  static void _processLocalNotificationPayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleNotificationData(data);
    } catch (e) {
      AppLogger.error('❌ Erro ao processar payload local', error: e);
    }
  }

  static void _handleNotificationData(Map<String, dynamic> data) {
    final action = data['action'] as String?;

    // Aqui você implementaria a navegação baseada nos dados
    // Por exemplo, usando GoRouter ou Navigator

    AppLogger.info(
      '🎯 Processando ação de notificação',
      data: {'action': action, 'type': data['type']},
    );

    // TODO: Implementar navegação específica baseada no action
    // Exemplos:
    // - 'open_game' -> navegar para sala de jogo
    // - 'open_connections' -> navegar para lista de conexões
    // - 'open_achievements' -> navegar para conquistas
    // - 'open_app' -> apenas abrir o app (home)
  }

  static dynamic _convertToTZDateTime(DateTime dateTime) {
    // Implementação simplificada - em produção, usar timezone package
    return dateTime;
  }

  // Persistência de preferências
  static Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_prefsKey);

      if (prefsJson != null) {
        final data = jsonDecode(prefsJson) as Map<String, dynamic>;

        // Carrega estatísticas (apenas do dia atual)
        final savedDate = data['date'] as String?;
        final today = DateTime.now().toIso8601String().substring(0, 10);

        if (savedDate == today) {
          _notificationsSent = data['notificationsSent'] ?? 0;
          _sentCountByType.clear();
          _sentCountByType.addAll(
            Map<String, int>.from(data['sentCountByType'] ?? {}),
          );

          // Reconstrói _lastSentByType para hoje
          final lastSentData =
              data['lastSentByType'] as Map<String, dynamic>? ?? {};
          _lastSentByType.clear();
          lastSentData.forEach((key, value) {
            _lastSentByType[key] = DateTime.parse(value);
          });
        }
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao carregar preferências', error: e);
    }
  }

  static Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final data = {
        'date': today,
        'notificationsSent': _notificationsSent,
        'sentCountByType': _sentCountByType,
        'lastSentByType': _lastSentByType.map(
          (key, value) => MapEntry(key, value.toIso8601String()),
        ),
      };

      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (e) {
      AppLogger.error('❌ Erro ao salvar preferências', error: e);
    }
  }

  // Métodos públicos de utilidade
  static String? get fcmToken => _fcmToken;
  static bool get isInitialized => _isInitialized;

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
      'sentToday': _getTotalSentToday(),
      'maxDaily': _maxNotificationsPerDay,
      'remainingToday': _maxNotificationsPerDay - _getTotalSentToday(),
      'sentByType': _sentCountByType,
      'lastSentByType': _lastSentByType.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  static Future<void> getFCMToken() async {
    return _fcmToken;
  }

  // Handler para mensagens em background (função de nível superior)
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    AppLogger.info(
      '📥 Mensagem background processada',
      data: {
        'messageId': message.messageId,
        'title': message.notification?.title,
      },
    );
  }

  /// Força refresh do token FCM
  static Future<void> refreshFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = await _firebaseMessaging.getToken();
      AppLogger.info('🔄 FCM Token renovado');
    } catch (e) {
      AppLogger.error('❌ Erro ao renovar FCM token', error: e);
    }
  }

  /// Cleanup manual dos recursos
  static Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _backgroundSubscription?.cancel();
    await _savePreferences();
    _isInitialized = false;
    AppLogger.info('🧹 NotificationService disposed');
  }
}
