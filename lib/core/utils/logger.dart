// lib/core/utils/logger.dart - Sistema de Logs Centralizado
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Importação adicionada para Crashlytics
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Sistema de logs centralizado para o app Unlock
///
/// Uso:
/// ```dart
/// AppLogger.info('Usuário logado com sucesso', data: {'uid': user.uid});
/// AppLogger.error('Erro no login', error: e, stackTrace: stackTrace);
/// AppLogger.debug('Estado do provider', data: {'state': state.toString()});
/// ```
class AppLogger {
  static late Logger _logger;
  static bool _isInitialized = false;

  // Configuração inicial do logger
  static void initialize({
    bool enableInRelease = false,
    Level logLevel = Level.debug,
  }) {
    if (_isInitialized) return;

    _logger = Logger(
      filter: AppLogFilter(
        enableInRelease: enableInRelease,
      ), // Corrigido: Usando AppLogFilter
      printer: _AppLogPrinter(),
      // output: _AppLogOutput(), // Removido: Lógica de Crashlytics movida para _AppLogPrinter
      level: logLevel, // Garante que o nível de log configurado seja aplicado
    );

    _isInitialized = true;
    info('🚀 AppLogger inicializado');
  }

  // Logs de informação (fluxos principais)
  static void info(
    String message, {
    Map<String, dynamic>? data,
    String? feature,
  }) {
    _ensureInitialized();
    final formattedMessage = _formatMessage(message, data, feature);
    _logger.i(formattedMessage);
  }

  // Logs de debug (desenvolvimento)
  static void debug(
    String message, {
    Map<String, dynamic>? data,
    String? feature,
  }) {
    _ensureInitialized();
    final formattedMessage = _formatMessage(message, data, feature);
    _logger.d(formattedMessage);
  }

  // Logs de warning (situações inesperadas mas não críticas)
  static void warning(
    String message, {
    Map<String, dynamic>? data,
    String? feature,
  }) {
    _ensureInitialized();
    final formattedMessage = _formatMessage(message, data, feature);
    _logger.w(formattedMessage);
  }

  // Logs de erro (falhas e exceções)
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? feature,
  }) {
    _ensureInitialized();
    _logger.e(
      // Passa a mensagem, erro e stackTrace para o logger
      _formatMessage(message, data, feature),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Logs críticos (falhas graves do sistema)
  static void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? feature,
  }) {
    _ensureInitialized();
    _logger.f(
      // Passa a mensagem, erro e stackTrace para o logger
      _formatMessage(message, data, feature),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Logs específicos para features
  static void auth(String message, {Map<String, dynamic>? data}) {
    info(message, data: data, feature: 'AUTH');
  }

  static void firestore(String message, {Map<String, dynamic>? data}) {
    debug(message, data: data, feature: 'FIRESTORE');
  }

  static void navigation(String message, {Map<String, dynamic>? data}) {
    debug(message, data: data, feature: 'NAVIGATION');
  }

  static void missions(String message, {Map<String, dynamic>? data}) {
    info(message, data: data, feature: 'MISSIONS');
  }

  static void connections(String message, {Map<String, dynamic>? data}) {
    info(message, data: data, feature: 'CONNECTIONS');
  }

  static void security(String message, {Map<String, dynamic>? data}) {
    warning(message, data: data, feature: 'SECURITY');
  }

  // Utilitários internos
  static void _ensureInitialized() {
    if (!_isInitialized) {
      initialize(); // Inicialização padrão se não foi feita
    }
  }

  static String _formatMessage(
    String message,
    Map<String, dynamic>? data,
    String? feature,
  ) {
    final buffer = StringBuffer();

    if (feature != null) {
      buffer.write('[$feature] ');
    }

    buffer.write(message);

    if (data != null && data.isNotEmpty) {
      buffer.write(' | Data: ${data.toString()}');
    }

    return buffer.toString();
  }
}

/// Filtro personalizado para controlar quando logs são exibidos
class AppLogFilter extends LogFilter {
  // Renomeado para classe pública
  final bool enableInRelease;

  AppLogFilter({this.enableInRelease = false});

  @override
  bool shouldLog(LogEvent event) {
    // Em debug, sempre loga
    if (kDebugMode) return true;

    // Em release, só loga se explicitamente habilitado
    if (enableInRelease) return true;

    // Em release por padrão, só loga erros críticos
    return event.level == Level.error || event.level == Level.fatal;
  }
}

/// Formatador personalizado para logs mais legíveis
class _AppLogPrinter extends PrettyPrinter {
  _AppLogPrinter()
    : super(
        stackTraceBeginIndex: 1,
        methodCount: 3,
        errorMethodCount: 8,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        printTime: true,
      );

  @override
  List<String> log(LogEvent event) {
    // Primeiro, obtenha as linhas formatadas do log (para console)
    final originalLog = super.log(event);

    // Em desenvolvimento, printar no console
    if (kDebugMode) {
      // Adicionar timestamp mais legível
      final timestamp = DateTime.now().toIso8601String().substring(11, 23);
      if (originalLog.isNotEmpty) {
        originalLog[0] = '🔓 UNLOCK [$timestamp] ${originalLog[0]}';
      }
      for (final line in originalLog) {
        print(line);
      }
    }

    // Em produção, enviar logs críticos para Firebase Crashlytics
    if (!kDebugMode &&
        (event.level == Level.error || event.level == Level.fatal)) {
      final error = event.error; // O objeto de erro original
      if (error != null) {
        // A mensagem formatada já está em originalLog.first
        final reason = originalLog.isNotEmpty
            ? originalLog.first
            : 'No message provided';
        FirebaseCrashlytics.instance.recordError(
          error,
          event.stackTrace,
          reason:
              'AppLogger: ${event.level.toString().split('.').last.toUpperCase()} - $reason',
          fatal: event.level == Level.fatal,
        );
      }
    }

    // Retorna as linhas formatadas para o LogOutput (se houver um)
    // Como _AppLogOutput foi removido, isso é apenas para compatibilidade interna do logger.
    return originalLog;
  }
}

/// Extensão para facilitar logging em classes
extension LoggerExtension on Object {
  void logInfo(String message, {Map<String, dynamic>? data}) {
    AppLogger.info('${runtimeType}: $message', data: data);
  }

  void logDebug(String message, {Map<String, dynamic>? data}) {
    AppLogger.debug('${runtimeType}: $message', data: data);
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.error(
      '${runtimeType}: $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logWarning(String message, {Map<String, dynamic>? data}) {
    AppLogger.warning('${runtimeType}: $message', data: data);
  }
}

/// Configurações específicas para diferentes ambientes
class LoggerConfig {
  static void setupForDevelopment() {
    AppLogger.initialize(enableInRelease: false, logLevel: Level.debug);
  }

  static void setupForStaging() {
    AppLogger.initialize(enableInRelease: true, logLevel: Level.info);
  }

  static void setupForProduction() {
    AppLogger.initialize(enableInRelease: false, logLevel: Level.error);
  }
}
