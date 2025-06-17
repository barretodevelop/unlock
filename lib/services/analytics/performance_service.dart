// lib/services/analytics/performance_service.dart
import 'dart:async';
import 'dart:collection';

import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

/// Serviço especializado para monitoramento de performance
///
/// Coleta métricas de performance, monitora operações críticas
/// e envia dados para o sistema de analytics.
class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance =>
      _instance ??= PerformanceService._();

  PerformanceService._();

  final Map<String, _PerformanceTrace> _activeTraces = {};
  final Queue<_PerformanceMetric> _metrics = Queue<_PerformanceMetric>();
  final Map<String, List<int>> _operationTimes = {};

  bool _isInitialized = false;
  Timer? _reportTimer;

  /// Inicializar o serviço de performance
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('⚡ Inicializando Performance Service...');

      // Configurar relatório periódico
      _setupPeriodicReporting();

      _isInitialized = true;

      AppLogger.info('✅ Performance Service inicializado');
    } catch (e) {
      AppLogger.error('❌ Erro ao inicializar Performance Service: $e');
    }
  }

  /// Iniciar medição de uma operação
  PerformanceTrace startTrace(String name, {Map<String, String>? attributes}) {
    final trace = _PerformanceTrace(
      name: name,
      startTime: DateTime.now(),
      attributes: attributes ?? {},
      onStop: (trace) => _onTraceCompleted(trace),
    );

    _activeTraces[name] = trace;

    AppLogger.debug('⚡ Performance trace iniciada: $name', data: attributes);

    return trace;
  }

  /// Medir tempo de execução de uma função
  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
    bool trackToAnalytics = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.debug('⚡ Iniciando operação: $operationName');

      final result = await operation();

      stopwatch.stop();
      final durationMs = stopwatch.elapsedMilliseconds;

      // Registrar métrica
      _recordMetric(operationName, durationMs, attributes);

      // Enviar para analytics se habilitado
      if (trackToAnalytics && AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackTiming(
          operationName,
          durationMs,
          category: 'performance',
          parameters: {'success': true, ...?attributes},
        );
      }

      AppLogger.debug('✅ Operação concluída: $operationName (${durationMs}ms)');

      return result;
    } catch (e) {
      stopwatch.stop();
      final durationMs = stopwatch.elapsedMilliseconds;

      // Registrar métrica de erro
      _recordMetric('${operationName}_error', durationMs, {
        'error': e.runtimeType.toString(),
        ...?attributes,
      });

      // Enviar erro para analytics
      if (trackToAnalytics && AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackError(
          'Performance operation failed: $operationName',
          error: e,
          parameters: {
            'operation': operationName,
            'duration_ms': durationMs,
            ...?attributes,
          },
        );
      }

      AppLogger.error(
        '❌ Operação falhou: $operationName (${durationMs}ms): $e',
      );

      rethrow;
    }
  }

  /// Registrar métrica de rede
  Future<void> recordNetworkMetric({
    required String url,
    required String method,
    required int statusCode,
    required int durationMs,
    int? requestSize,
    int? responseSize,
  }) async {
    final attributes = {
      'method': method,
      'status_code': statusCode.toString(),
      if (requestSize != null) 'request_size': requestSize.toString(),
      if (responseSize != null) 'response_size': responseSize.toString(),
    };

    _recordMetric('network_request', durationMs, attributes);

    AppLogger.debug(
      '🌐 Network metric: $method $url ($statusCode, ${durationMs}ms)',
    );

    // Enviar para analytics
    if (AnalyticsIntegration.isEnabled) {
      await AnalyticsIntegration.manager.trackTiming(
        'network_request',
        durationMs,
        category: 'network',
        parameters: {
          'url_domain': Uri.tryParse(url)?.host ?? 'unknown',
          'method': method,
          'status_code': statusCode,
          'success': statusCode >= 200 && statusCode < 300,
          ...attributes,
        },
      );
    }
  }

  /// Registrar métrica de uso de memória
  Future<void> recordMemoryUsage(int memoryMB) async {
    _recordMetric('memory_usage', memoryMB, {'unit': 'MB'});

    AppLogger.debug('🧠 Memory usage: ${memoryMB}MB');

    // Enviar para analytics apenas se for valor significativo
    if (memoryMB > 100 && AnalyticsIntegration.isEnabled) {
      await AnalyticsIntegration.manager.trackEvent(
        'memory_usage_high',
        parameters: {'memory_mb': memoryMB, 'threshold': 100},
        category: EventCategory.performance,
      );
    }
  }

  /// Registrar métrica de FPS
  Future<void> recordFrameRate(double fps) async {
    _recordMetric('frame_rate', fps.round(), {'unit': 'fps'});

    // Alertar se FPS estiver baixo
    if (fps < 30) {
      AppLogger.warning('⚠️ FPS baixo detectado: ${fps.toStringAsFixed(1)}');

      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          'low_fps_detected',
          parameters: {'fps': fps, 'threshold': 30},
          category: EventCategory.performance,
          priority: EventPriority.high,
        );
      }
    }
  }

  /// Medir tempo de carregamento de tela
  Future<void> measureScreenLoad(
    String screenName,
    Future<void> Function() loadOperation,
  ) async {
    await measureOperation(
      'screen_load_$screenName',
      loadOperation,
      attributes: {'screen_name': screenName},
    );
  }

  /// Medir tempo de operação de database
  Future<T> measureDatabaseOperation<T>(
    String operation,
    Future<T> Function() dbOperation, {
    String? collection,
    String? document,
  }) async {
    return await measureOperation(
      'database_$operation',
      dbOperation,
      attributes: {
        'operation': operation,
        if (collection != null) 'collection': collection,
        if (document != null) 'document': document,
      },
    );
  }

  /// Obter estatísticas de performance
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{
      'active_traces': _activeTraces.length,
      'total_metrics': _metrics.length,
      'operation_averages': <String, double>{},
    };

    // Calcular médias por operação
    for (final entry in _operationTimes.entries) {
      if (entry.value.isNotEmpty) {
        final average =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
        stats['operation_averages'][entry.key] = average;
      }
    }

    return stats;
  }

  /// Obter métricas recentes
  List<Map<String, dynamic>> getRecentMetrics({int limit = 100}) {
    return _metrics.take(limit).map((metric) => metric.toJson()).toList();
  }

  /// Configurar relatório periódico
  void _setupPeriodicReporting() {
    _reportTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _generatePerformanceReport();
    });
  }

  /// Gerar relatório de performance
  Future<void> _generatePerformanceReport() async {
    if (!AnalyticsIntegration.isEnabled) return;

    try {
      final stats = getPerformanceStats();

      await AnalyticsIntegration.manager.trackEvent(
        'performance_report',
        parameters: {
          'active_traces': stats['active_traces'],
          'total_metrics': stats['total_metrics'],
          'avg_operations': (stats['operation_averages'] as Map).length,
          'report_interval': 'minutes_5',
        },
        category: EventCategory.system,
        priority: EventPriority.low,
      );

      AppLogger.debug('📊 Relatório de performance enviado', data: stats);
    } catch (e) {
      AppLogger.error('❌ Erro ao gerar relatório de performance: $e');
    }
  }

  /// Callback quando trace é completada
  void _onTraceCompleted(_PerformanceTrace trace) {
    _activeTraces.remove(trace.name);

    final durationMs = trace.duration.inMilliseconds;
    _recordMetric(trace.name, durationMs, trace.attributes);

    AppLogger.debug(
      '⚡ Performance trace concluída: ${trace.name} (${durationMs}ms)',
    );
  }

  /// Registrar métrica interna
  void _recordMetric(String name, int value, Map<String, String>? attributes) {
    final metric = _PerformanceMetric(
      name: name,
      value: value,
      timestamp: DateTime.now(),
      attributes: attributes ?? {},
    );

    _metrics.add(metric);

    // Manter apenas as últimas 1000 métricas
    while (_metrics.length > 1000) {
      _metrics.removeFirst();
    }

    // Registrar tempo da operação para cálculos de média
    if (!_operationTimes.containsKey(name)) {
      _operationTimes[name] = [];
    }
    _operationTimes[name]!.add(value);

    // Manter apenas os últimos 100 tempos por operação
    if (_operationTimes[name]!.length > 100) {
      _operationTimes[name]!.removeAt(0);
    }
  }

  /// Limpar dados antigos
  void _cleanupOldData() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));

    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoff));

    AppLogger.debug('🧹 Limpeza de dados de performance concluída');
  }

  /// Fazer dispose do serviço
  Future<void> dispose() async {
    AppLogger.info('🧹 Disposing Performance Service');

    _reportTimer?.cancel();

    // Completar todas as traces ativas
    for (final trace in _activeTraces.values) {
      trace.stop();
    }

    _activeTraces.clear();
    _metrics.clear();
    _operationTimes.clear();

    _isInitialized = false;
    _instance = null;
  }
}

