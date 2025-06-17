// lib/main.dart - Configuração Principal com Analytics
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/theme_provider.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/background_service.dart';
import 'package:unlock/shared/screens/splash_screen.dart';

// Configurações do Firebase (mover para arquivo separado se necessário)
// import 'firebase_options.dart';

void main() async {
  // Garantir inicialização dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientação (apenas portrait por padrão)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Medir tempo de inicialização
  final initStartTime = DateTime.now();

  try {
    // Inicializar sistema de logs baseado no ambiente
    _initializeLogger();

    AppLogger.info('🚀 Iniciando app Unlock v${AppConstants.appVersion}');

    // Inicializar Firebase
    await _initializeFirebase();

    // Inicializar sistema de analytics
    await _initializeAnalytics();

    // Inicializar serviços de background
    await _initializeBackgroundServices();

    // Configurações de status bar
    _configureSystemUI();

    // Calcular tempo de inicialização
    final initDuration = DateTime.now().difference(initStartTime);
    AppLogger.info(
      '✅ Inicialização completa em ${initDuration.inMilliseconds}ms',
    );

    // Rastrear tempo de inicialização
    await _trackAppStartup(initDuration.inMilliseconds);

    // Iniciar app com provider
    runApp(ProviderScope(child: const UnlockApp()));
  } catch (error, stackTrace) {
    final initDuration = DateTime.now().difference(initStartTime);

    AppLogger.fatal(
      'Erro crítico na inicialização do app após ${initDuration.inMilliseconds}ms',
      error: error,
      stackTrace: stackTrace,
    );

    // Tentar rastrear erro de inicialização
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackError(
          'App initialization failed',
          error: error,
          stackTrace: stackTrace,
          fatal: true,
          parameters: {
            'init_duration_ms': initDuration.inMilliseconds,
            'flutter_version': '3.8.1',
          },
        );
      }
    } catch (e) {
      AppLogger.error('Falha ao rastrear erro de inicialização: $e');
    }

    // Em caso de erro crítico, mostrar tela de erro
    runApp(_ErrorApp(error: error));
  }
}

/// Configurar sistema de logs baseado no ambiente
void _initializeLogger() {
  if (kDebugMode) {
    LoggerConfig.setupForDevelopment();
  } else if (kProfileMode) {
    LoggerConfig.setupForStaging();
  } else {
    LoggerConfig.setupForProduction();
  }
}

/// Inicializar Firebase
Future<void> _initializeFirebase() async {
  try {
    AppLogger.info('🔥 Inicializando Firebase...');

    final stopwatch = Stopwatch()..start();

    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );

    stopwatch.stop();

    AppLogger.info(
      '✅ Firebase inicializado em ${stopwatch.elapsedMilliseconds}ms',
    );
  } catch (error, stackTrace) {
    AppLogger.error(
      'Erro ao inicializar Firebase',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

/// Inicializar sistema de analytics
Future<void> _initializeAnalytics() async {
  try {
    AppLogger.info('📊 Inicializando Analytics...');

    final stopwatch = Stopwatch()..start();

    await AnalyticsIntegration.initialize();

    stopwatch.stop();

    AppLogger.info(
      '✅ Analytics inicializado em ${stopwatch.elapsedMilliseconds}ms',
      data: {
        'providers':
            AnalyticsIntegration.getSystemStats()['config']['active_providers'],
      },
    );
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Erro ao inicializar Analytics (continuando sem analytics)',
      // error: error,
      // stackTrace: stackTrace,
    );
    // Não interromper o app por falha em analytics
  }
}

/// Inicializar serviços de background
Future<void> _initializeBackgroundServices() async {
  try {
    AppLogger.info('⚙️ Inicializando serviços de background...');

    // Inicializar background service se não estiver em desenvolvimento web
    if (!kIsWeb) {
      await BackgroundService.initialize();
      AppLogger.info('✅ Background service inicializado');
    } else {
      AppLogger.info('⚠️ Background service pulado (plataforma web)');
    }
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Erro ao inicializar background services',
      // error: error,
      // stackTrace: stackTrace,
    );
    // Não interromper o app por falha em background services
  }
}

/// Configurar UI do sistema (status bar, etc)
void _configureSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  AppLogger.debug('⚙️ UI do sistema configurada');
}

/// Rastrear tempo de inicialização do app
Future<void> _trackAppStartup(int durationMs) async {
  try {
    if (AnalyticsIntegration.isEnabled) {
      await AnalyticsIntegration.manager.trackAppStartup(durationMs);

      // Evento detalhado de startup
      await AnalyticsIntegration.manager.trackEvent(
        'app_startup_detailed',
        parameters: {
          'duration_ms': durationMs,
          'platform': defaultTargetPlatform.name,
          'debug_mode': kDebugMode,
          'first_launch': true, // TODO: detectar se é primeiro launch
        },
      );
    }
  } catch (e) {
    AppLogger.error('Erro ao rastrear app startup: $e');
  }
}

/// Widget principal do app
class UnlockApp extends ConsumerStatefulWidget {
  const UnlockApp({super.key});

  @override
  ConsumerState<UnlockApp> createState() => _UnlockAppState();
}

