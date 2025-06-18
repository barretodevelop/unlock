// lib/services/analytics/interfaces/analytics_interface.dart

/// Interface principal para serviços de analytics
///
/// Permite trocar facilmente entre diferentes provedores (Firebase, Amplitude, etc.)
/// sem alterar o código que usa analytics.
abstract class AnalyticsInterface {
  /// Nome do provider (ex: 'firebase', 'amplitude', 'mock')
  String get providerName;

  /// Inicializar o serviço de analytics
  Future<void> initialize();

  /// Rastrear evento personalizado
  ///
  /// [event] Nome do evento (ex: 'user_login', 'screen_view')
  /// [parameters] Dados adicionais do evento
  Future<void> trackEvent(String event, {Map<String, dynamic>? parameters});

  /// Definir ID do usuário
  Future<void> setUserId(String? userId);

  /// Definir propriedade do usuário
  ///
  /// [key] Nome da propriedade (ex: 'user_type', 'subscription_level')
  /// [value] Valor da propriedade
  Future<void> setUserProperty(String key, String value);

  /// Rastrear visualização de tela
  ///
  /// [screenName] Nome da tela (ex: 'home_screen', 'login_screen')
  /// [screenClass] Classe da tela (opcional)
  Future<void> trackScreen(
    String screenName, {
    String? screenClass,
    Map<String, dynamic>? parameters,
  });

  /// Rastrear tempo de execução/performance
  ///
  /// [name] Nome da métrica (ex: 'app_startup', 'login_duration')
  /// [durationMs] Duração em milissegundos
  /// [category] Categoria (opcional, ex: 'performance', 'network')
  Future<void> trackTiming(
    String name,
    int durationMs, {
    String? category,
    Map<String, dynamic>? parameters,
  });

  /// Rastrear erro/exceção
  ///
  /// [description] Descrição do erro
  /// [error] Objeto de erro (opcional)
  /// [stackTrace] Stack trace (opcional)
  /// [fatal] Se o erro é fatal (padrão: false)
  Future<void> trackError(
    String description, {
    Object? error,
    StackTrace? stackTrace,
    bool fatal = false,
    Map<String, dynamic>? parameters,
  });

  /// Rastrear conversão/objetivo atingido
  ///
  /// [goalName] Nome do objetivo (ex: 'registration_complete', 'first_purchase')
  /// [value] Valor monetário (opcional)
  Future<void> trackConversion(
    String goalName, {
    double? value,
    String? currency,
    Map<String, dynamic>? parameters,
  });

  /// Iniciar sessão de usuário
  Future<void> startSession();

  /// Finalizar sessão de usuário
  Future<void> endSession();

  /// Forçar envio de eventos pendentes
  Future<void> flush();

  /// Resetar dados do usuário (útil para logout)
  Future<void> reset();

  /// Verificar se o provider está habilitado
  bool get isEnabled;

  /// Limpar recursos e finalizar o serviço
  Future<void> dispose();
}

/// Interface para controle de performance
abstract class PerformanceInterface {
  /// Iniciar rastreamento de performance para uma operação
  PerformanceTrace startTrace(String name);

  /// Rastrear tempo de carregamento de rede
  Future<void> trackNetworkRequest(
    String url,
    String method,
    int statusCode,
    int responseTimeMs, {
    int? responseSize,
  });

  /// Rastrear uso de memória
  Future<void> trackMemoryUsage(int memoryUsageMB);

  /// Rastrear FPS (frames per second)
  Future<void> trackFrameRate(double fps);
}

/// Classe para rastreamento de performance de operações específicas
abstract class PerformanceTrace {
  /// Nome da operação
  String get name;

  /// Adicionar métrica personalizada
  void putMetric(String metricName, int value);

  /// Adicionar atributo personalizado
  void putAttribute(String attributeName, String value);

  /// Finalizar rastreamento
  void stop();
}

/// Interface para relatórios de crash
abstract class CrashReportingInterface {
  /// Reportar crash/exceção
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  });

  /// Adicionar log personalizado
  Future<void> log(String message);

  /// Definir chave personalizada para contexto
  Future<void> setCustomKey(String key, String value);

  /// Definir informações do usuário
  Future<void> setUserIdentifier(String identifier);
}

/// Enum para níveis de prioridade de eventos
enum EventPriority {
  low, // Eventos de debug, desenvolvimento
  medium, // Eventos importantes mas não críticos
  high, // Eventos críticos de negócio
  critical, // Eventos essenciais (ex: crashes, conversões)
}

/// Enum para categorias de eventos
enum EventCategory {
  user, // Ações do usuário
  system, // Eventos do sistema
  performance, // Métricas de performance
  business, // Métricas de negócio
  debug, // Eventos de debug
  error, // Erros e exceções
  auth, // Erros e exceções
}

/// Classe para configuração de eventos
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic>? parameters;
  final EventPriority priority;
  final EventCategory category;
  final DateTime? timestamp;

  AnalyticsEvent({
    required this.name,
    this.parameters,
    this.priority = EventPriority.medium,
    this.category = EventCategory.user,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  AnalyticsEvent copyWith({
    String? name,
    Map<String, dynamic>? parameters,
    EventPriority? priority,
    EventCategory? category,
    DateTime? timestamp,
  }) {
    return AnalyticsEvent(
      name: name ?? this.name,
      parameters: parameters ?? this.parameters,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'priority': priority.name,
      'category': category.name,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AnalyticsEvent(name: $name, category: ${category.name}, priority: ${priority.name})';
  }
}
