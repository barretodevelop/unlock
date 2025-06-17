// lib/services/analytics/analytics_config.dart
import 'package:flutter/foundation.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

/// Configurações centralizadas para o sistema de analytics
///
/// Controla custos, providers ativos e políticas de envio de eventos.
class AnalyticsConfig {
  // ========== CONFIGURAÇÕES DE AMBIENTE ==========

  /// Se está em modo de desenvolvimento
  static const bool isDevelopment = kDebugMode;

  /// Se está em modo de produção
  static const bool isProduction = !kDebugMode;

  /// Versão do app para analytics
  static const String appVersion = '1.0.0';

  // ========== CONTROLE DE CUSTOS ==========

  /// Máximo de eventos por dia por usuário
  static const int maxEventsPerUserPerDay = 500;

  /// Máximo de eventos por sessão
  static const int maxEventsPerSession = 100;

  /// Máximo de eventos por minuto (throttling)
  static const int maxEventsPerMinute = 30;

  /// Tamanho máximo do parâmetro de evento (em caracteres)
  static const int maxParameterSize = 1000;

  /// Número máximo de parâmetros por evento
  static const int maxParametersPerEvent = 25;

  // ========== CONFIGURAÇÃO DE PROVIDERS ==========

  /// Providers ativos por ambiente
  static List<String> get activeProviders {
    if (isDevelopment) {
      return ['mock', 'firebase']; // Mock para testes, Firebase para debug
    } else {
      return ['amplitude', 'firebase']; // Amplitude gratuito + Firebase básico
    }
  }

  /// Configuração de providers por evento
  static const Map<String, List<String>> providersByEventCategory = {
    'debug': ['mock'], // Só mock em desenvolvimento
    'development': ['firebase'], // Só Firebase para desenvolvimento
    'user': [
      'amplitude',
      'firebase',
    ], // Todos os providers para eventos de usuário
    'business': ['amplitude'], // Só providers gratuitos/baratos para business
    'performance': [
      'firebase',
    ], // Firebase para performance (tem tools específicos)
    'error': ['firebase', 'amplitude'], // Todos para erros (crítico)
    'system': ['firebase'], // Sistema no Firebase
  };

  /// Eventos que só devem ser enviados em produção
  static const List<String> productionOnlyEvents = [
    'revenue_',
    'purchase_',
    'subscription_',
    'conversion_',
  ];

  /// Eventos que só devem ser enviados em desenvolvimento
  static const List<String> developmentOnlyEvents = ['debug_', 'test_', 'dev_'];

  // ========== CONFIGURAÇÕES DE RETENÇÃO ==========

  /// Tempo para manter eventos em cache local (antes de enviar)
  static const Duration eventCacheTimeout = Duration(minutes: 5);

  /// Máximo de eventos para manter em cache
  static const int maxCachedEvents = 1000;

  /// Tentar reenviar eventos falhados
  static const bool retryFailedEvents = true;

  /// Máximo de tentativas para reenvio
  static const int maxRetryAttempts = 3;

  // ========== CONFIGURAÇÕES DE SAMPLING ==========

  /// Taxa de sampling para eventos de debug (% que realmente serão enviados)
  static const double debugEventSamplingRate = 0.1; // 10%

  /// Taxa de sampling para eventos de performance
  static const double performanceEventSamplingRate = 0.5; // 50%

  /// Taxa de sampling para eventos de usuário
  static const double userEventSamplingRate = 1.0; // 100%

  // ========== MÉTODOS DE CONFIGURAÇÃO ==========

  /// Verificar se um provider deve ser usado para um evento específico
  static bool shouldUseProvider(
    String provider,
    String eventName,
    EventCategory category,
  ) {
    // Verificar se provider está ativo
    if (!activeProviders.contains(provider)) return false;

    // Verificar configuração por categoria
    final categoryName = category.name;
    final allowedProviders = providersByEventCategory[categoryName];
    if (allowedProviders != null && !allowedProviders.contains(provider)) {
      return false;
    }

    // Verificar eventos específicos de ambiente
    if (isDevelopment) {
      if (productionOnlyEvents.any((prefix) => eventName.startsWith(prefix))) {
        return false;
      }
    } else {
      if (developmentOnlyEvents.any((prefix) => eventName.startsWith(prefix))) {
        return false;
      }
    }

    return true;
  }

