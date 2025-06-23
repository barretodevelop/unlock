// lib/core/router/app_router.dart - SISTEMA SIMPLIFICADO
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/auth/screens/login_screen.dart';
import 'package:unlock/features/game/screens/game_room_screen.dart';
import 'package:unlock/features/home/screens/home_screen.dart';
import 'package:unlock/onboarding/onboarding_wrapper.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/screens/splash_screen.dart';

/// ✅ SISTEMA DE NAVEGAÇÃO SIMPLIFICADO

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Criar router simples
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: false,

      // ✅ REDIRECT SIMPLES - sem complexidade desnecessária
      redirect: (context, state) => _handleRedirect(ref, state),

      // ✅ REFRESH LISTENER SIMPLES - apenas para mudanças de auth
      refreshListenable: _AuthChangeNotifier(ref),

      // ✅ ROTAS SIMPLES E DIRETAS
      routes: [
        // Splash Screen
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) {
            AppLogger.navigation('🎯 Building SplashScreen');
            return const SplashScreen();
          },
        ),

        // Login Screen
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) {
            AppLogger.navigation('🔑 Building LoginScreen');
            return const LoginScreen();
          },
        ),

        // Home Screen (Main App)
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) {
            AppLogger.navigation(
              '🏠 Building HomeScreen',
            ); // ✅ Corrigido para usar const
            return const HomeScreen();
          },
        ),

        // Onboarding Wrapper
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) {
            AppLogger.navigation('📝 Building OnboardingWrapper');
            return const OnboardingWrapper();
          },
        ),

        // Game Room Screen
        GoRoute(
          path: '/game/:gameRoomId',
          name: 'game_room',
          builder: (context, state) {
            final gameRoomId = state.pathParameters['gameRoomId']!;
            return GameRoomScreen(gameRoomId: gameRoomId);
          },
        ),
      ],

      // ✅ ERROR HANDLER SIMPLES
      errorBuilder: (context, state) {
        AppLogger.error('❌ Route error: ${state.error}');
        return _ErrorScreen(
          error: state.error?.toString() ?? 'Rota não encontrada',
        );
      },
    );
  }

  /// ✅ LÓGICA DE REDIRECT SIMPLIFICADA - SEM LOOPS
  /// ✅ REDIRECT SIMPLES E CORRIGIDO - SEM LOOPS INFINITOS
  static String? _handleRedirect(WidgetRef ref, GoRouterState state) {
    try {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final needsOnboarding = authState.needsOnboarding;
      final isInitialized = authState.isInitialized;
      final isLoading = authState.isLoading; // Usar isLoading diretamente

      final String currentPath = state.uri.path;

      // 1. Lidar com o estado de carregamento/inicialização
      if (isLoading || !isInitialized) {
        // Se ainda estamos carregando ou não inicializados, sempre ir para a splash screen,
        // a menos que já estejamos nela.
        AppLogger.navigation(
          '⏳ Auth state loading or not initialized. Desired: ${AppRoutes.splash}',
        );
        return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // 2. Lidar com o estado não autenticado
      if (!isAuthenticated) {
        // Se não autenticado, permitir apenas as telas de login e splash.
        // Redirecionar para o login se tentar acessar qualquer outra rota.
        AppLogger.navigation(
          '🔑 User not authenticated. Desired: ${AppRoutes.login}',
        );
        if (currentPath == AppRoutes.login || currentPath == AppRoutes.splash) {
          return null; // Permanecer na tela de login ou splash
        } else {
          return AppRoutes.login; // Redirecionar para o login
        }
      }

      // 3. Lidar com o estado autenticado, mas com onboarding pendente
      if (needsOnboarding) {
        // Se autenticado, mas precisa de onboarding, permitir apenas rotas de onboarding.
        // Redirecionar para o onboarding se tentar acessar qualquer outra rota (incluindo a home).
        AppLogger.navigation(
          '📝 User needs onboarding. Desired: ${AppRoutes.onboarding}',
        );
        if (currentPath.startsWith(AppRoutes.onboarding)) {
          return null; // Permanecer no fluxo de onboarding
        }
        return AppRoutes.onboarding; // Redirecionar para o onboarding
      }

      // 4. Lidar com o estado totalmente autenticado e com onboarding concluído
      // Se autenticado e com onboarding concluído, impedir o acesso a splash, login e onboarding.
      // Permitir o acesso a todas as outras rotas.
      if (currentPath == AppRoutes.splash ||
          currentPath == AppRoutes.login ||
          currentPath.startsWith(AppRoutes.onboarding)) {
        AppLogger.navigation(
          '🏠 User authenticated and onboarded. Redirecting from $currentPath to ${AppRoutes.home}',
        );
        return AppRoutes.home; // Redirecionar para a home
      }

      // Se nenhuma das condições acima acionou um redirecionamento, permitir o caminho atual.
      AppLogger.navigation('✅ Allowing navigation to: $currentPath');
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Redirect error', error: e, stackTrace: stackTrace);
      return '/';
    }
  }

  // ✅ GETTERS SIMPLES PARA COMPATIBILIDADE
  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
  static BuildContext? get context => _rootNavigatorKey.currentContext;
}

