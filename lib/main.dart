// main.dart - ATUALIZADO PARA SISTEMA DE NAVEGAÇÃO ESCALÁVEL
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/firebase_options.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';
import 'package:unlock/services/notification_service.dart'; // Importar NotificationService
import 'package:unlock/unlockApp.dart';

/// Entry point da aplicação Unlock
void main() async {
  await _initializeApp();
}

/// Handler de mensagens em background do Firebase Messaging
/// Deve ser uma função de nível superior (fora de qualquer classe)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('📢 [Background Message] Received: ${message.messageId}');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.handleBackgroundMessage(message);
}

/// Inicializar aplicação com configuração completa
Future<void> _initializeApp() async {
  final initStartTime = DateTime.now();

  try {
    // ========== INICIALIZAÇÃO BÁSICA ==========

    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.info('✅ Flutter binding inicializado');

    // Configurar orientação do dispositivo
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    AppLogger.info('✅ Orientação configurada (portrait apenas)');

    // Configurar system UI
    await _configureSystemUI();

    // ========== INICIALIZAÇÃO DO FIREBASE ==========

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('✅ Firebase inicializado');

    // Configurar handler de mensagens em background do FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    AppLogger.info('✅ FCM background handler configurado');

    // ========== INICIALIZAÇÃO DO ANALYTICS ==========

    // await AnalyticsIntegration.initialize();
    // AppLogger.info('✅ Analytics inicializado');

    // ========== RASTREAMENTO DE INICIALIZAÇÃO ==========

    final initDuration = DateTime.now().difference(initStartTime);

    // Analytics: App inicializado
    try {
      await AnalyticsIntegration.manager.trackEvent(
        'app_initialized',
        parameters: {
          'init_duration_ms': initDuration.inMilliseconds,
          'platform':
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark
              ? 'dark'
              : 'light',
          'is_debug': kDebugMode,
        },
        category: EventCategory.system,
        priority: EventPriority.high,
      );
    } catch (e) {
      AppLogger.debug('Analytics initialization event failed: $e');
    }

    AppLogger.info(
      '✅ Aplicação inicializada com sucesso',
      data: {
        'duration_ms': initDuration.inMilliseconds,
        'is_debug': kDebugMode,
      },
    );

    // Inicializar o NotificationService (que também configura o foreground handler)
    // e verificar por navegação pendente.
    // Isso será feito no UnlockApp para ter acesso ao ref.
    // ========== EXECUTAR APP ==========

    runApp(
      ProviderScope(
        observers: kDebugMode ? [_ProviderLogger()] : [],
        child: const UnlockApp(),
      ),
    );
  } catch (error, stackTrace) {
    final initDuration = DateTime.now().difference(initStartTime);

    AppLogger.error(
      '❌ Erro fatal na inicialização',
      error: error,
      stackTrace: stackTrace,
      data: {
        'duration_ms': initDuration.inMilliseconds,
        'initialization_failed': true,
      },
    );

    // Em caso de erro crítico, executar app mínimo de erro
    runApp(_CriticalErrorApp(error: error, stackTrace: stackTrace));
  }
}

/// Configurar system UI (status bar, navigation bar)
Future<void> _configureSystemUI() async {
  // Configurar status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  AppLogger.info('✅ System UI configurado');
}

/// Observer de providers para debug
class _ProviderLogger extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    final providerName = provider.name ?? provider.runtimeType.toString();
    AppLogger.debug('🔧 Provider adicionado: $providerName');
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    final providerName = provider.name ?? provider.runtimeType.toString();
    AppLogger.debug('🗑️ Provider removido: $providerName');
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    final providerName = provider.name ?? provider.runtimeType.toString();

    // Log apenas para providers importantes para evitar spam
    if (_isImportantProvider(providerName)) {
      AppLogger.debug('🔄 Provider atualizado: $providerName');
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final providerName = provider.name ?? provider.runtimeType.toString();
    AppLogger.error(
      '❌ Provider falhou: $providerName',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Verificar se é um provider importante para logging
  bool _isImportantProvider(String providerName) {
    final importantKeywords = [
      'auth',
      'Auth',
      'navigation',
      'Navigation',
      'onboarding',
      'Onboarding',
      'theme',
      'Theme',
      'user',
      'User',
    ];

    return importantKeywords.any(
      (keyword) => providerName.toLowerCase().contains(keyword.toLowerCase()),
    );
  }
}

/// App mínimo para casos de erro crítico
class _CriticalErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const _CriticalErrorApp({required this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unlock - Erro Crítico',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _CriticalErrorScreen(error: error, stackTrace: stackTrace),
    );
  }
}

/// Tela de erro crítico
class _CriticalErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const _CriticalErrorScreen({required this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de erro
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade700,
                  ),
                ),

                const SizedBox(height: 32),

                // Título
                Text(
                  'Erro Fatal',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),

                const SizedBox(height: 16),

                // Descrição
                Text(
                  'O aplicativo não pôde ser iniciado devido a um erro crítico.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Detalhes do erro (apenas em debug)
                if (kDebugMode) ...[
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalhes do Erro (Debug):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Colors.red.shade700,
                            ),
                          ),
                          if (stackTrace != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Stack Trace:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stackTrace.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],

                // Botões de ação
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Tentar reinicializar o app
                        main();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informações de suporte
                Text(
                  'Se o problema persistir, contate o suporte.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.red.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
