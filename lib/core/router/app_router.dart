// lib/core/router/app_router.dart - SISTEMA SIMPLIFICADO
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/auth/screens/login_screen.dart';
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
      final location = state.uri.toString();
      final authState = ref.read(authProvider);

      // Se o estado de autenticação estiver carregando, não redirecione para evitar
      // telas piscando. O router será reavaliado quando o carregamento terminar.
      if (authState.isLoading) {
        AppLogger.navigation(
          '⏳ Auth state is loading. No redirects will occur.',
        );
        return null;
      }

      // Se o provedor de autenticação ainda não foi inicializado,
      // o usuário deve ser direcionado para a tela de splash.
      if (!authState.isInitialized) {
        AppLogger.navigation(
          '🎯 Redirect: App not initialized. Forcing to splash.',
        );
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isLoggedIn = authState.isAuthenticated;
      final needsOnboarding = authState.needsOnboarding;

      // Se não autenticado, mostrar login
      if (!isLoggedIn) {
        // Permite que o usuário permaneça na tela de login.
        // Redireciona de qualquer outra rota para o login.
        if (location != AppRoutes.login) {
          AppLogger.navigation(
            '🔑 Redirect: User not authenticated. Forcing to login.',
          );
          return AppRoutes.login;
        }
        return null;
      }

      // A partir daqui, o usuário está autenticado (isLoggedIn == true).

      // Se precisa onboarding, mostrar onboarding
      if (needsOnboarding) {
        if (!location.startsWith(AppRoutes.onboarding)) {
          AppLogger.navigation(
            '📝 Redirect: User needs onboarding. Forcing to onboarding.',
          );
          return AppRoutes.onboarding;
        }
        return null;
      }

      // Se o usuário está autenticado e já completou o onboarding,
      // ele não deve poder acessar as telas de login, splash ou onboarding.
      if (location == AppRoutes.login ||
          location.startsWith(AppRoutes.onboarding) ||
          location == AppRoutes.splash) {
        AppLogger.navigation(
          '🏠 Redirect: User is authenticated and onboarded. Forcing to home.',
        );
        return AppRoutes.home;
      }

      // Caso padrão
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
