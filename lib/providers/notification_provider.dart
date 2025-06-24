// lib/providers/notification_provider.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/streak_provider.dart';
import 'package:unlock/services/notification_service.dart';

/// Provider para gerenciar notificações inteligentes
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final authState = ref.watch(authProvider);
  return NotificationNotifier(
    userId: authState.user?.uid,
    ref: ref,
  );
});

/// Provider para configurações de notificação
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

/// Estado das notificações
class NotificationState {
  final bool isInitialized;
  final bool permissionsGranted;
  final String? fcmToken;
  final List<ScheduledNotification> scheduledNotifications;
  final Map<String, DateTime> lastSent; // tipo -> quando foi enviado pela última vez
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.isInitialized = false,
    this.permissionsGranted = false,
    this.fcmToken,
    this.scheduledNotifications = const [],
    this.lastSent = const {},
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    bool? isInitialized,
    bool? permissionsGranted,
    String? fcmToken,
    List<ScheduledNotification>? scheduledNotifications,
    Map<String, DateTime>? lastSent,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      fcmToken: fcmToken ?? this.fcmToken,
      scheduledNotifications: scheduledNotifications ?? this.scheduledNotifications,
      lastSent: lastSent ?? this.lastSent,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Configurações de notificação do usuário
class NotificationSettings {
  final bool enabled;
  final bool streakReminders;
  final bool gameInvites;
  final bool connectionUpdates;
  final bool weeklyDigest;
  final bool achievementUnlocks;
  final String preferredTime; // HH:mm format
  final List<int> quietDays; // 0-6, domingo a sábado
  final TimeRange quietHours;

  const NotificationSettings({
    this.enabled = true,
    this.streakReminders = true,
    this.gameInvites = true,
    this.connectionUpdates = true,
    this.weeklyDigest = true,
    this.achievementUnlocks = true,
    this.preferredTime = '20:00',
    this.quietDays = const [],
    this.quietHours = const TimeRange(start: '22:00', end: '08:00'),
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? streakReminders,
    bool? gameInvites,
    bool? connectionUpdates,
    bool? weeklyDigest,
    bool? achievementUnlocks,
    String? preferredTime,
    List<int>? quietDays,
    TimeRange? quietHours,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      streakReminders: streakReminders ?? this.streakReminders,
      gameInvites: gameInvites ?? this.gameInvites,
      connectionUpdates: connectionUpdates ?? this.connectionUpdates,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
      achievementUnlocks: achievementUnlocks ?? this.achievementUnlocks,
      preferredTime: preferredTime ?? this.preferredTime,
      quietDays: quietDays ?? this.quietDays,
      quietHours: quietHours ?? this.quietHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'streakReminders': streakReminders,
      'gameInvites': gameInvites,
      'connectionUpdates': connectionUpdates,
      'weeklyDigest': weeklyDigest,
      'achievementUnlocks': achievementUnlocks,
      'preferredTime': preferredTime,
      'quietDays': quietDays,
      'quietHours': quietHours.toJson(),
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      streakReminders: json['streakReminders'] ?? true,
      gameInvites: json['gameInvites'] ?? true,
      connectionUpdates: json['connectionUpdates'] ?? true,
      weeklyDigest: json['weeklyDigest'] ?? true,
      achievementUnlocks: json['achievementUnlocks'] ?? true,
      preferredTime: json['preferredTime'] ?? '20:00',
      quietDays: List<int>.from(json['quietDays'] ?? []),
      quietHours: TimeRange.fromJson(json['quietHours'] ?? {}),
    );
  }
}

/// Representa um período de tempo
class TimeRange {
  final String start; // HH:mm
  final String end;   // HH:mm

  const TimeRange({required this.start, required this.end});

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      start: json['start'] ?? '22:00',
      end: json['end'] ?? '08:00',
    );
  }

  /// Verifica se um horário está dentro do período
  bool contains(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final currentTime = hour * 60 + minute; // minutos desde meia-noite

    final startParts = start.split(':');
    final endParts = end.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    if (startMinutes <= endMinutes) {
      // Mesmo dia (ex: 08:00 - 22:00)
      return currentTime >= startMinutes && currentTime <= endMinutes;
    } else {
      // Atravessa meia-noite (ex: 22:00 - 08:00)
      return currentTime >= startMinutes || currentTime <= endMinutes;
    }
  }
}