/// ✅ CONSTANTES DE ROTAS SIMPLIFICADAS
class AppRoutes {
  // Rotas principais
  static const String splash = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String gameRoom =
      '/game/:gameRoomId'; // Nova rota para sala de jogo
  static const String profile = '/profile';
  static const String accountSettings = '/account-settings';
  static const String connections = '/connections';
  static const String missions = '/missions';
  static const String settings = '/settings';
}

/// ✅ UTILITÁRIOS SIMPLES DE NAVEGAÇÃO
class NavigationUtils {
  /// Navegar para rota
  static void navigateTo(BuildContext context, String path, {Object? extra}) {
    AppLogger.navigation('🧭 Navigating to: $path');
    context.go(path, extra: extra);
  }

  /// Push (manter no stack)
  static void pushTo(BuildContext context, String path, {Object? extra}) {
    AppLogger.navigation('📌 Pushing to: $path');
    context.push(path, extra: extra);
  }

  /// Voltar se possível, senão ir para home
  static void popOrHome(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// Ir para home e limpar stack
  static void goHome(BuildContext context) {
    context.go('/home');
  }

  /// Verificar se pode voltar
  static bool canPop(BuildContext context) {
    return GoRouter.of(context).canPop();
  }
}

/// ✅ LISTENER SIMPLES PARA MUDANÇAS DE AUTH - SEM COMPLEXIDADE
class _AuthChangeNotifier extends ChangeNotifier {
  final WidgetRef _ref;
  bool _isDisposed = false;

  _AuthChangeNotifier(this._ref) {
    // ✅ ESCUTAR APENAS MUDANÇAS RELEVANTES NO AUTH
    _ref.listen(authProvider, (previous, current) {
      if (_isDisposed) return;

      // ✅ SÓ NOTIFICAR SE MUDANÇA SIGNIFICATIVA
      final shouldNotify = _shouldNotifyChange(previous, current);

      if (shouldNotify) {
        AppLogger.navigation(
          '🔄 Auth state changed, notifying router',
          data: {
            'wasAuth': previous?.isAuthenticated,
            'isAuth': current.isAuthenticated,
            'wasLoading': previous?.isLoading,
            'isLoading': current.isLoading,
          },
        );

        notifyListeners();
      }
    });
  }

  /// ✅ DECIDIR SE DEVE NOTIFICAR - EVITA LOOPS
  bool _shouldNotifyChange(AuthState? previous, AuthState current) {
    if (previous == null) return true;

    // Notificar se qualquer um dos seguintes estados mudou:
    final bool isLoadingChanged = previous.isLoading != current.isLoading;
    final bool isAuthenticatedChanged =
        previous.isAuthenticated != current.isAuthenticated;
    final bool needsOnboardingChanged =
        previous.needsOnboarding != current.needsOnboarding;
    final bool isInitializedChanged =
        previous.isInitialized != current.isInitialized;
    final bool errorChanged =
        (previous.error == null) != (current.error == null);
    final bool statusChanged = previous.status != current.status;

    return isLoadingChanged ||
        isAuthenticatedChanged ||
        needsOnboardingChanged ||
        isInitializedChanged ||
        errorChanged ||
        statusChanged;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// ✅ TELA DE ERRO SIMPLES
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'Oops! Algo deu errado',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => NavigationUtils.goHome(context),
                icon: const Icon(Icons.home),
                label: const Text('Voltar à Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
