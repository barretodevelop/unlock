// lib/services/analytics/implementations/mock_analytics_impl.dart
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

/// Implementação Mock para analytics - usado em desenvolvimento e testes
///
/// Permite testar o sistema de analytics sem enviar dados reais,
/// e fornece ferramentas de debug e validação.
class MockAnalyticsImpl implements AnalyticsInterface {
  bool _isInitialized = false;
  String? _currentUserId;
  final Map<String, String> _userProperties = {};
  final Queue<MockAnalyticsEvent> _events = Queue<MockAnalyticsEvent>();
  final Map<String, MockPerformanceTrace> _activeTraces = {};
  final List<String> _logs = [];

  // Configurações do mock
  final bool _logToConsole;
  final bool _simulateNetworkDelay;
  final int _maxStoredEvents;

  MockAnalyticsImpl({
    bool logToConsole = true,
    bool simulateNetworkDelay = false,
    int maxStoredEvents = 1000,
  }) : _logToConsole = logToConsole,
       _simulateNetworkDelay = simulateNetworkDelay,
       _maxStoredEvents = maxStoredEvents;

  @override
  String get providerName => 'mock';

  @override
  bool get isEnabled => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🧪 Inicializando Mock Analytics...');

      // Simular delay de inicialização se configurado
      if (_simulateNetworkDelay) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _isInitialized = true;

      AppLogger.info(
        '✅ Mock Analytics inicializado',
        data: {
          'provider': providerName,
          'logToConsole': _logToConsole,
          'simulateDelay': _simulateNetworkDelay,
          'maxEvents': _maxStoredEvents,
        },
      );

