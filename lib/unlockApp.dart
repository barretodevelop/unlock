// lib/unlockApp.dart - COMPATÍVEL com app_router.dart corrigido
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/navigation/navigation_system.dart';
import 'package:unlock/core/router/app_router.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/providers/theme_provider.dart';

/// Widget principal do app Unlock com navegação escalável
class UnlockApp extends ConsumerWidget {
  const UnlockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    AppLogger.info(
      '🚀 UnlockApp construindo',
      data: {
        'isDarkMode': isDarkMode,
        'isDebugMode': kDebugMode,
        'system': 'Navegação escalável com compatibilidade',
      },
    );

    return MaterialApp.router(
      // ========== CONFIGURAÇÕES BÁSICAS ==========
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ========== TEMA ==========
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // ========== 🎯 SISTEMA DE NAVEGAÇÃO ==========
      // Usa o sistema escalável através da interface compatível
      routerConfig: _createCompatibleRouter(ref),

      // ========== BUILDER PARA ERROR HANDLING ==========
      builder: (context, child) {
        return _AppBuilder(child: child);
      },
    );
  }

  /// Criar router compatível que usa o sistema escalável
  GoRouter _createCompatibleRouter(WidgetRef ref) {
    try {
      // 🆕 PREFERÊNCIA: Usar sistema escalável se disponível
      AppLogger.info('🔄 Criando router com sistema escalável');
      return NavigationSystem.createRouter(ref);
    } catch (e) {
      // 🔧 FALLBACK: Se houver problema, tentar interface compatível
      AppLogger.warning(
        '⚠️ Fallback para interface compatível de navegação',
        data: {'error': e.toString()},
      );

      try {
        return AppRouter.createRouter(ref);
      } catch (e2) {
        AppLogger.error('❌ Erro crítico na criação do router', error: e2);

        // 🚨 ÚLTIMO RECURSO: Router mínimo
        return _createMinimalRouter();
      }
    }
  }

  /// Router mínimo para casos de emergência
  GoRouter _createMinimalRouter() {
    AppLogger.warning('🚨 Usando router mínimo de emergência');

    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _EmergencyScreen(),
        ),
      ],
      errorBuilder: (context, state) =>
          _ErrorScreen(error: state.error?.toString() ?? 'Erro de navegação'),
    );
  }
}

/// Builder do app com error handling
class _AppBuilder extends ConsumerWidget {
  final Widget? child;

  const _AppBuilder({this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Configurar error widget personalizado
    ErrorWidget.builder = (errorDetails) {
      AppLogger.error(
        '❌ Widget error occurred',
        error: errorDetails.exception,
        stackTrace: errorDetails.stack,
        data: {
          'library': errorDetails.library,
          'context': errorDetails.context?.toString(),
        },
      );

      return _CustomErrorWidget(error: errorDetails.exception);
    };

    return Stack(
      children: [
        // App principal
        child ?? const SizedBox.shrink(),

        // Debug tools (apenas em desenvolvimento)
        // if (kDebugMode) ...[_DebugTools()],
      ],
    );
  }
}

/// Widget de erro personalizado
class _CustomErrorWidget extends StatelessWidget {
  final Object error;

  const _CustomErrorWidget({required this.error});

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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade700,
                  ),
                ),

                const SizedBox(height: 24),

                // Título
                Text(
                  'Ops! Algo deu errado',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Descrição
                Text(
                  'Ocorreu um erro inesperado no aplicativo.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),

                // Detalhes do erro (apenas em debug)
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Info:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Botão de recarregar
                ElevatedButton.icon(
                  onPressed: () {
                    AppLogger.info('🔄 User requested app reload');
                    // Em uma implementação real, isso reiniciaria o app
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tela de emergência para casos críticos
class _EmergencyScreen extends StatelessWidget {
  const _EmergencyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 80,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(height: 24),
                Text(
                  'Sistema de Navegação',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'O sistema de navegação está sendo inicializado.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tela de erro para problemas de rota
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erro'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro de Navegação',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Tentar navegar para home
                  try {
                    NavigationUtils.goHomeAndClearStack();
                  } catch (e) {
                    AppLogger.error('Erro ao navegar para home: $e');
                  }
                },
                icon: const Icon(Icons.home),
                label: const Text('Ir para Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug tools simplificado
class _DebugTools extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: FloatingActionButton.small(
        heroTag: "debug_navigation",
        onPressed: () {
          _showDebugInfo(context, ref);
        },
        backgroundColor: Colors.black87,
        child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
      ),
    );
  }

  void _showDebugInfo(BuildContext context, WidgetRef ref) {
    try {
      // final debugInfo = NavigationSystem.getNavigationDebugInfo(ref);
      // AppLogger.info('🐛 Debug Navigation Info', data: debugInfo);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug info logged to console'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      AppLogger.error('Erro ao obter debug info: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro no debug: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