/// Notificação agendada
class ScheduledNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime scheduledFor;
  final Map<String, dynamic> data;
  final bool sent;

  const ScheduledNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledFor,
    this.data = const {},
    this.sent = false,
  });

  ScheduledNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    DateTime? scheduledFor,
    Map<String, dynamic>? data,
    bool? sent,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      data: data ?? this.data,
      sent: sent ?? this.sent,
    );
  }
}

/// Notifier principal de notificações
class NotificationNotifier extends StateNotifier<NotificationState> {
  final String? _userId;
  final Ref _ref;
  Timer? _checkTimer;
  Timer? _scheduleTimer;

  NotificationNotifier({
    required String? userId,
    required Ref ref,
  })  : _userId = userId,
        _ref = ref,
        super(const NotificationState()) {
    if (_userId != null) {
      _initialize();
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _scheduleTimer?.cancel();
    super.dispose();
  }

  /// Inicializa o sistema de notificações
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);

      // Inicializa NotificationService
      await NotificationService.initialize();
      
      // Verifica permissões
      final hasPermissions = await NotificationService.hasPermissions();
      
      // Obtém FCM token se tem permissões
      String? fcmToken;
      if (hasPermissions) {
        fcmToken = await NotificationService.getFCMToken();
      }

      state = state.copyWith(
        isInitialized: true,
        permissionsGranted: hasPermissions,
        fcmToken: fcmToken,
        isLoading: false,
      );

      // Agenda verificações periódicas
      _startPeriodicChecks();
      
      // Agenda notificações inteligentes
      await _scheduleIntelligentNotifications();

