// lib/services/analytics/analytics_manager.dart
import 'dart:async';
import 'dart:collection';

import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/services/analytics/analytics_config.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

/// Gerenciador central de analytics que coordena múltiplos providers
///
/// Implementa controle de custos, rate limiting e fallback entre providers.
class AnalyticsManager {
  static AnalyticsManager? _instance;
  static AnalyticsManager get instance => _instance ??= AnalyticsManager._();

  AnalyticsManager._();

  // ========== PROVIDERS E ESTADO ==========

  final Map<String, AnalyticsInterface> _providers = {};
  final List<AnalyticsEvent> _eventQueue = [];
  final Map<String, int> _eventCounts = {}; // Contadores por tipo

  bool _isInitialized = false;
  String? _currentUserId;
  Timer? _flushTimer;

  // Controle de rate limiting
  final Queue<DateTime> _recentEvents = Queue<DateTime>();
  int _eventsToday = 0;
  int _eventsThisSession = 0;
  DateTime? _lastResetDate;

  // ========== INICIALIZAÇÃO ==========

  /// Inicializar o analytics manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('📊 Inicializando Analytics Manager...');

      // Resetar contadores se necessário
      _resetDailyCountersIfNeeded();

      // Inicializar providers ativos
      await _initializeProviders();

      // Configurar timer para flush automático
      _setupAutoFlush();

      _isInitialized = true;

      AppLogger.info(
        '✅ Analytics Manager inicializado',
        data: {
          'activeProviders': _providers.keys.toList(),
          'isDevelopment': AnalyticsConfig.isDevelopment,
        },
      );