  /// Verificar se deve aplicar sampling a um evento
  static bool shouldSampleEvent(String eventName, EventCategory category) {
    double samplingRate;

    switch (category) {
      case EventCategory.debug:
        samplingRate = debugEventSamplingRate;
        break;
      case EventCategory.performance:
        samplingRate = performanceEventSamplingRate;
        break;
      case EventCategory.user:
      case EventCategory.business:
      case EventCategory.error:
        samplingRate = userEventSamplingRate;
        break;
      case EventCategory.system:
        samplingRate = 0.8; // 80% para eventos de sistema
        break;
    }

    // Em desenvolvimento, reduzir sampling para economizar
    if (isDevelopment) {
      samplingRate *= 0.5;
    }

    return (DateTime.now().millisecondsSinceEpoch % 1000) <
        (samplingRate * 1000);
  }

  /// Verificar se parâmetros de evento são válidos
  static bool validateEventParameters(Map<String, dynamic>? parameters) {
    if (parameters == null) return true;

    // Verificar número de parâmetros
    if (parameters.length > maxParametersPerEvent) {
      return false;
    }

    // Verificar tamanho de cada parâmetro
    for (final entry in parameters.entries) {
      final keySize = entry.key.length;
      final valueSize = entry.value.toString().length;

      if (keySize + valueSize > maxParameterSize) {
        return false;
      }
    }

    return true;
  }

  /// Sanitizar parâmetros para remover dados sensíveis
  static Map<String, dynamic>? sanitizeParameters(
    Map<String, dynamic>? parameters,
  ) {
    if (parameters == null) return null;

    final sanitized = <String, dynamic>{};
    final sensitiveKeys = ['password', 'token', 'key', 'secret', 'auth'];

    for (final entry in parameters.entries) {
      final key = entry.key.toLowerCase();

      // Remover dados sensíveis
      if (sensitiveKeys.any((sensitive) => key.contains(sensitive))) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        // Truncar valores muito grandes
        final value = entry.value;
        if (value is String && value.length > maxParameterSize) {
          sanitized[entry.key] = value.substring(0, maxParameterSize);
        } else {
          sanitized[entry.key] = value;
        }
      }
    }

    return sanitized;
  }

  // ========== CONFIGURAÇÕES ESPECÍFICAS DE PROVIDERS ==========

  /// Configurações para Firebase Analytics
  static const Map<String, dynamic> firebaseConfig = {
    'enableInDebug': true,
    'automaticDataCollection': true,
    'sessionTimeoutDuration': 1800, // 30 minutos
  };

  /// Configurações para Amplitude
  static const Map<String, dynamic> amplitudeConfig = {
    'apiKey': 'YOUR_AMPLITUDE_API_KEY', // Configurar em .env
    'enableLocationTracking': false,
    'enableCoppaControl': true, // Para compliance com menores
    'sessionTimeout': 1800000, // 30 minutos em ms
  };

  /// Configurações para Mock Analytics (desenvolvimento)
  static const Map<String, dynamic> mockConfig = {
    'logToConsole': true,
    'saveToFile': false,
    'simulateNetworkDelay': true,
    'maxStoredEvents': 1000,
  };

  // ========== EVENTOS PRÉ-DEFINIDOS ==========

  /// Eventos padrão da aplicação
  static const Map<String, String> standardEvents = {
    // Autenticação
    'user_login': 'User logged in successfully',
    'user_logout': 'User logged out',
    'user_signup': 'User completed registration',
    'login_failed': 'User login attempt failed',

    // Navegação
    'screen_view': 'User viewed a screen',
    'navigation': 'User navigated between screens',

    // Onboarding (para Fase 2)
    'onboarding_started': 'User started onboarding',
    'onboarding_completed': 'User completed onboarding',
    'onboarding_abandoned': 'User abandoned onboarding',

    // Performance
    'app_startup': 'App startup time measured',
    'screen_load': 'Screen load time measured',
    'network_request': 'Network request performance',

    // Erros
    'app_error': 'Application error occurred',
    'crash': 'Application crashed',
    'network_error': 'Network error occurred',

    // UX
    'theme_changed': 'User changed app theme',
    'feature_used': 'User used a specific feature',
  };

  /// Obter descrição de um evento padrão
  static String getEventDescription(String eventName) {
    return standardEvents[eventName] ?? 'Custom event';
  }
}