      AppLogger.info('📱 Notification system initialized', data: {
        'userId': _userId,
        'hasPermissions': hasPermissions,
        'fcmToken': fcmToken != null ? 'present' : 'missing',
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to initialize notifications', 
        error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao inicializar notificações',
      );
    }
  }

  /// Inicia verificações periódicas
  void _startPeriodicChecks() {
    _checkTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _checkScheduledNotifications();
    });

    // Reagenda notificações a cada 6 horas
    _scheduleTimer = Timer.periodic(const Duration(hours: 6), (_) {
      _scheduleIntelligentNotifications();
    });
  }

  /// Verifica e envia notificações agendadas
  Future<void> _checkScheduledNotifications() async {
    final now = DateTime.now();
    final settings = _ref.read(notificationSettingsProvider);

    if (!settings.enabled) return;

    final toSend = state.scheduledNotifications.where((notification) {
      return !notification.sent && 
             notification.scheduledFor.isBefore(now) &&
             _shouldSendNotification(notification, settings, now);
    }).toList();

    for (final notification in toSend) {
      await _sendNotification(notification);
    }
  }

  /// Verifica se deve enviar uma notificação baseado nas configurações
  bool _shouldSendNotification(
    ScheduledNotification notification,
    NotificationSettings settings,
    DateTime now,
  ) {
    // Verifica dia quieto
    if (settings.quietDays.contains(now.weekday % 7)) {
      return false;
    }

    // Verifica horário quieto
    if (settings.quietHours.contains(now)) {
      return false;
    }

    // Verifica configurações específicas do tipo
    switch (notification.type) {
      case 'streak_reminder':
        return settings.streakReminders;
      case 'game_invite':
        return settings.gameInvites;
      case 'connection_update':
        return settings.connectionUpdates;
      case 'weekly_digest':
        return settings.weeklyDigest;
      case 'achievement_unlock':
        return settings.achievementUnlocks;
      default:
        return true;
    }
  }

  /// Envia uma notificação
  Future<void> _sendNotification(ScheduledNotification notification) async {
    try {
      await NotificationService.sendLocalNotification(
        title: notification.title,
        body: notification.body,
        data: notification.data,
      );

      // Marca como enviada
      final updatedNotifications = state.scheduledNotifications.map((n) {
        return n.id == notification.id ? n.copyWith(sent: true) : n;
      }).toList();

      // Atualiza última vez enviada para este tipo
      final updatedLastSent = Map<String, DateTime>.from(state.lastSent);
      updatedLastSent[notification.type] = DateTime.now();

      state = state.copyWith(
        scheduledNotifications: updatedNotifications,
        lastSent: updatedLastSent,
      );

      AppLogger.info('📤 Notification sent', data: {
        'type': notification.type,
        'title': notification.title,
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to send notification', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Agenda notificações inteligentes baseadas no comportamento do usuário
  Future<void> _scheduleIntelligentNotifications() async {
    try {
      final settings = _ref.read(notificationSettingsProvider);
      if (!settings.enabled) return;

      final now = DateTime.now();
      final scheduledNotifications = <ScheduledNotification>[];

      // ✅ Lembrete de streak
      if (settings.streakReminders) {
        await _scheduleStreakReminders(scheduledNotifications, settings, now);
      }

      // ✅ Digest semanal
      if (settings.weeklyDigest) {
        await _scheduleWeeklyDigest(scheduledNotifications, settings, now);
      }

      // ✅ Lembretes de atividade
      await _scheduleActivityReminders(scheduledNotifications, settings, now);

      // Remove notificações antigas e não enviadas
      final validNotifications = state.scheduledNotifications
          .where((n) => n.sent || n.scheduledFor.isAfter(now))
          .toList();

      state = state.copyWith(
        scheduledNotifications: [...validNotifications, ...scheduledNotifications],
      );

      AppLogger.info('📅 Intelligent notifications scheduled', data: {
        'count': scheduledNotifications.length,
        'types': scheduledNotifications.map((n) => n.type).toSet().toList(),
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to schedule notifications', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Agenda lembretes de streak
  Future<void> _scheduleStreakReminders(
    List<ScheduledNotification> notifications,
    NotificationSettings settings,
    DateTime now,
  ) async {
    final streakState = _ref.read(streakProvider);
    
    // Só agenda se o usuário tem um streak ativo ou recente
    if (streakState.currentStreak == 0) return;

    // Verifica se já enviou lembrete hoje
    final lastStreakReminder = state.lastSent['streak_reminder'];
    if (lastStreakReminder != null) {
      final today = DateTime(now.year, now.month, now.day);
      final lastReminderDay = DateTime(
        lastStreakReminder.year,
        lastStreakReminder.month,
        lastStreakReminder.day,
      );
      if (today == lastReminderDay) return;
    }

    // Agenda para o horário preferido do usuário (se ainda não passou hoje)
    final preferredTime = settings.preferredTime.split(':');
    final preferredHour = int.parse(preferredTime[0]);
    final preferredMinute = int.parse(preferredTime[1]);

    var reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      preferredHour,
      preferredMinute,
    );

    // Se já passou, agenda para amanhã
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    final nextMilestone = StreakMilestone.getNextMilestone(streakState.currentStreak);
    final daysToMilestone = nextMilestone != null 
        ? nextMilestone.days - streakState.currentStreak 
        : 0;

    String title = '🔥 Mantenha seu streak!';
    String body = streakState.hasLoggedInToday
        ? 'Você já logou hoje! Seu streak atual é de ${streakState.currentStreak} dias'
        : 'Não perca seu streak de ${streakState.currentStreak} dias! Faça login no Unlock';

    if (nextMilestone != null && daysToMilestone <= 3) {
      body += '. Faltam apenas $daysToMilestone dias para ${nextMilestone.title}!';
    }

    notifications.add(ScheduledNotification(
      id: 'streak_reminder_${reminderTime.millisecondsSinceEpoch}',
      type: 'streak_reminder',
      title: title,
      body: body,
      scheduledFor: reminderTime,
      data: {
        'currentStreak': streakState.currentStreak,
        'nextMilestone': nextMilestone?.days,
        'daysToMilestone': daysToMilestone,
      },
    ));
  }

  /// Agenda digest semanal
  Future<void> _scheduleWeeklyDigest(
    List<ScheduledNotification> notifications,
    NotificationSettings settings,
    DateTime now,
  ) async {
    // Verifica se já enviou esta semana
    final lastDigest = state.lastSent['weekly_digest'];
    if (lastDigest != null) {
      final weeksDifference = now.difference(lastDigest).inDays ~/ 7;
      if (weeksDifference == 0) return;
    }

    // Agenda para domingo às 19:00
    var digestTime = _getNextSunday(now);
    digestTime = DateTime(
      digestTime.year,
      digestTime.month,
      digestTime.day,
      19,
      0,
    );

    notifications.add(ScheduledNotification(
      id: 'weekly_digest_${digestTime.millisecondsSinceEpoch}',
      type: 'weekly_digest',
      title: '📊 Seu resumo semanal no Unlock',
      body: 'Veja como foi sua semana de conexões e descobertas!',
      scheduledFor: digestTime,
      data: {
        'week': _getWeekNumber(digestTime),
        'year': digestTime.year,
      },
    ));
  }

  /// Agenda lembretes de atividade baseados no padrão do usuário
  Future<void> _scheduleActivityReminders(
    List<ScheduledNotification> notifications,
    NotificationSettings settings,
    DateTime now,
  ) async {
    // Lógica para detectar inatividade e agendar lembretes personalizados
    // Por exemplo, se o usuário não joga há 2 dias, enviar lembrete

    final random = Random();
    final encouragingMessages = [
      'Que tal descobrir alguém novo hoje? 🎯',
      'Novas conexões estão esperando por você! 💫',
      'Hora de jogar um quiz e fazer novas amizades! 🎮',
      'Seus matches estão curiosos sobre você! 👀',
    ];

    // Agenda um lembrete aleatório para amanhã
    final reminderTime = now.add(Duration(
      days: 1,
      hours: 10 + random.nextInt(8), // Entre 10h e 18h
    ));

    notifications.add(ScheduledNotification(
      id: 'activity_reminder_${reminderTime.millisecondsSinceEpoch}',
      type: 'activity_reminder',
      title: 'Unlock te espera! 🚀',
      body: encouragingMessages[random.nextInt(encouragingMessages.length)],
      scheduledFor: reminderTime,
      data: {
        'type': 'activity_reminder',
        'randomIndex': random.nextInt(100),
      },
    ));
  }

  /// Solicita permissões de notificação
  Future<bool> requestPermissions() async {
    try {
      final granted = await NotificationService.requestPermissions();
      
      if (granted) {
        final fcmToken = await NotificationService.getFCMToken();
        state = state.copyWith(
          permissionsGranted: true,
          fcmToken: fcmToken,
        );
      }

      return granted;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to request permissions', 
        error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Envia notificação imediata
  Future<void> sendImmediateNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await NotificationService.sendLocalNotification(
        title: title,
        body: body,
        data: data ?? {},
      );

      AppLogger.info('📤 Immediate notification sent', data: {
        'title': title,
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to send immediate notification', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Força reagendamento de notificações
  Future<void> rescheduleNotifications() async {
    await _scheduleIntelligentNotifications();
  }

  /// Limpa todas as notificações agendadas
  void clearScheduledNotifications() {
    state = state.copyWith(scheduledNotifications: []);
  }

  /// Utilitários de data
  DateTime _getNextSunday(DateTime date) {
    final daysUntilSunday = (7 - date.weekday) % 7;
    return date.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    return ((date.difference(firstDayOfYear).inDays) / 7).ceil();
  }
}

/// Notifier para configurações de notificação
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _loadSettings();
  }

  /// Carrega configurações salvas
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings');
      
      if (settingsJson != null) {
        // Implementar parsing JSON
        AppLogger.debug('📱 Notification settings loaded');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to load notification settings', error: e);
    }
  }

  /// Salva configurações
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_settings', state.toJson().toString());
      AppLogger.debug('📱 Notification settings saved');
    } catch (e) {
      AppLogger.error('❌ Failed to save notification settings', error: e);
    }
  }

  /// Atualiza configurações
  Future<void> updateSettings(NotificationSettings newSettings) async {
    state = newSettings;
    await _saveSettings();
  }

  /// Toggle configuração específica
  Future<void> toggleSetting(String settingName, bool value) async {
    NotificationSettings newSettings;
    
    switch (settingName) {
      case 'enabled':
        newSettings = state.copyWith(enabled: value);
        break;
      case 'streakReminders':
        newSettings = state.copyWith(streakReminders: value);
        break;
      case 'gameInvites':
        newSettings = state.copyWith(gameInvites: value);
        break;
      case 'connectionUpdates':
        newSettings = state.copyWith(connectionUpdates: value);
        break;
      case 'weeklyDigest':
        newSettings = state.copyWith(weeklyDigest: value);
        break;
      case 'achievementUnlocks':
        newSettings = state.copyWith(achievementUnlocks: value);
        break;
      default:
        return;
    }

    state = newSettings;
    await _saveSettings();
  }
}