class _UnlockAppState extends ConsumerState<UnlockApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    // Observar lifecycle do app para analytics
    WidgetsBinding.instance.addObserver(this);

    // Iniciar sessão de analytics
    _startAnalyticsSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Rastrear mudanças no lifecycle do app
    _handleAppLifecycleChange(state);
  }

  /// Iniciar sessão de analytics
  void _startAnalyticsSession() async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.startSession();
      }
    } catch (e) {
      AppLogger.error('Erro ao iniciar sessão de analytics: $e');
    }
  }

  /// Tratar mudanças no lifecycle do app
  void _handleAppLifecycleChange(AppLifecycleState state) async {
    try {
      AppLogger.debug('📱 App lifecycle: ${state.name}');

      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          'app_lifecycle_change',
          parameters: {
            'state': state.name,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        switch (state) {
          case AppLifecycleState.paused:
            // App foi para background
            await AnalyticsIntegration.manager.trackEvent('app_backgrounded');
            break;
          case AppLifecycleState.resumed:
            // App voltou do background
            await AnalyticsIntegration.manager.trackEvent('app_foregrounded');
            break;
          case AppLifecycleState.detached:
            // App está sendo encerrado
            await AnalyticsIntegration.endSession();
            break;
          default:
            break;
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao tratar lifecycle change: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers principais
    final isDarkMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    // Log navegação baseada no estado de auth
    AppLogger.navigation(
      'Estado de navegação atual',
      data: {
        'isDarkMode': isDarkMode,
        'authStatus': authState.status.toString(),
        'isInitialized': authState.isInitialized,
        'needsOnboarding': authState.needsOnboarding,
      },
    );

    return MaterialApp(
      // Configurações básicas
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Tema
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Home baseado no estado de auth
      home: _getHomeScreen(authState),

      // Builder para capturar erros de navegação
      builder: (context, child) {
        // Capturar erros de navegação
        ErrorWidget.builder = (errorDetails) {
          AppLogger.error(
            'Erro no widget',
            error: errorDetails.exception,
            stackTrace: errorDetails.stack,
          );

          // Rastrear erro de widget se analytics estiver disponível
          _trackWidgetError(errorDetails);

          return _ErrorWidget(error: errorDetails.exception);
        };

        return child ?? const SizedBox.shrink();
      },

      // Navigator observers para rastrear navegação
      navigatorObservers: [
        if (AnalyticsIntegration.isEnabled) _AnalyticsNavigatorObserver(),
      ],
    );
  }

  /// Determinar qual tela mostrar baseado no estado de auth
  Widget _getHomeScreen(AuthState authState) {
    if (authState.shouldShowSplash) {
      return const SplashScreen();
    }

    // Por enquanto, sempre mostrar splash na Fase 1
    // Nas próximas fases, implementaremos a lógica completa
    return const SplashScreen();
  }

  /// Rastrear erro de widget
  void _trackWidgetError(FlutterErrorDetails errorDetails) async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackError(
          'Widget error occurred',
          error: errorDetails.exception,
          stackTrace: errorDetails.stack,
          parameters: {
            'error_context': 'widget_build',
            'library': errorDetails.library ?? 'unknown',
          },
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao rastrear widget error: $e');
    }
  }
}

/// Navigator observer para rastrear mudanças de tela automaticamente
class _AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackRouteChange('push', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _trackRouteChange('pop', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackRouteChange('replace', newRoute, oldRoute);
    }
  }

  void _trackRouteChange(
    String action,
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) async {
    try {
      final routeName = _getRouteName(route);
      final previousRouteName = previousRoute != null
          ? _getRouteName(previousRoute)
          : null;

      AppLogger.navigation(
        '📱 Navegação: $action para $routeName',
        data: {
          'action': action,
          'current_route': routeName,
          'previous_route': previousRouteName,
        },
      );

      if (AnalyticsIntegration.isEnabled) {
        // Rastrear mudança de tela
        await AnalyticsIntegration.manager.trackScreen(routeName);

        // Rastrear navegação
        await AnalyticsIntegration.manager.trackNavigation(
          previousRouteName ?? 'unknown',
          routeName,
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao rastrear mudança de rota: $e');
    }
  }

  String _getRouteName(Route<dynamic> route) {
    if (route.settings.name != null) {
      return route.settings.name!;
    }

    // Tentar extrair nome da rota baseado no tipo
    final routeType = route.runtimeType.toString();
    if (routeType.contains('MaterialPageRoute')) {
      return 'MaterialPageRoute';
    } else if (routeType.contains('PageRouteBuilder')) {
      return 'PageRouteBuilder';
    }

    return routeType;
  }
}

/// App de erro para falhas críticas na inicialização
class _ErrorApp extends StatelessWidget {
  final Object error;

  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unlock - Erro',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 24),
                Text(
                  'Ops! Algo deu errado',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'O app encontrou um erro durante a inicialização. '
                  'Por favor, reinicie o aplicativo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                ),
                const SizedBox(height: 24),
                if (kDebugMode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de erro para falhas durante execução
class _ErrorWidget extends StatelessWidget {
  final Object error;

  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.shade100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bug_report, size: 48, color: Colors.red.shade600),
              const SizedBox(height: 16),
              Text(
                'Erro no Widget',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              if (kDebugMode)
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                )
              else
                const Text(
                  'Algo deu errado aqui.',
                  style: TextStyle(fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
