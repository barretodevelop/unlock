// lib/services/analytics/crash_reporting_service.dart
import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';

/// Serviço especializado para relatório de crashes e erros
///
/// Intercepta erros não tratados, coleta contexto útil
/// e envia relatórios para o sistema de analytics.
class CrashReportingService {
  static CrashReportingService? _instance;
  static CrashReportingService get instance =>
      _instance ??= CrashReportingService._();

  CrashReportingService._();

  bool _isInitialized = false;
  final Map<String, String> _globalContext = {};
  final List<_CrashReport> _pendingReports = [];

  /// Inicializar o serviço de crash reporting
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🚨 Inicializando Crash Reporting Service...');

      // Configurar handlers de erro
      _setupErrorHandlers();

      // Configurar contexto global
      _setupGlobalContext();

      _isInitialized = true;

      AppLogger.info('✅ Crash Reporting Service inicializado');
    } catch (e) {
      AppLogger.error('❌ Erro ao inicializar Crash Reporting Service: $e');
    }
  }

  /// Configurar handlers de erro do Flutter
  void _setupErrorHandlers() {
    // Handler para erros no Flutter framework
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Handler para erros em isolates
    Isolate.current.addErrorListener(
      RawReceivePort((pair) {
        final List<dynamic> errorAndStacktrace = pair;
        _handleIsolateError(
          errorAndStacktrace.first,
          errorAndStacktrace.length > 1 ? errorAndStacktrace.last : null,
        );
      }).sendPort,
    );

    // Handler para erros não capturados em zones
    if (!kIsWeb) {
      runZonedGuarded(
        () {
          // Nada aqui, apenas configurar o handler
        },
        (error, stackTrace) {
          _handleZoneError(error, stackTrace);
        },
      );
    }

    AppLogger.debug('🚨 Error handlers configurados');
  }

  /// Configurar contexto global
  void _setupGlobalContext() {
    _globalContext.addAll({
      'platform': defaultTargetPlatform.name,
      'debug_mode': kDebugMode.toString(),
      'web_mode': kIsWeb.toString(),
      'profile_mode': kProfileMode.toString(),
      'release_mode': kReleaseMode.toString(),
    });

    AppLogger.debug('🚨 Contexto global configurado', data: _globalContext);
  }

  /// Reportar erro manualmente
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? customData,
    bool fatal = false,
    String? userId,
  }) async {
    if (!_isInitialized) return;

    try {
      AppLogger.error(
        '🚨 Reportando erro: ${error.runtimeType}',
        error: error,
        stackTrace: stackTrace,
      );

      final report = _CrashReport(
        error: error,
        stackTrace: stackTrace,
        context: context ?? 'manual_report',
        customData: customData ?? {},
        fatal: fatal,
        userId: userId,
        timestamp: DateTime.now(),
        globalContext: Map.from(_globalContext),
      );

      // Adicionar à lista de reports pendentes
      _pendingReports.add(report);

      // Enviar para analytics
      await _sendToAnalytics(report);

      // Log do report
      AppLogger.info(
        '✅ Crash report enviado',
        data: {
          'error_type': error.runtimeType.toString(),
          'fatal': fatal,
          'context': context,
          'has_stack_trace': stackTrace != null,
        },
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao reportar crash: $e');
    }
  }

  /// Adicionar contexto customizado
  void setCustomContext(String key, String value) {
    _globalContext[key] = value;
    AppLogger.debug('🚨 Contexto customizado adicionado: $key = $value');
  }

  /// Remover contexto customizado
  void removeCustomContext(String key) {
    _globalContext.remove(key);
    AppLogger.debug('🚨 Contexto customizado removido: $key');
  }

  /// Limpar todo contexto customizado
  void clearCustomContext() {
    final keysToRemove = _globalContext.keys
        .where(
          (key) => ![
            'platform',
            'debug_mode',
            'web_mode',
            'profile_mode',
            'release_mode',
          ].contains(key),
        )
        .toList();

    for (final key in keysToRemove) {
      _globalContext.remove(key);
    }

    AppLogger.debug('🚨 Contexto customizado limpo');
  }

  /// Adicionar breadcrumb (rastro de ações)
  void addBreadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    AppLogger.debug(
      '🍞 Breadcrumb: $message',
      data: {'category': category ?? 'user_action', ...?data},
    );

    // TODO: Implementar sistema de breadcrumbs persistente
    // Por enquanto, apenas log
  }

  /// Log personalizado
  void log(String message, {String? level}) {
    AppLogger.info('📝 Crash log: $message', data: {'level': level ?? 'info'});
  }

  /// Handler para erros do Flutter
  void _handleFlutterError(FlutterErrorDetails details) {
    // Log do erro
    AppLogger.error(
      '🚨 Flutter Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );

    // Reportar se não for modo debug ou se for erro crítico
    if (!kDebugMode || _isCriticalError(details.exception)) {
      recordError(
        details.exception,
        stackTrace: details.stack,
        context: 'flutter_framework',
        customData: {
          'library': details.library,
          'context': details.context?.toString() ?? 'unknown',
          'silent': details.silent.toString(),
        },
        fatal: _isCriticalError(details.exception),
      );
    }
  }

  /// Handler para erros em isolates
  void _handleIsolateError(dynamic error, dynamic stackTrace) {
    AppLogger.error(
      '🚨 Isolate Error: $error',
      error: error,
      stackTrace: stackTrace,
    );

    recordError(
      error,
      stackTrace: stackTrace is StackTrace ? stackTrace : null,
      context: 'isolate',
      fatal: true, // Erros de isolate são geralmente críticos
    );
  }

  /// Handler para erros em zones
  void _handleZoneError(Object error, StackTrace stackTrace) {
    AppLogger.error(
      '🚨 Zone Error: $error',
      error: error,
      stackTrace: stackTrace,
    );

    recordError(error, stackTrace: stackTrace, context: 'zone', fatal: false);
  }

  /// Verificar se é um erro crítico
  bool _isCriticalError(Object error) {
    final errorString = error.toString().toLowerCase();

    // Padrões que indicam erros críticos
    final criticalPatterns = [
      'out of memory',
      'stackoverflow',
      'segmentation fault',
      'access violation',
      'null pointer',
      'assertion failed',
    ];

    return criticalPatterns.any((pattern) => errorString.contains(pattern));
  }

  /// Enviar report para analytics
  Future<void> _sendToAnalytics(_CrashReport report) async {
    if (!AnalyticsIntegration.isEnabled) return;

    try {
      await AnalyticsIntegration.manager.trackError(
        'Crash/Error Report',
        error: report.error,
        stackTrace: report.stackTrace,
        fatal: report.fatal,
        parameters: {
          'context': report.context,
          'error_type': report.error.runtimeType.toString(),
          'timestamp': report.timestamp.toIso8601String(),
          'platform': report.globalContext['platform'] ?? 'unknown',
          'debug_mode': report.globalContext['debug_mode'] ?? 'unknown',
          ...report.customData,
        },
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao enviar crash report para analytics: $e');
    }
  }

  /// Obter estatísticas de crash reports
  Map<String, dynamic> getStats() {
    final errorTypes = <String, int>{};
    final contexts = <String, int>{};
    int fatalCount = 0;

    for (final report in _pendingReports) {
      final errorType = report.error.runtimeType.toString();
      errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;

      contexts[report.context] = (contexts[report.context] ?? 0) + 1;

      if (report.fatal) fatalCount++;
    }

    return {
      'total_reports': _pendingReports.length,
      'fatal_reports': fatalCount,
      'non_fatal_reports': _pendingReports.length - fatalCount,
      'error_types': errorTypes,
      'contexts': contexts,
      'global_context_keys': _globalContext.keys.toList(),
    };
  }

  /// Obter reports recentes
  List<Map<String, dynamic>> getRecentReports({int limit = 50}) {
    return _pendingReports
        .take(limit)
        .map((report) => report.toJson())
        .toList();
  }

  /// Limpar reports antigos
  void _cleanupOldReports() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));

    _pendingReports.removeWhere((report) => report.timestamp.isBefore(cutoff));

    AppLogger.debug('🧹 Limpeza de crash reports concluída');
  }

  /// Fazer dispose do serviço
  Future<void> dispose() async {
    AppLogger.info('🧹 Disposing Crash Reporting Service');

    // Tentar enviar reports pendentes
    for (final report in _pendingReports) {
      try {
        await _sendToAnalytics(report);
      } catch (e) {
        AppLogger.error('❌ Erro ao enviar report pendente: $e');
      }
    }

    _pendingReports.clear();
    _globalContext.clear();

    _isInitialized = false;
    _instance = null;
  }
}