      // Evento de inicialização
      await trackEvent(
        'analytics_initialized',
        parameters: {
          'providers': _providers.keys.toList(),
          'environment': AnalyticsConfig.isDevelopment
              ? 'development'
              : 'production',
        },
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao inicializar Analytics Manager: $e');
      rethrow;
    }
  }

  /// Adicionar provider de analytics
  Future<void> addProvider(AnalyticsInterface provider) async {
    try {
      AppLogger.debug('📊 Adicionando provider: ${provider.providerName}');

      await provider.initialize();
      _providers[provider.providerName] = provider;

      // Definir userId se já estiver disponível
      if (_currentUserId != null) {
        await provider.setUserId(_currentUserId);
      }

      AppLogger.info('✅ Provider adicionado: ${provider.providerName}');
    } catch (e) {
      AppLogger.error(
        '❌ Erro ao adicionar provider ${provider.providerName}: $e',
      );
    }
  }

  /// Remover provider
  Future<void> removeProvider(String providerName) async {
    final provider = _providers.remove(providerName);
    if (provider != null) {
      try {
        await provider.dispose();
        AppLogger.info('🗑️ Provider removido: $providerName');
      } catch (e) {
        AppLogger.error('❌ Erro ao remover provider $providerName: $e');
      }
    }
  }

  // ========== TRACKING DE EVENTOS ==========

  /// Rastrear evento principal
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    EventPriority priority = EventPriority.medium,
    EventCategory category = EventCategory.user,
    List<String>? onlyProviders,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning(
        '⚠️ Analytics não inicializado, evento ignorado: $eventName',
      );
      return;
    }

    try {
      // Criar evento
      final event = AnalyticsEvent(
        name: eventName,
        parameters: parameters,
        priority: priority,
        category: category,
      );

      // Validações e controles
      if (!_shouldTrackEvent(event)) {
        return;
      }

      // Sanitizar parâmetros
      final sanitizedParams = AnalyticsConfig.sanitizeParameters(parameters);

      // Determinar providers para enviar
      final targetProviders = _getTargetProviders(event, onlyProviders);

      if (targetProviders.isEmpty) {
        AppLogger.debug(
          '📊 Nenhum provider disponível para evento: $eventName',
        );
        return;
      }

      // Incrementar contadores
      _incrementCounters(eventName);

      // Enviar para providers
      await _sendToProviders(eventName, sanitizedParams, targetProviders);

      // Log do evento
      AppLogger.debug(
        '📊 Evento rastreado: $eventName',
        data: {
          'category': category.name,
          'priority': priority.name,
          'providers': targetProviders,
          'parameters': sanitizedParams,
        },
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear evento $eventName: $e');
    }
  }

  /// Rastrear visualização de tela
  Future<void> trackScreen(
    String screenName, {
    String? screenClass,
    Map<String, dynamic>? parameters,
  }) async {
    final params = {
      'screen_name': screenName,
      if (screenClass != null) 'screen_class': screenClass,
      ...?parameters,
    };

    await trackEvent(
      'screen_view',
      parameters: params,
      category: EventCategory.user,
      priority: EventPriority.medium,
    );
  }

  /// Rastrear performance/timing
  Future<void> trackTiming(
    String name,
    int durationMs, {
    String? category,
    Map<String, dynamic>? parameters,
  }) async {
    final params = {
      'duration_ms': durationMs,
      'duration_seconds': (durationMs / 1000).round(),
      if (category != null) 'category': category,
      ...?parameters,
    };

    await trackEvent(
      'timing_$name',
      parameters: params,
      category: EventCategory.performance,
      priority: EventPriority.medium,
    );
  }

  /// Rastrear erro
  Future<void> trackError(
    String description, {
    Object? error,
    StackTrace? stackTrace,
    bool fatal = false,
    Map<String, dynamic>? parameters,
  }) async {
    final params = {
      'error_description': description,
      'fatal': fatal,
      if (error != null) 'error_type': error.runtimeType.toString(),
      if (stackTrace != null) 'has_stack_trace': true,
      ...?parameters,
    };

    await trackEvent(
      fatal ? 'app_crash' : 'app_error',
      parameters: params,
      category: EventCategory.error,
      priority: fatal ? EventPriority.critical : EventPriority.high,
    );
  }

  /// Rastrear conversão
  Future<void> trackConversion(
    String goalName, {
    double? value,
    String? currency,
    Map<String, dynamic>? parameters,
  }) async {
    final params = {
      'goal_name': goalName,
      if (value != null) 'value': value,
      if (currency != null) 'currency': currency,
      ...?parameters,
    };

    await trackEvent(
      'conversion',
      parameters: params,
      category: EventCategory.business,
      priority: EventPriority.high,
    );
  }

  // ========== GESTÃO DE USUÁRIO ==========

  /// Definir ID do usuário
  Future<void> setUserId(String? userId) async {
    _currentUserId = userId;

    AppLogger.info('👤 Definindo user ID: ${userId ?? 'null'}');

    for (final provider in _providers.values) {
      try {
        await provider.setUserId(userId);
      } catch (e) {
        AppLogger.error(
          '❌ Erro ao definir userId no provider ${provider.providerName}: $e',
        );
      }
    }
  }

  /// Definir propriedade do usuário
  Future<void> setUserProperty(String key, String value) async {
    AppLogger.debug('👤 Definindo propriedade: $key = $value');

    for (final provider in _providers.values) {
      try {
        await provider.setUserProperty(key, value);
      } catch (e) {
        AppLogger.error(
          '❌ Erro ao definir propriedade no provider ${provider.providerName}: $e',
        );
      }
    }
  }

  /// Iniciar sessão
  Future<void> startSession() async {
    _eventsThisSession = 0;

    AppLogger.info('🎬 Iniciando sessão de analytics');

    for (final provider in _providers.values) {
      try {
        await provider.startSession();
      } catch (e) {
        AppLogger.error(
          '❌ Erro ao iniciar sessão no provider ${provider.providerName}: $e',
        );
      }
    }

    await trackEvent('session_start', category: EventCategory.system);
  }

  /// Finalizar sessão
  Future<void> endSession() async {
    AppLogger.info(
      '🎬 Finalizando sessão de analytics',
      data: {'eventsThisSession': _eventsThisSession},
    );

    await trackEvent(
      'session_end',
      parameters: {'session_events': _eventsThisSession},
      category: EventCategory.system,
    );

    for (final provider in _providers.values) {
      try {
        await provider.endSession();
      } catch (e) {
        AppLogger.error(
          '❌ Erro ao finalizar sessão no provider ${provider.providerName}: $e',
        );
      }
    }
  }

  /// Reset de dados (logout)
  Future<void> reset() async {
    AppLogger.info('🔄 Resetando analytics');

    _currentUserId = null;
    _eventsThisSession = 0;

    for (final provider in _providers.values) {
      try {
        await provider.reset();
      } catch (e) {
        AppLogger.error(
          '❌ Erro ao resetar provider ${provider.providerName}: $e',
        );
      }
    }
  }

  // ========== MÉTODOS INTERNOS ==========

  /// Inicializar providers baseado na configuração
  Future<void> _initializeProviders() async {
    // Os providers serão adicionados externamente baseado na configuração
    // Isso mantém o manager agnóstico sobre implementações específicas
    AppLogger.debug('📊 Aguardando adição de providers...');
  }

  /// Verificar se deve rastrear um evento
  bool _shouldTrackEvent(AnalyticsEvent event) {
    // Rate limiting por minuto
    final now = DateTime.now();
    _recentEvents.removeWhere((time) => now.difference(time).inMinutes > 1);

    if (_recentEvents.length >= AnalyticsConfig.maxEventsPerMinute) {
      AppLogger.warning(
        '⚠️ Rate limit atingido, evento ignorado: ${event.name}',
      );
      return false;
    }

    // Limite diário
    if (_eventsToday >= AnalyticsConfig.maxEventsPerUserPerDay) {
      AppLogger.warning(
        '⚠️ Limite diário atingido, evento ignorado: ${event.name}',
      );
      return false;
    }

    // Limite por sessão
    if (_eventsThisSession >= AnalyticsConfig.maxEventsPerSession) {
      AppLogger.warning(
        '⚠️ Limite de sessão atingido, evento ignorado: ${event.name}',
      );
      return false;
    }

    // Validar parâmetros
    if (!AnalyticsConfig.validateEventParameters(event.parameters)) {
      AppLogger.warning(
        '⚠️ Parâmetros inválidos, evento ignorado: ${event.name}',
      );
      return false;
    }

    // Sampling
    if (!AnalyticsConfig.shouldSampleEvent(event.name, event.category)) {
      AppLogger.debug('📊 Evento ignorado por sampling: ${event.name}');
      return false;
    }

    return true;
  }

  /// Obter providers alvo para um evento
  List<String> _getTargetProviders(
    AnalyticsEvent event,
    List<String>? onlyProviders,
  ) {
    final availableProviders = _providers.keys.toList();

    if (onlyProviders != null) {
      return onlyProviders
          .where((p) => availableProviders.contains(p))
          .toList();
    }

    return availableProviders.where((provider) {
      return AnalyticsConfig.shouldUseProvider(
        provider,
        event.name,
        event.category,
      );
    }).toList();
  }

  /// Enviar evento para providers específicos
  Future<void> _sendToProviders(
    String eventName,
    Map<String, dynamic>? parameters,
    List<String> providers,
  ) async {
    final futures = providers.map((providerName) async {
      final provider = _providers[providerName];
      if (provider == null) return;

      try {
        await provider.trackEvent(eventName, parameters: parameters);
      } catch (e) {
        AppLogger.error('❌ Erro ao enviar evento para $providerName: $e');
      }
    });

    await Future.wait(futures);
  }

  /// Incrementar contadores
  void _incrementCounters(String eventName) {
    _recentEvents.add(DateTime.now());
    _eventsToday++;
    _eventsThisSession++;
    _eventCounts[eventName] = (_eventCounts[eventName] ?? 0) + 1;
  }

  /// Reset contadores diários
  void _resetDailyCountersIfNeeded() {
    final now = DateTime.now();

    if (_lastResetDate == null || now.difference(_lastResetDate!).inDays >= 1) {
      _eventsToday = 0;
      _lastResetDate = now;
      AppLogger.debug('📊 Contadores diários resetados');
    }
  }

  /// Configurar flush automático
  void _setupAutoFlush() {
    _flushTimer = Timer.periodic(AnalyticsConfig.eventCacheTimeout, (_) {
      flush();
    });
  }

  // ========== UTILITÁRIOS ==========

  /// Forçar envio de eventos pendentes
  Future<void> flush() async {
    AppLogger.debug('📊 Flush de analytics...');

    for (final provider in _providers.values) {
      try {
        await provider.flush();
      } catch (e) {
        AppLogger.error(
          '❌ Erro no flush do provider ${provider.providerName}: $e',
        );
      }
    }
  }

  /// Obter estatísticas de uso
  Map<String, dynamic> getStats() {
    return {
      'eventsToday': _eventsToday,
      'eventsThisSession': _eventsThisSession,
      'activeProviders': _providers.keys.toList(),
      'eventCounts': Map.from(_eventCounts),
      'isInitialized': _isInitialized,
      'currentUserId': _currentUserId,
    };
  }

  /// Verificar se está habilitado
  bool get isEnabled => _isInitialized && _providers.isNotEmpty;

  /// Limpar recursos
  Future<void> dispose() async {
    AppLogger.info('🧹 Fazendo dispose do Analytics Manager');

    _flushTimer?.cancel();

    for (final provider in _providers.values) {
      try {
        await provider.dispose();
      } catch (e) {
        AppLogger.error(
          '❌ Erro no dispose do provider ${provider.providerName}: $e',
        );
      }
    }

    _providers.clear();
    _eventQueue.clear();
    _eventCounts.clear();
    _recentEvents.clear();

    _isInitialized = false;
    _instance = null;
  }
}
