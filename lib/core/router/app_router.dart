// lib/core/router/app_router.dart - Atualizado com Onboarding
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/auth/screens/login_screen.dart';
import 'package:unlock/features/home/screens/home_screen.dart';
import 'package:unlock/features/onboarding/onboarding_wrapper.dart';
import 'package:unlock/features/onboarding/screens/anonymous_identity_screen.dart';
import 'package:unlock/features/onboarding/screens/interests_selection_screen.dart';
import 'package:unlock/features/onboarding/screens/welcome_age_screen.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/screens/splash_screen.dart';

/// Sistema de roteamento centralizado do app Unlock
class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Configuração principal do GoRouter
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.splash,

    // Redirect baseado no estado de autenticação
    redirect: (context, state) {
      return _handleRedirect(context, state);
    },

    // Refresh listener para mudanças no estado de auth
    refreshListenable: _AuthChangeNotifier(),

    // Rotas da aplicação
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Login Screen
      GoRoute(
        path: AppRoutes.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ✅ ONBOARDING ROUTES
      GoRoute(
        path: AppRoutes.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingWrapper(),
        routes: [
          // Sub-rotas do onboarding para deep linking (opcional)
          GoRoute(
            path: 'welcome',
            name: RouteNames.onboardingWelcome,
            builder: (context, state) => const WelcomeAgeScreen(),
          ),
          GoRoute(
            path: 'identity',
            name: RouteNames.onboardingIdentity,
            builder: (context, state) => const AnonymousIdentityScreen(),
          ),
          GoRoute(
            path: 'interests',
            name: RouteNames.onboardingInterests,
            builder: (context, state) => const InterestsSelectionScreen(),
          ),
        ],
      ),

      // Home e rotas principais (com shell navigation)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _MainShell(child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: AppRoutes.home,
            name: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),

          // Profile (placeholder)
          GoRoute(
            path: AppRoutes.profile,
            name: RouteNames.profile,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Profile - Em Desenvolvimento')),
            ),
          ),

          // Connections (placeholder)
          GoRoute(
            path: AppRoutes.connections,
            name: RouteNames.connections,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Connections - Em Desenvolvimento')),
            ),
          ),

          // Missions (placeholder)
          GoRoute(
            path: AppRoutes.missions,
            name: RouteNames.missions,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Missions - Em Desenvolvimento')),
            ),
          ),

          // Shop (placeholder)
          GoRoute(
            path: AppRoutes.shop,
            name: RouteNames.shop,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Shop - Em Desenvolvimento')),
            ),
          ),
        ],
      ),

      // Settings (fora do shell)
      GoRoute(
        path: AppRoutes.settings,
        name: RouteNames.settings,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Configurações')),
          body: const Center(child: Text('Settings - Em Desenvolvimento')),
        ),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );

  /// Lógica de redirecionamento baseada no estado de auth
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final location = state.uri.toString();

    AppLogger.navigation(
      'Verificando redirecionamento',
      data: {
        'currentLocation': location,
        'matchedLocation': state.matchedLocation,
      },
    );

    // ✅ INTEGRAÇÃO COM AUTHPROVIDER
    // TODO: Implementar quando AuthProvider estiver na árvore de widgets
    // Temporariamente permitir navegação livre para desenvolvimento

    // Em produção, a lógica seria:
    /*
    final container = ProviderScope.containerOf(context);
    final authState = container.read(authProvider);
    
    // Se não inicializado, mostrar splash
    if (!authState.isInitialized) {
      if (location != AppRoutes.splash) {
        return AppRoutes.splash;
      }
    }
    
    // Se não autenticado e não em rota pública, ir para login
    if (!authState.isAuthenticated && !_isPublicRoute(location)) {
      return AppRoutes.login;
    }
    
    // Se autenticado mas precisa onboarding
    if (authState.isAuthenticated && authState.needsOnboarding) {
      if (!location.startsWith(AppRoutes.onboarding)) {
        return AppRoutes.onboarding;
      }
    }
    
    // Se autenticado, onboarding completo, mas em rota pública
    if (authState.isAuthenticated && !authState.needsOnboarding) {
      if (_isPublicRoute(location)) {
        return AppRoutes.home;
      }
    }
    */

    return null; // Não redirecionar por enquanto
  }

  /// Verificar se a rota é pública (não requer autenticação)
  static bool _isPublicRoute(String location) {
    return [AppRoutes.splash, AppRoutes.login].contains(location);
  }

  /// Verificar se a rota é de onboarding
  static bool _isOnboardingRoute(String location) {
    return location.startsWith(AppRoutes.onboarding);
  }
}

