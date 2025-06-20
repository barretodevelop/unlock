// lib/unlockApp.dart - ATUALIZADO PARA SISTEMA SIMPLIFICADO
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/router/app_router.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/theme_provider.dart';

/// ✅ Widget principal do app Unlock com navegação simplificada
class UnlockApp extends ConsumerWidget {
  const UnlockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    AppLogger.info(
      '🚀 UnlockApp construindo com sistema simplificado',
      data: {
        'isDarkMode': isDarkMode,
        'isDebugMode': kDebugMode,
        'navigationSystem': 'Simplificado',
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

      // ========== 🎯 SISTEMA DE NAVEGAÇÃO SIMPLIFICADO ==========
      routerConfig: AppRouter.createRouter(ref),

      // ========== BUILDER PARA ERROR HANDLING ==========
      builder: (context, child) {
        return _AppBuilder(child: child);
      },
    );
  }
}

/// ✅ Builder com error handling e overlays
class _AppBuilder extends StatelessWidget {
  final Widget? child;

  const _AppBuilder({this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ Fechar teclado ao tocar fora
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          currentFocus.focusedChild!.unfocus();
        }
      },
      child: Stack(
        children: [
          // ✅ App principal
          child ?? const _EmergencyScreen(),
          // Removido Debug overlay para simplificar
          // ✅ Debug overlay apenas em desenvolvimento
          // if (kDebugMode) ...[
          //   const Positioned(top: 100, right: 10, child: _DebugOverlay()),
          // ],
        ],
      ),
    );
  }
}

/// ✅ Debug overlay simplificado
class _DebugOverlay extends ConsumerWidget {
  const _DebugOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DEBUG',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Text(
            'Auth: ${authState.isAuthenticated ? "✅" : "❌"}',
            style: const TextStyle(color: Colors.green, fontSize: 10),
          ),
          Text(
            'Loading: ${authState.isLoading ? "⏳" : "✅"}',
            style: const TextStyle(color: Colors.yellow, fontSize: 10),
          ),
          Text(
            'Onboarding: ${authState.needsOnboarding ? "📝" : "✅"}',
            style: const TextStyle(color: Colors.blue, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// ✅ Tela de emergência para casos críticos
class _EmergencyScreen extends StatelessWidget {
  const _EmergencyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.red.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro Crítico',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'O sistema de navegação falhou. '
                'Reinicie o aplicativo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.red.shade700),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Tentar recriar o app
                  AppLogger.error('🚨 Emergency restart requested');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reiniciar App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
