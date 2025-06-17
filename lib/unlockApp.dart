import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/theme_provider.dart';
import 'package:unlock/shared/screens/splash_screen.dart';

/// Widget principal do app
class UnlockApp extends ConsumerWidget {
  const UnlockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          return _ErrorWidget(error: errorDetails.exception);
        };

        return child ?? const SizedBox.shrink();
      },
    );
  }

  // Determinar qual tela mostrar baseado no estado de auth
  Widget _getHomeScreen(AuthState authState) {
    if (authState.shouldShowSplash) {
      return const SplashScreen();
    }

    // Por enquanto, sempre mostrar splash na Fase 1
    // Nas próximas fases, implementaremos a lógica completa
    return const SplashScreen();
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