/// Constantes de rotas atualizadas
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';

  // ✅ ONBOARDING ROUTES
  static const String onboarding = '/onboarding';
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingIdentity = '/onboarding/identity';
  static const String onboardingInterests = '/onboarding/interests';

  static const String home = '/home';
  static const String profile = '/profile';
  static const String connections = '/connections';
  static const String missions = '/missions';
  static const String shop = '/shop';
  static const String settings = '/settings';

  // Sub-rotas (para implementação futura)
  static const String editProfile = '/profile/edit';
  static const String connectionDetail = '/connections/:id';
  static const String missionDetail = '/missions/:id';
  static const String shopItem = '/shop/:id';
  static const String game = '/game/:id';
}

/// Nomes das rotas (para navegação type-safe)
class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';

  // ✅ ONBOARDING ROUTE NAMES
  static const String onboarding = 'onboarding';
  static const String onboardingWelcome = 'onboarding_welcome';
  static const String onboardingIdentity = 'onboarding_identity';
  static const String onboardingInterests = 'onboarding_interests';

  static const String home = 'home';
  static const String profile = 'profile';
  static const String connections = 'connections';
  static const String missions = 'missions';
  static const String shop = 'shop';
  static const String settings = 'settings';
}

/// Shell principal com bottom navigation (placeholder)
class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    // TODO: Implementar bottom navigation na Fase 3
    return Scaffold(body: child, bottomNavigationBar: _buildBottomNavigation());
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Conexões'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Missões'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Loja'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
      onTap: (index) {
        // TODO: Implementar navegação entre abas
        AppLogger.navigation('Bottom nav tap', data: {'index': index});
      },
    );
  }
}

/// Notifier para mudanças de autenticação
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    // TODO: Escutar mudanças no AuthProvider
    // authProvider.addListener(notifyListeners);
  }
}

/// Tela de erro para rotas
class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    AppLogger.error('Erro de rota', error: error);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Erro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
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
              const SizedBox(height: 24),
              Text(
                'Página não encontrada',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'A página que você está procurando não existe ou foi movida.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extensões para navegação type-safe atualizadas
extension AppRouterExtension on GoRouter {
  /// Navegar para home
  void goHome() => go(AppRoutes.home);

  /// Navegar para login
  void goLogin() => go(AppRoutes.login);

  /// ✅ ONBOARDING NAVIGATION
  void goOnboarding() => go(AppRoutes.onboarding);
  void goOnboardingWelcome() => go(AppRoutes.onboardingWelcome);
  void goOnboardingIdentity() => go(AppRoutes.onboardingIdentity);
  void goOnboardingInterests() => go(AppRoutes.onboardingInterests);

  /// Navegar para perfil
  void goProfile() => go(AppRoutes.profile);

  /// Navegar para conexões
  void goConnections() => go(AppRoutes.connections);

  /// Navegar para missões
  void goMissions() => go(AppRoutes.missions);

  /// Navegar para loja
  void goShop() => go(AppRoutes.shop);

  /// Navegar para configurações
  void goSettings() => go(AppRoutes.settings);
}

/// Utilitários de navegação atualizados
class NavigationUtils {
  /// Obter context do router
  static BuildContext? get context =>
      AppRouter._rootNavigatorKey.currentContext;

  /// Verificar se pode voltar
  static bool canPop() {
    return AppRouter._rootNavigatorKey.currentState?.canPop() ?? false;
  }

  /// Voltar se possível
  static void popIfCan() {
    if (canPop()) {
      AppRouter._rootNavigatorKey.currentState?.pop();
    }
  }

  /// Limpar stack e ir para home
  static void goHomeAndClearStack() {
    AppRouter.router.go(AppRoutes.home);
  }

  /// ✅ ONBOARDING NAVIGATION UTILS
  static void goToOnboarding() {
    AppRouter.router.go(AppRoutes.onboarding);
  }

  static void goToOnboardingStep(int step) {
    switch (step) {
      case 0:
        AppRouter.router.go(AppRoutes.onboardingWelcome);
        break;
      case 1:
        AppRouter.router.go(AppRoutes.onboardingIdentity);
        break;
      case 2:
        AppRouter.router.go(AppRoutes.onboardingInterests);
        break;
      default:
        AppRouter.router.go(AppRoutes.onboarding);
    }
  }

  /// Log da rota atual
  static void logCurrentRoute() {
    final location = GoRouter.of(context!).state.uri;
    AppLogger.navigation('Rota atual', data: {'location': location});
  }

  /// Verificar se está em onboarding
  static bool isInOnboarding() {
    final location = GoRouter.of(context!).state.uri.toString();
    return location.startsWith(AppRoutes.onboarding);
  }
}