/// Implementação interna de PerformanceTrace
class _PerformanceTrace implements PerformanceTrace {
  @override
  final String name;

  final DateTime startTime;
  final Map<String, String> attributes;
  final Map<String, int> metrics = {};
  final void Function(_PerformanceTrace) onStop;

  bool _stopped = false;

  _PerformanceTrace({
    required this.name,
    required this.startTime,
    required this.attributes,
    required this.onStop,
  });

  Duration get duration => DateTime.now().difference(startTime);

  @override
  void putMetric(String metricName, int value) {
    if (_stopped) return;

    metrics[metricName] = value;
    AppLogger.debug('⚡ Métrica adicionada: $name.$metricName = $value');
  }

  @override
  void putAttribute(String attributeName, String value) {
    if (_stopped) return;

    attributes[attributeName] = value;
    AppLogger.debug('⚡ Atributo adicionado: $name.$attributeName = $value');
  }

  @override
  void stop() {
    if (_stopped) return;

    _stopped = true;
    onStop(this);
  }
}

/// Classe para representar uma métrica de performance
class _PerformanceMetric {
  final String name;
  final int value;
  final DateTime timestamp;
  final Map<String, String> attributes;

  _PerformanceMetric({
    required this.name,
    required this.value,
    required this.timestamp,
    required this.attributes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'attributes': attributes,
    };
  }
}

/// Extensão para facilitar uso do PerformanceService
extension PerformanceExtension on Object {
  /// Medir performance de um método
  Future<T> measurePerformance<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    return await PerformanceService.instance.measureOperation(
      '${runtimeType}_$operationName',
      operation,
      attributes: attributes,
    );
  }

  /// Iniciar trace de performance
  PerformanceTrace startPerformanceTrace(
    String traceName, {
    Map<String, String>? attributes,
  }) {
    return PerformanceService.instance.startTrace(
      '${runtimeType}_$traceName',
      attributes: attributes,
    );
  }
}
