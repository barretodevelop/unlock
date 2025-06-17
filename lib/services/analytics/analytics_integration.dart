// lib/services/analytics/analytics_integration.dart
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/services/analytics/analytics_config.dart';
import 'package:unlock/services/analytics/analytics_manager.dart';
import 'package:unlock/services/analytics/implementations/amplitude_analytics_impl.dart';
import 'package:unlock/services/analytics/implementations/firebase_analytics_impl.dart';
import 'package:unlock/services/analytics/implementations/mock_analytics_impl.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

/// Serviço de integração para inicializar e configurar analytics
///
/// Centraliza a configuração de todos os providers de analytics
/// baseado no ambiente e configurações.
class AnalyticsIntegration {
  static bool _isInitialized = false;
  static AnalyticsManager get manager => AnalyticsManager.instance;

  /// Inicializar sistema completo de analytics
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🚀 Inicializando integração de Analytics...');

      // Inicializar manager
      await manager.initialize();

      // Adicionar providers baseado na configuração
      await _setupProviders();

      // Configurar integração com AppLogger
      _setupLoggerIntegration();

      _isInitialized = true;

      AppLogger.info(
        '✅ Analytics integração inicializada',
        data: {
          'providers': AnalyticsConfig.activeProviders,
          'environment': AnalyticsConfig.isDevelopment
              ? 'development'
              : 'production',
        },
      );

      // Evento inicial de analytics
      await manager.trackEvent(
        'analytics_system_initialized',
        parameters: {
          'providers': AnalyticsConfig.activeProviders,
          'version': AnalyticsConfig.appVersion,
        },
      );
    } catch (e) {
      AppLogger.error('❌ Erro na inicialização de Analytics: $e');
      rethrow;
    }
  }

  /// Configurar providers baseado no ambiente
  static Future<void> _setupProviders() async {
    final activeProviders = AnalyticsConfig.activeProviders;

    for (final providerName in activeProviders) {
      try {
        final provider = await _createProvider(providerName);
        if (provider != null) {
          await manager.addProvider(provider);
          AppLogger.info('✅ Provider adicionado: $providerName');
        }
      } catch (e) {
        AppLogger.error('❌ Erro ao adicionar provider $providerName: $e');
        // Continuar com outros providers mesmo se um falhar
      }
    }
  }

  /// Factory para criar providers específicos
  static Future<AnalyticsInterface?> _createProvider(
    String providerName,
  ) async {
    switch (providerName) {
      case 'firebase':
        return FirebaseAnalyticsImpl();

      case 'mock':
        return MockAnalyticsImpl(
          logToConsole: AnalyticsConfig.isDevelopment,
          simulateNetworkDelay: AnalyticsConfig.isDevelopment,
          maxStoredEvents: 1000,
        );

      case 'amplitude':
        // Só criar se a configuração estiver válida
        if (AmplitudeConfig.isConfigValid()) {
          return AmplitudeAnalyticsImpl();
        } else {
          AppLogger.warning(
            '⚠️ Amplitude configuração inválida, pulando provider',
          );
          return null;
        }

      default:
        AppLogger.warning('⚠️ Provider desconhecido: $providerName');
        return null;
    }
  }

  /// Configurar integração com AppLogger
  static void _setupLoggerIntegration() {
    // Por enquanto, a integração é manual
    // Em versões futuras, podemos interceptar logs automaticamente
    AppLogger.debug('🔗 Integração com AppLogger configurada');
  }

  /// Configurar usuário no analytics (chamar após login)
  static Future<void> setUser({
    required String userId,
    String? username,
    String? email,
    Map<String, String>? properties,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('⚠️ Analytics não inicializado para setUser');
      return;
    }

    try {
      AppLogger.info(
        '👤 Configurando usuário no analytics',
        data: {
          'userId': userId,
          'username': username,
          'email': email!.substring(0, 3) + '***', // Privacy
        },
      );

      // Definir userId no manager
      await manager.setUserId(userId);

      // Definir propriedades do usuário
      if (username != null) {
        await manager.setUserProperty('username', username);
      }

      if (email != null) {
        await manager.setUserProperty('email_domain', email.split('@').last);
      }

      // Propriedades personalizadas
      if (properties != null) {
        for (final entry in properties.entries) {
          await manager.setUserProperty(entry.key, entry.value);
        }
      }

      // Evento de identificação
      await manager.trackEvent(
        'user_identified',
        parameters: {
          'has_username': username != null,
          'has_email': email != null,
          'custom_properties_count': properties?.length ?? 0,
        },
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao configurar usuário no analytics: $e');
    }
  }

  /// Limpar usuário (chamar no logout)
  static Future<void> clearUser() async {
    if (!_isInitialized) return;

    try {
      AppLogger.info('👤 Limpando usuário do analytics');

      await manager.reset();

      AppLogger.debug('✅ Usuário limpo do analytics');
    } catch (e) {
      AppLogger.error('❌ Erro ao limpar usuário do analytics: $e');
    }
  }

  /// Iniciar sessão de analytics
  static Future<void> startSession() async {
    if (!_isInitialized) return;

    try {
      await manager.startSession();
      AppLogger.debug('🎬 Sessão de analytics iniciada');
    } catch (e) {
      AppLogger.error('❌ Erro ao iniciar sessão de analytics: $e');
    }
  }

  /// Finalizar sessão de analytics
  static Future<void> endSession() async {
    if (!_isInitialized) return;

    try {
      await manager.endSession();
      AppLogger.debug('🎬 Sessão de analytics finalizada');
    } catch (e) {
      AppLogger.error('❌ Erro ao finalizar sessão de analytics: $e');
    }
  }

  /// Verificar se analytics está habilitado
  static bool get isEnabled => _isInitialized && manager.isEnabled;

  /// Obter estatísticas do sistema
  static Map<String, dynamic> getSystemStats() {
    if (!_isInitialized) return {'initialized': false};

    return {
      'initialized': true,
      'manager_stats': manager.getStats(),
      'config': {
        'environment': AnalyticsConfig.isDevelopment
            ? 'development'
            : 'production',
        'active_providers': AnalyticsConfig.activeProviders,
        'app_version': AnalyticsConfig.appVersion,
      },
    };
  }

  /// Fazer dispose do sistema
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      AppLogger.info('🧹 Fazendo dispose da integração de Analytics');

      await manager.dispose();
      _isInitialized = false;

      AppLogger.debug('✅ Analytics integração disposed');
    } catch (e) {
      AppLogger.error('❌ Erro no dispose de Analytics: $e');
    }
  }
}