      // Log inicial
      _addLog('Mock Analytics initialized');
    } catch (e) {
      AppLogger.error('❌ Erro ao inicializar Mock Analytics: $e');
      rethrow;
    }
  }

  @override
  Future<void> trackEvent(
    String event, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) return;

    try {
      // Simular delay de rede se configurado
      if (_simulateNetworkDelay) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Criar evento mock
      final mockEvent = MockAnalyticsEvent(
        name: event,
        parameters: parameters,
        timestamp: DateTime.now(),
        userId: _currentUserId,
        userProperties: Map.from(_userProperties),
      );

      // Adicionar à fila de eventos
      _addEvent(mockEvent);

      // Log detalhado
      if (_logToConsole) {
        AppLogger.debug('🧪 Mock evento: $event', data: parameters);
      }

      _addLog(
        'Event tracked: $event ${parameters != null ? jsonEncode(parameters) : ''}',
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear evento Mock: $e');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized) return;

    try {
      _currentUserId = userId;

      if (_logToConsole) {
        AppLogger.debug('🧪 Mock userId definido: ${userId ?? 'null'}');
      }

      _addLog('User ID set: ${userId ?? 'null'}');
    } catch (e) {
      AppLogger.error('❌ Erro ao definir userId Mock: $e');
    }
  }

  @override
  Future<void> setUserProperty(String key, String value) async {
    if (!_isInitialized) return;

    try {
      _userProperties[key] = value;

      if (_logToConsole) {
        AppLogger.debug('🧪 Mock propriedade: $key = $value');
      }

      _addLog('User property set: $key = $value');
    } catch (e) {
      AppLogger.error('❌ Erro ao definir propriedade Mock: $e');
    }
  }

  @override
  Future<void> trackScreen(
    String screenName, {
    String? screenClass,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) return;

    try {
      final params = {
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
        ...?parameters,
      };

      await trackEvent('screen_view', parameters: params);

      if (_logToConsole) {
        AppLogger.debug('🧪 Mock screen: $screenName');
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear screen Mock: $e');
    }
  }

  @override
  Future<void> trackTiming(
    String name,
    int durationMs, {
    String? category,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) return;

    try {
      final params = {
        'duration_ms': durationMs,
        'duration_seconds': (durationMs / 1000).round(),
        if (category != null) 'category': category,
        ...?parameters,
      };

      await trackEvent('timing_$name', parameters: params);

      if (_logToConsole) {
        AppLogger.debug('🧪 Mock timing: $name (${durationMs}ms)');
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear timing Mock: $e');
    }
  }

  @override
  Future<void> trackError(
    String description, {
    Object? error,
    StackTrace? stackTrace,
    bool fatal = false,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) return;

    try {
      final params = {
        'error_description': description,
        'fatal': fatal,
        if (error != null) 'error_type': error.runtimeType.toString(),
        if (stackTrace != null) 'has_stack_trace': true,
        ...?parameters,
      };

      await trackEvent(fatal ? 'app_crash' : 'app_error', parameters: params);

      if (_logToConsole) {
        AppLogger.debug('🧪 Mock erro: $description (fatal: $fatal)');
      }

      _addLog('Error tracked: $description (fatal: $fatal)');
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear erro Mock: $e');
    }
  }

  @override
  Future<void> trackConversion(
    String goalName, {
    double? value,
    String? currency,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) return;

    try {
      final params = {
        'goal_name': goalName,
        if (value != null) 'value': value,
        if (currency != null) 'currency': currency,
        ...?parameters,
      };

      await trackEvent('conversion', parameters: params);

      if (_logToConsole) {
        AppLogger.debug('🧪 Mock conversão: $goalName');
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear conversão Mock: $e');
    }
  }

  @override
  Future<void> startSession() async {
    if (!_isInitialized) return;

    try {
      await trackEvent('session_start');

      if (_logToConsole) {
        AppLogger.debug('🧪 Mock sessão iniciada');
      }

      _addLog('Session started');
    } catch (e) {
      AppLogger.error('❌ Erro ao iniciar sessão Mock: $e');
    }
  }

  @override
  Future<void> endSession() async {
    if (!_isInitialized) return;

    try {
      await trackEvent('session_end');

      if (_logToConsole) {
        AppLogger.debug('🧪 Mock sessão finalizada');
      }

      _addLog('Session ended');
    } catch (e) {
      AppLogger.error('❌ Erro ao finalizar sessão Mock: $e');
    }
  }

  @override
  Future<void> flush() async {
    if (_logToConsole) {
      AppLogger.debug('🧪 Mock flush (${_events.length} eventos)');
    }

    _addLog('Flush called (${_events.length} events in queue)');
  }

  @override
  Future<void> reset() async {
    if (!_isInitialized) return;

    try {
      _currentUserId = null;
      _userProperties.clear();
      _events.clear();
      _activeTraces.clear();
      _logs.clear();

      if (_logToConsole) {
        AppLogger.debug('🧪 Mock analytics resetado');
      }

      _addLog('Analytics reset');
    } catch (e) {
      AppLogger.error('❌ Erro ao resetar Mock: $e');
    }
  }

  // ========== PERFORMANCE TRACKING ==========

  /// Iniciar trace de performance
  PerformanceTrace startTrace(String name) {
    final trace = MockPerformanceTrace(name, () {
      _activeTraces.remove(name);
    });

    _activeTraces[name] = trace;

    if (_logToConsole) {
      AppLogger.debug('🧪 Mock trace iniciada: $name');
    }

    return trace;
  }

  // ========== MÉTODOS DE DEBUG E TESTE ==========

  /// Obter todos os eventos coletados
  List<MockAnalyticsEvent> getEvents() {
    return List.unmodifiable(_events);
  }

  /// Obter eventos por nome
  List<MockAnalyticsEvent> getEventsByName(String eventName) {
    return _events.where((event) => event.name == eventName).toList();
  }

  /// Obter último evento
  MockAnalyticsEvent? getLastEvent() {
    return _events.isEmpty ? null : _events.last;
  }

  /// Contar eventos por nome
  Map<String, int> getEventCounts() {
    final counts = <String, int>{};
    for (final event in _events) {
      counts[event.name] = (counts[event.name] ?? 0) + 1;
    }
    return counts;
  }

  /// Obter propriedades do usuário atual
  Map<String, String> getUserProperties() {
    return Map.unmodifiable(_userProperties);
  }

  /// Obter logs do mock
  List<String> getLogs() {
    return List.unmodifiable(_logs);
  }

  /// Limpar eventos (útil para testes)
  void clearEvents() {
    _events.clear();
    _addLog('Events cleared');
  }

  /// Verificar se evento específico foi rastreado
  bool hasEvent(String eventName) {
    return _events.any((event) => event.name == eventName);
  }

  /// Verificar se evento com parâmetros específicos foi rastreado
  bool hasEventWithParameters(
    String eventName,
    Map<String, dynamic> expectedParams,
  ) {
    return _events.any((event) {
      if (event.name != eventName) return false;
      if (event.parameters == null) return expectedParams.isEmpty;

      for (final entry in expectedParams.entries) {
        if (event.parameters![entry.key] != entry.value) return false;
      }

      return true;
    });
  }

  /// Obter estatísticas do mock
  Map<String, dynamic> getStats() {
    return {
      'totalEvents': _events.length,
      'eventCounts': getEventCounts(),
      'currentUserId': _currentUserId,
      'userProperties': _userProperties,
      'activeTraces': _activeTraces.keys.toList(),
      'isInitialized': _isInitialized,
    };
  }

  /// Exportar eventos como JSON (para debug)
  String exportEventsAsJson() {
    final eventsData = _events.map((event) => event.toJson()).toList();
    return jsonEncode({
      'metadata': {
        'provider': providerName,
        'exportedAt': DateTime.now().toIso8601String(),
        'totalEvents': _events.length,
        'userId': _currentUserId,
      },
      'events': eventsData,
    });
  }

  // ========== MÉTODOS INTERNOS ==========

  void _addEvent(MockAnalyticsEvent event) {
    _events.add(event);

    // Manter apenas os últimos N eventos para evitar uso excessivo de memória
    while (_events.length > _maxStoredEvents) {
      _events.removeFirst();
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _logs.add('[$timestamp] $message');

    // Manter apenas os últimos logs
    while (_logs.length > 500) {
      _logs.removeAt(0);
    }
  }

  @override
  Future<void> dispose() async {
    AppLogger.debug('🧹 Disposing Mock Analytics');

    // Parar todas as traces ativas
    for (final trace in _activeTraces.values) {
      trace.stop();
    }

    _events.clear();
    _userProperties.clear();
    _activeTraces.clear();
    _logs.clear();

    _isInitialized = false;
  }
}

/// Classe para representar evento mock com informações detalhadas
class MockAnalyticsEvent {
  final String name;
  final Map<String, dynamic>? parameters;
  final DateTime timestamp;
  final String? userId;
  final Map<String, String> userProperties;

  const MockAnalyticsEvent({
    required this.name,
    this.parameters,
    required this.timestamp,
    this.userId,
    this.userProperties = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userProperties': userProperties,
    };
  }

  @override
  String toString() {
    return 'MockAnalyticsEvent(name: $name, timestamp: $timestamp, userId: $userId)';
  }
}

/// Implementação mock de PerformanceTrace
class MockPerformanceTrace implements PerformanceTrace {
  final String _name;
  final VoidCallback _onStop;
  final DateTime _startTime;
  final Map<String, int> _metrics = {};
  final Map<String, String> _attributes = {};
  bool _stopped = false;

  MockPerformanceTrace(this._name, this._onStop) : _startTime = DateTime.now();

  @override
  String get name => _name;

  @override
  void putMetric(String metricName, int value) {
    if (_stopped) return;
    _metrics[metricName] = value;
    AppLogger.debug('🧪 Mock trace métrica: $_name.$metricName = $value');
  }

  @override
  void putAttribute(String attributeName, String value) {
    if (_stopped) return;
    _attributes[attributeName] = value;
    AppLogger.debug('🧪 Mock trace atributo: $_name.$attributeName = $value');
  }

  @override
  void stop() {
    if (_stopped) return;

    _stopped = true;
    final duration = DateTime.now().difference(_startTime);

    AppLogger.debug(
      '🧪 Mock trace finalizada: $_name (${duration.inMilliseconds}ms)',
      data: {
        'duration_ms': duration.inMilliseconds,
        'metrics': _metrics,
        'attributes': _attributes,
      },
    );

    _onStop();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': _name,
      'startTime': _startTime.toIso8601String(),
      'duration_ms': _stopped
          ? DateTime.now().difference(_startTime).inMilliseconds
          : null,
      'metrics': _metrics,
      'attributes': _attributes,
      'stopped': _stopped,
    };
  }
}