/// Classe para representar um crash report
class _CrashReport {
  final Object error;
  final StackTrace? stackTrace;
  final String context;
  final Map<String, dynamic> customData;
  final bool fatal;
  final String? userId;
  final DateTime timestamp;
  final Map<String, String> globalContext;

  _CrashReport({
    required this.error,
    this.stackTrace,
    required this.context,
    required this.customData,
    required this.fatal,
    this.userId,
    required this.timestamp,
    required this.globalContext,
  });

  Map<String, dynamic> toJson() {
    return {
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      'context': context,
      'custom_data': customData,
      'fatal': fatal,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'global_context': globalContext,
      'has_stack_trace': stackTrace != null,
    };
  }
}

/// Extensão para facilitar uso do CrashReportingService
extension CrashReportingExtension on Object {
  /// Reportar erro com contexto da classe
  Future<void> reportError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? customData,
    bool fatal = false,
  }) async {
    await CrashReportingService.instance.recordError(
      error,
      stackTrace: stackTrace,
      context: runtimeType.toString(),
      customData: customData,
      fatal: fatal,
    );
  }

  /// Adicionar breadcrumb com contexto da classe
  void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    CrashReportingService.instance.addBreadcrumb(
      message,
      category: runtimeType.toString(),
      data: data,
    );
  }
}
