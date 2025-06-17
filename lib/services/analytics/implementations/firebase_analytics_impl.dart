// lib/services/analytics/implementations/firebase_analytics_impl.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/services/analytics/analytics_config.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

/// Implementação Firebase para analytics
///
/// Integra Firebase Analytics, Crashlytics e Performance Monitoring
class FirebaseAnalyticsImpl implements AnalyticsInterface {
  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  late final FirebasePerformance _performance;

  bool _isInitialized = false;
  final Map<String, Trace> _activeTraces = {};

  @override
  String get providerName => 'firebase';

  @override
  bool get isEnabled => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🔥 Inicializando Firebase Analytics...');

      // Inicializar serviços Firebase
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _performance = FirebasePerformance.instance;

      // Configurar Analytics
      await _setupAnalytics();

      // Configurar Crashlytics
      await _setupCrashlytics();

      // Configurar Performance
      await _setupPerformance();

      _isInitialized = true;

      AppLogger.info(
        '✅ Firebase Analytics inicializado',
        data: {
          'provider': providerName,
          'environment': AnalyticsConfig.isDevelopment
              ? 'development'
              : 'production',
        },
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao inicializar Firebase Analytics: $e');
      rethrow;
    }
  }

  /// Configurar Firebase Analytics
  Future<void> _setupAnalytics() async {
    try {
      // Configurações baseadas no ambiente
      final config = AnalyticsConfig.firebaseConfig;

      // Em desenvolvimento, podemos coletar mais dados
      if (AnalyticsConfig.isDevelopment) {
        await _analytics.setAnalyticsCollectionEnabled(true);
      }

      // Configurar propriedades globais
      await _analytics.setDefaultEventParameters({
        'app_version': AnalyticsConfig.appVersion,
        'environment': AnalyticsConfig.isDevelopment
            ? 'development'
            : 'production',
        'platform': defaultTargetPlatform.name,
      });

      AppLogger.debug('✅ Firebase Analytics configurado');
    } catch (e) {
      AppLogger.error('❌ Erro ao configurar Firebase Analytics: $e');
    }
  }

  /// Configurar Firebase Crashlytics
  Future<void> _setupCrashlytics() async {
    try {
      // Habilitar Crashlytics baseado no ambiente
      await _crashlytics.setCrashlyticsCollectionEnabled(
        !AnalyticsConfig.isDevelopment,
      );

      // Configurar informações do usuário
      await _crashlytics.setCustomKey(
        'environment',
        AnalyticsConfig.isDevelopment ? 'development' : 'production',
      );

      await _crashlytics.setCustomKey(
        'app_version',
        AnalyticsConfig.appVersion,
      );

      AppLogger.debug('✅ Firebase Crashlytics configurado');
    } catch (e) {
      AppLogger.error('❌ Erro ao configurar Firebase Crashlytics: $e');
    }
  }

  /// Configurar Firebase Performance
  Future<void> _setupPerformance() async {
    try {
      // Performance Monitoring é automático, mas podemos configurar
      await _performance.setPerformanceCollectionEnabled(true);

      AppLogger.debug('✅ Firebase Performance configurado');
    } catch (e) {
      AppLogger.error('❌ Erro ao configurar Firebase Performance: $e');
    }
  }

  @override
  Future<void> trackEvent(
    String event, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) return;

    try {
      // Converter parâmetros para formato Firebase
      final firebaseParams = _convertParameters(parameters);

      // Limitar nome do evento (Firebase tem limitações)
      final eventName = _sanitizeEventName(event);

      await _analytics.logEvent(name: eventName, parameters: firebaseParams);

      AppLogger.debug(
        '🔥 Firebase evento enviado: $eventName',
        data: firebaseParams,
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao enviar evento Firebase: $e');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized) return;

    try {
      await _analytics.setUserId(id: userId);

      // Também definir no Crashlytics
      await _crashlytics.setUserIdentifier(userId ?? '');

      AppLogger.debug('🔥 Firebase userId definido: ${userId ?? 'null'}');
    } catch (e) {
      AppLogger.error('❌ Erro ao definir userId Firebase: $e');
    }
  }

  @override
  Future<void> setUserProperty(String key, String value) async {
    if (!_isInitialized) return;

    try {
      // Firebase Analytics
      await _analytics.setUserProperty(name: key, value: value);

      // Firebase Crashlytics
      await _crashlytics.setCustomKey(key, value);

      AppLogger.debug('🔥 Firebase propriedade definida: $key = $value');
    } catch (e) {
      AppLogger.error('❌ Erro ao definir propriedade Firebase: $e');
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
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );

      // Também logar como evento com parâmetros adicionais
      if (parameters != null && parameters.isNotEmpty) {
        await trackEvent(
          'screen_view',
          parameters: {
            'screen_name': screenName,
            if (screenClass != null) 'screen_class': screenClass,
            ...parameters,
          },
        );
      }

      AppLogger.debug('🔥 Firebase screen view: $screenName');
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear screen Firebase: $e');
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
        ...?_convertParameters(parameters),
      };

      await trackEvent('timing_$name', parameters: params);

      AppLogger.debug('🔥 Firebase timing: $name (${durationMs}ms)');
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear timing Firebase: $e');
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
      // Enviar para Crashlytics
      if (fatal) {
        await _crashlytics.recordError(
          error ?? Exception(description),
          stackTrace,
          fatal: true,
          information:
              parameters?.entries.map((e) => '${e.key}: ${e.value}').toList() ??
              [],
        );
      } else {
        await _crashlytics.log(description);
        if (error != null) {
          await _crashlytics.recordError(error, stackTrace, fatal: false);
        }
      }

      // Também enviar como evento Analytics
      await trackEvent(
        fatal ? 'app_crash' : 'app_error',
        parameters: {
          'error_description': description,
          'fatal': fatal,
          if (error != null) 'error_type': error.runtimeType.toString(),
          ...?parameters,
        },
      );

      AppLogger.debug(
        '🔥 Firebase erro rastreado: $description (fatal: $fatal)',
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear erro Firebase: $e');
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
        ...?_convertParameters(parameters),
      };

      await trackEvent('conversion', parameters: params);

      AppLogger.debug('🔥 Firebase conversão: $goalName');
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear conversão Firebase: $e');
    }
  }

  @override
  Future<void> startSession() async {
    if (!_isInitialized) return;

    try {
      // Firebase gerencia sessões automaticamente
      // Mas podemos logar início de sessão
      await trackEvent('session_start');

      AppLogger.debug('🔥 Firebase sessão iniciada');
    } catch (e) {
      AppLogger.error('❌ Erro ao iniciar sessão Firebase: $e');
    }
  }

  @override
  Future<void> endSession() async {
    if (!_isInitialized) return;

    try {
      await trackEvent('session_end');

      AppLogger.debug('🔥 Firebase sessão finalizada');
    } catch (e) {
      AppLogger.error('❌ Erro ao finalizar sessão Firebase: $e');
    }
  }

  @override
  Future<void> flush() async {
    // Firebase não tem método flush explícito
    // Os eventos são enviados automaticamente
    AppLogger.debug('🔥 Firebase flush (automático)');
  }

  @override
  Future<void> reset() async {
    if (!_isInitialized) return;

    try {
      await _analytics.resetAnalyticsData();
      await setUserId(null);

      // Limpar traces ativas
      for (final trace in _activeTraces.values) {
        trace.stop();
      }
      _activeTraces.clear();

      AppLogger.debug('🔥 Firebase analytics resetado');
    } catch (e) {
      AppLogger.error('❌ Erro ao resetar Firebase: $e');
    }
  }

  // ========== PERFORMANCE TRACKING ==========

  /// Iniciar trace de performance
  PerformanceTrace startTrace(String name) {
    final trace = _performance.newTrace(name);
    trace.start();

    _activeTraces[name] = trace;

    return FirebasePerformanceTrace(trace, name, () {
      _activeTraces.remove(name);
    });
  }

  /// Rastrear requisição de rede
  Future<void> trackNetworkRequest(
    String url,
    String method,
    int statusCode,
    int responseTimeMs, {
    int? responseSize,
  }) async {
    try {
      final metric = _performance.newHttpMetric(
        url,
        HttpMethod.values.firstWhere(
          (m) => m.name.toUpperCase() == method.toUpperCase(),
          orElse: () => HttpMethod.Get,
        ),
      );

      metric.responseContentType = 'application/json';
      metric.requestPayloadSize = responseSize;
      metric.httpResponseCode = statusCode;

      await metric.start();

      // Simular requisição
      await Future.delayed(Duration(milliseconds: responseTimeMs));

      await metric.stop();

      AppLogger.debug(
        '🔥 Firebase network request: $method $url (${statusCode}, ${responseTimeMs}ms)',
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao rastrear requisição Firebase: $e');
    }
  }

  // ========== MÉTODOS AUXILIARES ==========

  /// Converter parâmetros para formato Firebase
  Map<String, Object>? _convertParameters(Map<String, dynamic>? parameters) {
    if (parameters == null) return null;

    final converted = <String, Object>{};

    for (final entry in parameters.entries) {
      final key = _sanitizeParameterKey(entry.key);
      final value = entry.value;

      // Firebase aceita apenas tipos específicos
      if (value is String || value is int || value is double || value is bool) {
        converted[key] = value;
      } else {
        converted[key] = value.toString();
      }
    }

    return converted;
  }

  /// Sanitizar nome do evento para Firebase
  String _sanitizeEventName(String eventName) {
    // Firebase tem limitações: máximo 40 caracteres, apenas letras, números e _
    return eventName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase()
        .substring(0, eventName.length > 40 ? 40 : eventName.length);
  }

  /// Sanitizar chave de parâmetro
  String _sanitizeParameterKey(String key) {
    // Firebase: máximo 24 caracteres
    return key
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase()
        .substring(0, key.length > 24 ? 24 : key.length);
  }

  @override
  Future<void> dispose() async {
    AppLogger.debug('🧹 Disposing Firebase Analytics');

    // Parar todas as traces ativas
    for (final trace in _activeTraces.values) {
      trace.stop();
    }
    _activeTraces.clear();

    _isInitialized = false;
  }
}

/// Implementação de PerformanceTrace para Firebase
class FirebasePerformanceTrace implements PerformanceTrace {
  final Trace _trace;
  final String _name;
  final VoidCallback _onStop;

  FirebasePerformanceTrace(this._trace, this._name, this._onStop);

  @override
  String get name => _name;

  @override
  void putMetric(String metricName, int value) {
    try {
      _trace.setMetric(metricName, value);
    } catch (e) {
      AppLogger.error('❌ Erro ao definir métrica Firebase: $e');
    }
  }

  @override
  void putAttribute(String attributeName, String value) {
    try {
      _trace.putAttribute(attributeName, value);
    } catch (e) {
      AppLogger.error('❌ Erro ao definir atributo Firebase: $e');
    }
  }

  @override
  void stop() {
    try {
      _trace.stop();
      _onStop();
      AppLogger.debug('🔥 Firebase trace finalizada: $_name');
    } catch (e) {
      AppLogger.error('❌ Erro ao parar trace Firebase: $e');
    }
  }
}
