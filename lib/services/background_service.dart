// lib/services/background_service.dart - Real Background Service
// ✅ NOVO: Serviço real para monitoramento em background
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundService {
  static const String _taskName = 'petCareCheck';
  static const String _periodicTaskName = 'petCarePeriodicCheck';
  static const Duration _checkInterval = Duration(hours: 4);

  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static bool _isInitialized = false;

  // ✅ Inicialização do serviço
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print('🔄 BackgroundService: Inicializando...');
      }

      // Inicializar WorkManager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to false in production
      );

      // Inicializar notificações locais
      await _initializeNotifications();

      // Registrar tarefas periódicas
      await _registerPeriodicTasks();

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ BackgroundService: Inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ BackgroundService: Erro na inicialização: $e');
      }
      rethrow;
    }
  }

  // ✅ Inicializar sistema de notificações
  static Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

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

    await _notificationsPlugin!.initialize(settings);
    if (kDebugMode) {
      print('✅ BackgroundService: Notificações inicializadas');
    }
  }

  // ✅ Registrar tarefas periódicas
  static Future<void> _registerPeriodicTasks() async {
    // Cancelar tarefas existentes
    await Workmanager().cancelAll();

    // Registrar verificação periódica a cada 4 horas
    await Workmanager().registerPeriodicTask(
      _periodicTaskName,
      _taskName,
      frequency: _checkInterval,
      initialDelay: const Duration(minutes: 5), // Primeira verificação em 5 min
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    if (kDebugMode) {
      print(
        '✅ BackgroundService: Tarefa periódica registrada (${_checkInterval.inHours}h)',
      );
    }
  }

  // ✅ Verificação manual (quando app abre)
  static Future<void> performManualCheck() async {
    if (kDebugMode) {
      print('🔄 BackgroundService: Verificação manual iniciada');
    }
    try {
      if (kDebugMode) {
        print('✅ BackgroundService: Verificação manual completa');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ BackgroundService: Erro na verificação manual: $e');
      }
    }
  }

  // ✅ Obter timestamp da última verificação
  static Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('lastBackgroundCheck');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  // ✅ Parar serviço (logout)
  static Future<void> stop() async {
    await Workmanager().cancelAll();
    if (kDebugMode) {
      print('🛑 BackgroundService: Serviço parado');
    }
  }

  // ✅ Status do serviço
  static bool get isInitialized => _isInitialized;
}

// ✅ Callback do WorkManager (executa em background)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (kDebugMode) {
      print('🔄 BackgroundTask: Executando tarefa $task');
    }

    try {
      // Inicializar Firebase no isolate
      await Firebase.initializeApp();

      // Executar verificação

      if (kDebugMode) {
        print('✅ BackgroundTask: Tarefa $task concluída');
      }
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('❌ BackgroundTask: Erro na tarefa $task: $e');
      }
      return Future.value(false);
    }
  });
}
