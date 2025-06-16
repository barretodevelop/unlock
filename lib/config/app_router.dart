// lib/config/app_router.dart - ATUALIZADO
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/screens/settings_screen.dart';

// Import dos providers
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/social/affinity_test_screen.dart';
import '../screens/social/chat_screen.dart';
// Import das novas telas do sistema Unlock
import '../screens/social/unlock_discovery_screen.dart';
import '../screens/social/unlock_result_screen.dart';
// Import das telas existentes
import '../screens/splash/splash_screen.dart';

// Classe para nomes das rotas
class AppRoutes {
  // Rotas de autenticação
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';

  // Rotas principais
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Rotas sociais
  static const String connections = '/connections';
  static const String chat = '/chat';

  // Rotas do sistema Unlock
  static const String unlockDiscovery = '/unlock-discovery';
  static const String affinityTest = '/affinity-test';
  static const String unlockResult = '/unlock-result';
  static const String unlockStats = '/unlock-stats';

  // Rotas de gamificação
  static const String missions = '/missions';
  static const String shop = '/shop';

  // Rotas de jogos
  static const String games = '/games';
  static const String rockPaperScissors = '/games/rock-paper-scissors';
}

// Provider do router
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    // Redirecionamento baseado no estado de autenticação
    redirect: (context, state) {
      final location = state.uri.toString();

      // Se está carregando, mantém na splash
      if (authState.shouldShowSplash) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Se não está autenticado, redireciona para login
      if (authState.shouldShowLogin) {
        final authRoutes = [
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.splash,
        ];
        return authRoutes.contains(location) ? null : AppRoutes.login;
      }

      // Se precisa de onboarding
      if (authState.shouldShowOnboarding) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // Se está autenticado, redireciona rotas de auth para home
      if (authState.shouldShowHome) {
        final authRoutes = [
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.onboarding,
          AppRoutes.splash,
        ];
        return authRoutes.contains(location) ? AppRoutes.home : null;
      }

      return null;
    },

    routes: [
      // ==========================================
      // ROTAS DE AUTENTICAÇÃO
      // ==========================================
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // GoRoute(
      //   path: AppRoutes.register,
      //   name: 'register',
      //   builder: (context, state) => const RegisterScreen(),
      // ),

      // GoRoute(
      //   path: AppRoutes.onboarding,
      //   name: 'onboarding',
      //   builder: (context, state) => const OnboardingScreen(),
      // ),

      // ==========================================
      // ROTAS PRINCIPAIS
      // ==========================================
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // ==========================================
      // ROTAS SOCIAIS
      // ==========================================
      GoRoute(
        path: AppRoutes.connections,
        name: 'connections',
        builder: (context, state) => const ConnectionsScreen(),
      ),

      GoRoute(
        path: '${AppRoutes.chat}/:connectionId',
        name: 'chat',
        builder: (context, state) {
          final connectionId = state.pathParameters['connectionId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};

          return ChatScreen(connectionId: connectionId, connectionData: extra);
        },
      ),

      // ==========================================
      // ROTAS DO SISTEMA UNLOCK
      // ==========================================
      GoRoute(
        path: AppRoutes.unlockDiscovery,
        name: 'unlock-discovery',
        builder: (context, state) => const UnlockDiscoveryScreen(),
      ),

      GoRoute(
        path: AppRoutes.affinityTest,
        name: 'affinity-test',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final potentialMatch = extra['potentialMatch'];

          return AffinityTestScreen(
            potentialMatch: potentialMatch,
            match: null,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.unlockResult,
        name: 'unlock-result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final match = extra['match'];
          final wasSuccessful = extra['wasSuccessful'] as bool;

          return UnlockResultScreen(match: match, wasSuccessful: wasSuccessful);
        },
      ),

      GoRoute(
        path: AppRoutes.unlockStats,
        name: 'unlock-stats',
        builder: (context, state) => const UnlockStatsScreen(),
      ),

      // ==========================================
      // ROTAS DE GAMIFICAÇÃO
      // ==========================================
      GoRoute(
        path: AppRoutes.missions,
        name: 'missions',
        builder: (context, state) => const MissionsScreen(),
      ),

      GoRoute(
        path: AppRoutes.shop,
        name: 'shop',
        builder: (context, state) => const ShopScreen(),
      ),

      // ==========================================
      // ROTAS DE JOGOS
      // ==========================================
      GoRoute(
        path: AppRoutes.games,
        name: 'games',
        builder: (context, state) => const GameMenuScreen(),
      ),

      GoRoute(
        path: AppRoutes.rockPaperScissors,
        name: 'rock-paper-scissors',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final opponentId = extra['opponentId'] as String?;

          return RockPaperScissorsScreen(opponentId: opponentId);
        },
      ),
    ],

    // Página de erro personalizada
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error?.toString() ?? 'Página não encontrada',
      location: state.location,
    ),
  );
});

// Tela de erro personalizada
class ErrorScreen extends StatelessWidget {
  final String error;
  final String location;

  const ErrorScreen({super.key, required this.error, required this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Erro de Navegação'),
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Página não encontrada',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'A página "$location" não existe ou não pôde ser carregada.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Erro: $error',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.home),
                label: const Text('Voltar ao Início'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tela de menu de jogos (placeholder)
class GameMenuScreen extends StatelessWidget {
  const GameMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jogos')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.games, size: 64),
            SizedBox(height: 16),
            Text(
              'Menu de Jogos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('Em desenvolvimento...'),
          ],
        ),
      ),
    );
  }
}

// Extensions para navegação mais fácil
extension GoRouterExtension on BuildContext {
  // Navegação para rotas do Unlock
  void goToUnlockDiscovery() => go(AppRoutes.unlockDiscovery);

  void goToAffinityTest(dynamic potentialMatch) =>
      push(AppRoutes.affinityTest, extra: {'potentialMatch': potentialMatch});

  void goToUnlockResult(dynamic match, bool wasSuccessful) => push(
    AppRoutes.unlockResult,
    extra: {'match': match, 'wasSuccessful': wasSuccessful},
  );

  void goToUnlockStats() => push(AppRoutes.unlockStats);

  // Navegação para chat
  void goToChat(String connectionId, [Map<String, dynamic>? data]) =>
      push('${AppRoutes.chat}/$connectionId', extra: data ?? {});

  // Navegação para jogos
  void goToRockPaperScissors([String? opponentId]) =>
      push(AppRoutes.rockPaperScissors, extra: {'opponentId': opponentId});
}
