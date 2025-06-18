// lib/core/navigation/navigation_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/auth/screens/login_screen.dart';
import 'package:unlock/features/home/screens/home_screen.dart';
import 'package:unlock/features/onboarding/screens/anonymous_identity_screen.dart';
import 'package:unlock/features/onboarding/screens/interests_selection_screen.dart';
import 'package:unlock/features/onboarding/screens/welcome_age_screen.dart';
import 'package:unlock/shared/screens/splash_screen.dart';

/// Definição centralizada de todas as rotas do app
class NavigationRoutes {
  // ========== CONSTANTES DE ROTAS ==========

  static const String splash = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String onboardingIdentity = '/onboarding/identity';
  static const String onboardingInterests = '/onboarding/interests';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String connections = '/connections';
  static const String missions = '/missions';
  static const String shop = '/shop';
  static const String settings = '/settings';
  static const String error = '/error';

  // ========== NOMES DAS ROTAS ==========

  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String onboardingName = 'onboarding';
  static const String onboardingIdentityName = 'onboarding_identity';
  static const String onboardingInterestsName = 'onboarding_interests';
  static const String homeName = 'home';
  static const String profileName = 'profile';
  static const String connectionsName = 'connections';
  static const String missionsName = 'missions';
  static const String shopName = 'shop';
  static const String settingsName = 'settings';
  static const String errorName = 'error';

  // ========== DEFINIÇÃO DAS ROTAS ==========

  static List<RouteBase> get routes => [
    // Splash Screen - Tela inicial
    GoRoute(
      path: splash,
      name: splashName,
      builder: (context, state) {
        AppLogger.navigation('🏠 Building SplashScreen');
        return const SplashScreen();
      },
    ),

    // Login Screen - Autenticação
    GoRoute(
      path: login,
      name: loginName,
      builder: (context, state) {
        AppLogger.navigation('🔑 Building LoginScreen');
        return const LoginScreen();
      },
    ),

    // Onboarding - Processo de cadastro
    GoRoute(
      path: onboarding,
      name: onboardingName,
      builder: (context, state) {
        AppLogger.navigation('👋 Building WelcomeAgeScreen (onboarding start)');
        return const WelcomeAgeScreen();
      },
      routes: [
        // Sub-rota: Identidade Anônima
        GoRoute(
          path: 'identity',
          name: onboardingIdentityName,
          builder: (context, state) {
            AppLogger.navigation('🎭 Building AnonymousIdentityScreen');
            return const AnonymousIdentityScreen();
          },
        ),

        // Sub-rota: Seleção de Interesses
        GoRoute(
          path: 'interests',
          name: onboardingInterestsName,
          builder: (context, state) {
            AppLogger.navigation('❤️ Building InterestsSelectionScreen');
            return const InterestsSelectionScreen();
          },
        ),
      ],
    ),

    // Home Screen - Tela principal
    GoRoute(
      path: home,
      name: homeName,
      builder: (context, state) {
        AppLogger.navigation('🏠 Building HomeScreen');
        return const HomeScreen();
      },
      routes: [
        // 🚀 FUTURO: Sub-rotas do home
        // GoRoute(
        //   path: 'feed',
        //   name: 'home_feed',
        //   builder: (context, state) => const FeedScreen(),
        // ),
        // GoRoute(
        //   path: 'discover',
        //   name: 'home_discover',
        //   builder: (context, state) => const DiscoverScreen(),
        // ),
      ],
    ),

    // 🚀 PLACEHOLDER ROUTES - Para desenvolvimento futuro
    GoRoute(
      path: profile,
      name: profileName,
      builder: (context, state) {
        AppLogger.navigation('👤 Building ProfileScreen (placeholder)');
        return _PlaceholderScreen(
          title: 'Profile',
          description: 'Tela de perfil em desenvolvimento',
          icon: Icons.person,
        );
      },
    ),

    GoRoute(
      path: connections,
      name: connectionsName,
      builder: (context, state) {
        AppLogger.navigation('🤝 Building ConnectionsScreen (placeholder)');
        return _PlaceholderScreen(
          title: 'Connections',
          description: 'Tela de conexões em desenvolvimento',
          icon: Icons.people,
        );
      },
    ),

    GoRoute(
      path: missions,
      name: missionsName,
      builder: (context, state) {
        AppLogger.navigation('🎯 Building MissionsScreen (placeholder)');
        return _PlaceholderScreen(
          title: 'Missions',
          description: 'Tela de missões em desenvolvimento',
          icon: Icons.flag,
        );
      },
    ),

    GoRoute(
      path: shop,
      name: shopName,
      builder: (context, state) {
        AppLogger.navigation('🛍️ Building ShopScreen (placeholder)');
        return _PlaceholderScreen(
          title: 'Shop',
          description: 'Loja em desenvolvimento',
          icon: Icons.shopping_cart,
        );
      },
    ),

    GoRoute(
      path: settings,
      name: settingsName,
      builder: (context, state) {
        AppLogger.navigation('⚙️ Building SettingsScreen (placeholder)');
        return _PlaceholderScreen(
          title: 'Settings',
          description: 'Configurações em desenvolvimento',
          icon: Icons.settings,
        );
      },
    ),

    // Error Screen - Tela de erro genérica
    GoRoute(
      path: error,
      name: errorName,
      builder: (context, state) {
        final errorMessage = state.extra as String? ?? 'Erro desconhecido';
        AppLogger.navigation(
          '❌ Building ErrorScreen',
          data: {'error': errorMessage},
        );
        return _ErrorScreen(error: errorMessage);
      },
    ),
  ];

  // ========== ERROR BUILDER ==========

  static Widget errorBuilder(BuildContext context, GoRouterState state) {
    final error =
        state.error?.toString() ?? 'Rota não encontrada: ${state.uri}';

    AppLogger.error(
      '❌ Route error occurred',
      error: state.error,
      data: {
        'location': state.uri,
        'fullPath': state.fullPath,
        'name': state.name,
      },
    );

    return _ErrorScreen(error: error);
  }

  // ========== UTILIDADES ==========

  /// Verificar se a rota é pública (não requer autenticação)
  static bool isPublicRoute(String path) {
    return [splash, login, error].contains(_normalizePath(path));
  }

  /// Verificar se a rota é de onboarding
  static bool isOnboardingRoute(String path) {
    final normalized = _normalizePath(path);
    return normalized == onboarding || normalized.startsWith('$onboarding/');
  }

  /// Verificar se a rota requer autenticação
  static bool requiresAuth(String path) {
    return !isPublicRoute(path);
  }

  /// Normalizar path para comparação
  static String _normalizePath(String path) {
    return path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
  }

  /// Obter nome amigável da rota
  static String getRouteFriendlyName(String path) {
    switch (_normalizePath(path)) {
      case splash:
        return 'Splash';
      case login:
        return 'Login';
      case onboarding:
        return 'Onboarding';
      case home:
        return 'Home';
      case profile:
        return 'Profile';
      case connections:
        return 'Connections';
      case missions:
        return 'Missions';
      case shop:
        return 'Shop';
      case settings:
        return 'Settings';
      default:
        return 'Unknown';
    }
  }
}

/// Tela placeholder para rotas em desenvolvimento
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _PlaceholderScreen({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => context.go(NavigationRoutes.home),
                icon: const Icon(Icons.home),
                label: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tela de erro customizada
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erro'),
        centerTitle: true,
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
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Ops! Algo deu errado',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  error,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go(NavigationRoutes.home),
                    icon: const Icon(Icons.home),
                    label: const Text('Início'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(NavigationRoutes.home);
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