/// Extensão para AppLogger com integração automática de analytics
extension AnalyticsLogger on AppLogger {
  /// Log com envio automático para analytics
  static Future<void> analyticsEvent(
    String eventName, {
    Map<String, dynamic>? data,
    EventPriority priority = EventPriority.medium,
    EventCategory category = EventCategory.system,
  }) async {
    // Log normal
    AppLogger.debug('📊 Analytics Event: $eventName', data: data);

    // Enviar para analytics se inicializado
    if (AnalyticsIntegration.isEnabled) {
      try {
        await AnalyticsIntegration.manager.trackEvent(
          eventName,
          parameters: data,
          priority: priority,
          category: category,
        );
      } catch (e) {
        AppLogger.error('❌ Erro ao enviar evento para analytics: $e');
      }
    }
  }

  /// Log de performance com timing automático
  /// Log de performance com timing automático
  static Future<T> performanceEvent<T>(
    String operationName,
    Future<T> Function() operation, {
    String? category,
    Map<String, dynamic>? additionalData,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Executar operação
      final result = await operation();

      stopwatch.stop();
      final durationMs = stopwatch.elapsedMilliseconds;

      // Log normal
      AppLogger.debug('⏱️ Performance: $operationName (${durationMs}ms)');

      // Enviar para analytics
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackTiming(
          operationName,
          durationMs,
          category: category,
          parameters: additionalData,
        );
      }

      return result; // ✅ Now valid!
    } catch (e) {
      stopwatch.stop();

      // Log erro com timing
      AppLogger.error(
        '❌ Performance Error: $operationName (${stopwatch.elapsedMilliseconds}ms): $e',
      );

      // Enviar erro para analytics
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackError(
          'Performance error in $operationName',
          error: e,
          parameters: {
            'operation': operationName,
            'duration_ms': stopwatch.elapsedMilliseconds,
            ...?additionalData,
          },
        );
      }

      rethrow;
    }
  }
}

/// Extensão para facilitar tracking de eventos comuns
extension CommonAnalyticsEvents on AnalyticsManager {
  /// Eventos de autenticação
  Future<void> trackLogin(String method, {bool success = true}) async {
    await trackEvent(
      success ? 'user_login' : 'login_failed',
      parameters: {'method': method, 'success': success},
      category: EventCategory.user,
      priority: EventPriority.high,
    );
  }

  Future<void> trackLogout() async {
    await trackEvent(
      'user_logout',
      category: EventCategory.user,
      priority: EventPriority.medium,
    );
  }

  /// Eventos de navegação
  Future<void> trackNavigation(
    String from,
    String to, {
    int? durationMs,
  }) async {
    await trackEvent(
      'navigation',
      parameters: {
        'from_screen': from,
        'to_screen': to,
        if (durationMs != null) 'duration_ms': durationMs,
      },
      category: EventCategory.user,
    );
  }

  /// Eventos de UX
  Future<void> trackThemeChange(String newTheme) async {
    await trackEvent(
      'theme_changed',
      parameters: {'new_theme': newTheme},
      category: EventCategory.user,
    );
  }

  Future<void> trackFeatureUsage(
    String featureName, {
    Map<String, dynamic>? context,
  }) async {
    await trackEvent(
      'feature_used',
      parameters: {'feature_name': featureName, ...?context},
      category: EventCategory.user,
    );
  }

  /// Eventos de performance
  Future<void> trackAppStartup(int durationMs) async {
    await trackTiming('app_startup', durationMs, category: 'performance');
  }

  Future<void> trackScreenLoad(String screenName, int durationMs) async {
    await trackTiming(
      'screen_load',
      durationMs,
      category: 'performance',
      parameters: {'screen_name': screenName},
    );
  }

  /// Eventos de erro contextualizados
  Future<void> trackAuthError(String errorType, {String? details}) async {
    await trackError(
      'Authentication error occurred',
      parameters: {
        'error_type': errorType,
        if (details != null) 'details': details,
        'context': 'authentication',
      },
    );
  }

  Future<void> trackNetworkError(String operation, {int? statusCode}) async {
    await trackError(
      'Network error occurred',
      parameters: {
        'operation': operation,
        if (statusCode != null) 'status_code': statusCode,
        'context': 'network',
      },
    );
  }
}
