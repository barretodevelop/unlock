// lib/core/router/app_router.dart - ATUALIZADO COM RANKINGS IMPLEMENTADOS
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/auth/screens/login_screen.dart';
import 'package:unlock/features/groups/screens/create_group_screen.dart';
import 'package:unlock/features/groups/screens/group_detail_screen.dart';
import 'package:unlock/features/groups/screens/groups_list_screen.dart';
import 'package:unlock/features/home/screens/new_home_screen.dart';
import 'package:unlock/features/rankings/screens/rankings_screen.dart'; // ✅ NOVA TELA DE RANKINGS
import 'package:unlock/onboarding/onboarding_wrapper.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/screens/splash_screen.dart';

/// ✅ SISTEMA DE NAVEGAÇÃO COM RANKINGS IMPLEMENTADOS
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Criar router com rankings funcionais
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: false,

      // ✅ REDIRECT OTIMIZADO
      redirect: (context, state) => _handleRedirect(ref, state),

      // ✅ REFRESH LISTENER
      refreshListenable: _AuthChangeNotifier(ref),

      // ✅ ROTAS COMPLETAS
      routes: [
        // ========== ROTAS PRINCIPAIS ==========

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

        // Onboarding Wrapper
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) {
            AppLogger.navigation('📝 Building OnboardingWrapper');
            return const OnboardingWrapper();
          },
        ),

        // ========== NOVA HOME PRINCIPAL ==========

        // Home com nova navegação
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) {
            AppLogger.navigation('🏠 Building NewHomeScreen');
            return const NewHomeScreen();
          },
        ),

        // ========== ROTAS DOS GRUPOS ==========

        // Lista de Grupos
        GoRoute(
          path: '/groups',
          name: 'groups',
          builder: (context, state) {
            AppLogger.navigation('👥 Building GroupsListScreen');
            return const GroupsListScreen();
          },
        ),

        // Criar Grupo
        GoRoute(
          path: '/groups/create',
          name: 'create-group',
          builder: (context, state) {
            AppLogger.navigation('➕ Building CreateGroupScreen');
            return const CreateGroupScreen();
          },
        ),

        // Detalhes do Grupo
        GoRoute(
          path: '/groups/:groupId',
          name: 'group-detail',
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            AppLogger.navigation('👁️ Building GroupDetailScreen: $groupId');
            return GroupDetailScreen(groupId: groupId);
          },
        ),

        // ========== ROTAS DE DESAFIOS ==========

        // Lista de Desafios
        GoRoute(
          path: '/challenges',
          name: 'challenges',
          builder: (context, state) {
            AppLogger.navigation('🏆 Building ChallengesScreen');
            return _buildComingSoonScreen(context, 'Desafios');
          },
        ),

        // Criar Desafio
        GoRoute(
          path: '/challenges/create',
          name: 'create-challenge',
          builder: (context, state) {
            AppLogger.navigation('➕ Building CreateChallengeScreen');
            return _buildComingSoonScreen(context, 'Criar Desafio');
          },
        ),

        // Detalhes do Desafio
        GoRoute(
          path: '/challenges/:challengeId',
          name: 'challenge-detail',
          builder: (context, state) {
            final challengeId = state.pathParameters['challengeId']!;
            AppLogger.navigation(
              '👁️ Building ChallengeDetailScreen: $challengeId',
            );
            return _buildComingSoonScreen(context, 'Detalhes do Desafio');
          },
        ),

        // ========== ✅ RANKINGS IMPLEMENTADOS ==========

        // Rankings Screen - ✅ AGORA FUNCIONAL
        GoRoute(
          path: '/rankings',
          name: 'rankings',
          builder: (context, state) {
            AppLogger.navigation('🏅 Building RankingsScreen');
            return const RankingsScreen(); // ✅ TELA REAL
          },
        ),

        // Rankings por categoria (rota opcional)
        GoRoute(
          path: '/rankings/:category',
          name: 'rankings-category',
          builder: (context, state) {
            final category = state.pathParameters['category']!;
            AppLogger.navigation('🏅 Building RankingsScreen for: $category');
            // TODO: Implementar navegação direta para categoria
            return const RankingsScreen();
          },
        ),

        // ========== ROTAS REFINADAS ==========

        // Perfil
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) {
            AppLogger.navigation('👤 Building ProfileScreen');
            return _buildComingSoonScreen(context, 'Perfil');
          },
        ),

        // Perfil de outro usuário
        GoRoute(
          path: '/profile/:userId',
          name: 'user-profile',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            AppLogger.navigation('👤 Building UserProfileScreen: $userId');
            return _buildComingSoonScreen(context, 'Perfil do Usuário');
          },
        ),

        // Configurações
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) {
            AppLogger.navigation('⚙️ Building SettingsScreen');
            return _buildComingSoonScreen(context, 'Configurações');
          },
        ),

        // Mini-Games
        GoRoute(
          path: '/games',
          name: 'games',
          builder: (context, state) {
            AppLogger.navigation('🎮 Building GamesScreen');
            return _buildComingSoonScreen(context, 'Mini-Games');
          },
        ),

        // Notificações
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) {
            AppLogger.navigation('🔔 Building NotificationsScreen');
            return _buildComingSoonScreen(context, 'Notificações');
          },
        ),
      ],

      // ✅ ERROR HANDLER REFINADO
      errorBuilder: (context, state) {
        AppLogger.error('❌ Route error: ${state.error}');
        return _ErrorScreen(
          error: state.error?.toString() ?? 'Rota não encontrada',
          location: state.uri.toString(),
        );
      },
    );
  }

  /// ✅ LÓGICA DE REDIRECT OTIMIZADA
  static String? _handleRedirect(WidgetRef ref, GoRouterState state) {
    try {
      final location = state.uri.toString();
      final authState = ref.read(authProvider);

      AppLogger.navigation(
        '🧭 Avaliando redirect',
        data: {
          'location': location,
          'isAuth': authState.isAuthenticated,
          'isLoading': authState.isLoading,
          'needsOnboarding': authState.needsOnboarding,
        },
      );

      // Se carregando, não redirecionar
      if (authState.isLoading) {
        AppLogger.navigation('⏳ Auth loading, sem redirect');
        return null;
      }

      // Se não inicializado, ir para splash
      if (!authState.isInitialized) {
        if (location != AppRoutes.splash) {
          AppLogger.navigation('🎯 Não inicializado, indo para splash');
          return AppRoutes.splash;
        }
        return null;
      }

      final isLoggedIn = authState.isAuthenticated;
      final needsOnboarding = authState.needsOnboarding;

      // Se não autenticado, ir para login
      if (!isLoggedIn) {
        if (location != AppRoutes.login) {
          AppLogger.navigation('🔑 Não autenticado, indo para login');
          return AppRoutes.login;
        }
        return null;
      }

      // Se precisa onboarding, ir para onboarding
      if (needsOnboarding) {
        if (!location.startsWith(AppRoutes.onboarding)) {
          AppLogger.navigation('📝 Precisa onboarding');
          return AppRoutes.onboarding;
        }
        return null;
      }

      // ✅ REDIRECIONAMENTO PARA HOME
      if (location == AppRoutes.login ||
          location.startsWith(AppRoutes.onboarding) ||
          location == AppRoutes.splash) {
        AppLogger.navigation('🏠 Autenticado, indo para home');
        return AppRoutes.home;
      }

      // Caso padrão - sem redirect
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Redirect error', error: e, stackTrace: stackTrace);
      return AppRoutes.splash;
    }
  }

  /// Tela "Em Breve" refinada
  static Widget _buildComingSoonScreen(BuildContext context, String feature) {
    return Scaffold(
      appBar: AppBar(
        title: Text(feature),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone animado
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(seconds: 2),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.construction,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              Text(
                '$feature em Desenvolvimento',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Esta funcionalidade estará disponível em breve. Estamos trabalhando para trazer a melhor experiência!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Botões de ação
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => GoRouter.of(context).go(AppRoutes.home),
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Link para Rankings (já implementado)
              if (feature != 'Rankings')
                TextButton.icon(
                  onPressed: () => GoRouter.of(context).go(AppRoutes.rankings),
                  icon: const Icon(Icons.leaderboard),
                  label: const Text('Ver Rankings'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ GETTERS ATUALIZADOS
  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
  static BuildContext? get context => _rootNavigatorKey.currentContext;
}

/// ✅ CONSTANTES DE ROTAS ATUALIZADAS
class AppRoutes {
  // Rotas principais
  static const String splash = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String home = '/home';

  // Grupos
  static const String groups = '/groups';
  static const String createGroup = '/groups/create';
  static String groupDetail(String id) => '/groups/$id';

  // Desafios
  static const String challenges = '/challenges';
  static const String createChallenge = '/challenges/create';
  static String challengeDetail(String id) => '/challenges/$id';

  // ✅ RANKINGS IMPLEMENTADOS
  static const String rankings = '/rankings';
  static String rankingsCategory(String category) => '/rankings/$category';

  // Navegação Bottom
  static const String profile = '/profile';
  static String userProfile(String userId) => '/profile/$userId';
  static const String settings = '/settings';
  static const String games = '/games';
  static const String notifications = '/notifications';
}

/// ✅ LISTENER DE MUDANÇAS DE AUTH
class _AuthChangeNotifier extends ChangeNotifier {
  final WidgetRef _ref;
  bool _isDisposed = false;

  _AuthChangeNotifier(this._ref) {
    _ref.listen(authProvider, (previous, current) {
      if (_isDisposed) return;

      final shouldNotify = _shouldNotifyChange(previous, current);

      if (shouldNotify) {
        AppLogger.navigation(
          '🔄 Auth mudou, notificando router',
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

  bool _shouldNotifyChange(AuthState? previous, AuthState current) {
    if (previous == null) return true;

    return previous.isAuthenticated != current.isAuthenticated ||
        previous.isLoading != current.isLoading ||
        previous.isInitialized != current.isInitialized ||
        previous.needsOnboarding != current.needsOnboarding;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// ✅ TELA DE ERRO REFINADA
class _ErrorScreen extends StatelessWidget {
  final String error;
  final String location;

  const _ErrorScreen({required this.error, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erro'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'Oops! Algo deu errado',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Rota: $location',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => GoRouter.of(context).go(AppRoutes.home),
                    icon: const Icon(Icons.home),
                    label: const Text('Ir para Home'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () =>
                        GoRouter.of(context).go(AppRoutes.rankings),
                    icon: const Icon(Icons.leaderboard),
                    label: const Text('Ver Rankings'),
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

/// ✅ UTILITÁRIOS DE NAVEGAÇÃO ATUALIZADOS
class NavigationUtils {
  /// Navegar para home
  static void goToHome(BuildContext context) {
    AppLogger.navigation('🏠 Navegando para home');
    GoRouter.of(context).go(AppRoutes.home);
  }

  /// Navegar para rankings
  static void goToRankings(BuildContext context) {
    AppLogger.navigation('🏅 Navegando para rankings');
    GoRouter.of(context).go(AppRoutes.rankings);
  }

  /// Navegar para rankings de categoria específica
  static void goToRankingsCategory(BuildContext context, String category) {
    AppLogger.navigation('🏅 Navegando para rankings: $category');
    GoRouter.of(context).go(AppRoutes.rankingsCategory(category));
  }

  /// Navegar para perfil de usuário
  static void goToUserProfile(BuildContext context, String userId) {
    AppLogger.navigation('👤 Navegando para perfil: $userId');
    GoRouter.of(context).go(AppRoutes.userProfile(userId));
  }

  /// Navegar mantendo stack
  static void pushTo(BuildContext context, String path, {Object? extra}) {
    AppLogger.navigation('📌 Pushing para: $path');
    GoRouter.of(context).push(path, extra: extra);
  }

  /// Voltar ou ir para home
  static void popOrHome(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      AppLogger.navigation('⬅️ Pop');
      GoRouter.of(context).pop();
    } else {
      AppLogger.navigation('🏠 Não pode pop, indo para home');
      GoRouter.of(context).go(AppRoutes.home);
    }
  }

  /// Verificar se pode voltar
  static bool canPop(BuildContext context) {
    return GoRouter.of(context).canPop();
  }
}
