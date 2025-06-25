// lib/core/router/app_router.dart - COMPLETO COM PROVIDER
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/auth/screens/login_screen.dart';
import 'package:unlock/features/groups/screens/create_group_screen.dart';
import 'package:unlock/features/groups/screens/group_detail_screen.dart';
import 'package:unlock/features/groups/screens/groups_list_screen.dart';
import 'package:unlock/features/home/screens/modern_home_screen%20.dart';
import 'package:unlock/features/mini_games/screens/game_play_screen.dart'; // ✅ GAMEPLAY
import 'package:unlock/features/mini_games/screens/mini_games_screen.dart'; // ✅ MINI-GAMES
import 'package:unlock/features/rankings/screens/rankings_screen.dart';
import 'package:unlock/onboarding/onboarding_wrapper.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/screens/splash_screen.dart';

/// ✅ PROVIDER PRINCIPAL DO ROUTER - ISSO RESOLVE O ERRO!
// final appRouterProvider = Provider<GoRouter>((ref) {
//   return AppRouter.createRouter(ref);
// });

/// 🚀 Classe Router Principal com Mini-Games e Nova Home
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Criar router com todas as funcionalidades
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: false,

      // 🔐 Redirect para auth
      redirect: (context, state) => AppRouter._handleRedirect(ref, state),

      // 🔄 Refresh listener
      refreshListenable: _AuthChangeNotifier(ref),

      // 🛤️ Rotas completas
      routes: [
        // ========== ROTAS PRINCIPAIS ==========

        // 🎬 Splash Screen
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) {
            AppLogger.navigation('🎬 Building SplashScreen');
            return const SplashScreen();
          },
        ),

        // 🔐 Login
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) {
            AppLogger.navigation('🔐 Building LoginScreen');
            return const LoginScreen();
          },
        ),

        // 📝 Onboarding
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) {
            AppLogger.navigation('📝 Building OnboardingWrapper');
            return const OnboardingWrapper();
          },
        ),

        // ========== ✅ NOVA HOME MODERNA ==========
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) {
            AppLogger.navigation('🏠 Building ModernHomeScreen');
            return const ModernHomeScreen(); // ✅ Nova home com mini-games
          },
        ),

        // ========== 👥 ROTAS DOS GRUPOS ==========
        GoRoute(
          path: '/groups',
          name: 'groups',
          builder: (context, state) {
            AppLogger.navigation('👥 Building GroupsListScreen');
            return const GroupsListScreen();
          },
          routes: [
            // Criar grupo
            GoRoute(
              path: '/create',
              name: 'create-group',
              builder: (context, state) {
                AppLogger.navigation('➕ Building CreateGroupScreen');
                return const CreateGroupScreen();
              },
            ),
            // Detalhes do grupo
            GoRoute(
              path: '/:groupId',
              name: 'group-detail',
              builder: (context, state) {
                final groupId = state.pathParameters['groupId']!;
                AppLogger.navigation(
                  '👁️ Building GroupDetailScreen: $groupId',
                );
                return GroupDetailScreen(groupId: groupId);
              },
            ),
          ],
        ),

        // ========== 🏆 ROTAS DE DESAFIOS ==========
        GoRoute(
          path: '/challenges',
          name: 'challenges',
          builder: (context, state) {
            AppLogger.navigation('🏆 Building ChallengesScreen');
            return AppRouter._buildComingSoonScreen(context, 'Desafios');
          },
          routes: [
            // Criar desafio
            GoRoute(
              path: '/create',
              name: 'create-challenge',
              builder: (context, state) {
                AppLogger.navigation('➕ Building CreateChallengeScreen');
                return AppRouter._buildComingSoonScreen(
                  context,
                  'Criar Desafio',
                );
              },
            ),
            // Detalhes do desafio
            GoRoute(
              path: '/:challengeId',
              name: 'challenge-detail',
              builder: (context, state) {
                final challengeId = state.pathParameters['challengeId']!;
                AppLogger.navigation(
                  '👁️ Building ChallengeDetailScreen: $challengeId',
                );
                return AppRouter._buildComingSoonScreen(
                  context,
                  'Detalhes do Desafio',
                );
              },
            ),
          ],
        ),

        // ========== ✅ ROTAS DOS MINI-GAMES ==========
        GoRoute(
          path: '/mini-games',
          name: 'mini-games',
          builder: (context, state) {
            AppLogger.navigation('🎮 Building MiniGamesScreen');
            return const MiniGamesScreen(); // ✅ Tela principal dos mini-games
          },
          routes: [
            // Jogo específico
            GoRoute(
              path: '/:gameType',
              name: 'mini-game-play',
              builder: (context, state) {
                final gameType = state.pathParameters['gameType']!;
                AppLogger.navigation('🎯 Building GamePlayScreen: $gameType');
                return GamePlayScreen(
                  gameTypeId: gameType,
                ); // ✅ Gameplay específico
              },
            ),
            // Leaderboard - ✅ CORRIGIDO
            GoRoute(
              path: '/leaderboard',
              name: 'mini-games-leaderboard',
              builder: (context, state) {
                AppLogger.navigation('🏆 Building MiniGamesLeaderboard');
                return AppRouter._buildComingSoonScreen(
                  context,
                  'Leaderboard dos Mini-Games',
                );
              },
            ),
            // Histórico - ✅ CORRIGIDO
            GoRoute(
              path: '/history',
              name: 'mini-games-history',
              builder: (context, state) {
                AppLogger.navigation('📜 Building MiniGamesHistory');
                return AppRouter._buildComingSoonScreen(
                  context,
                  'Histórico de Jogos',
                );
              },
            ),
          ],
        ),

        // ========== 🏅 RANKINGS ==========
        GoRoute(
          path: '/rankings',
          name: 'rankings',
          builder: (context, state) {
            AppLogger.navigation('🏅 Building RankingsScreen');
            return const RankingsScreen(); // ✅ Tela de rankings implementada
          },
          routes: [
            // Rankings por categoria
            GoRoute(
              path: '/:category',
              name: 'rankings-category',
              builder: (context, state) {
                final category = state.pathParameters['category']!;
                AppLogger.navigation(
                  '🏅 Building RankingsScreen for: $category',
                );
                return const RankingsScreen(); // Redireciona para tela principal
              },
            ),
          ],
        ),

        // ========== 👤 PERFIL ==========
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) {
            AppLogger.navigation('👤 Building ProfileScreen');
            return AppRouter._buildComingSoonScreen(context, 'Perfil');
          },
          routes: [
            // Editar perfil
            GoRoute(
              path: '/edit',
              name: 'edit-profile',
              builder: (context, state) {
                AppLogger.navigation('✏️ Building EditProfileScreen');
                return AppRouter._buildComingSoonScreen(
                  context,
                  'Editar Perfil',
                );
              },
            ),
            // Perfil de outro usuário
            GoRoute(
              path: '/:userId',
              name: 'user-profile',
              builder: (context, state) {
                final userId = state.pathParameters['userId']!;
                AppLogger.navigation('👁️ Building UserProfileScreen: $userId');
                return AppRouter._buildComingSoonScreen(
                  context,
                  'Perfil do Usuário',
                );
              },
            ),
          ],
        ),

        // ========== ⚙️ CONFIGURAÇÕES ==========
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) {
            AppLogger.navigation('⚙️ Building SettingsScreen');
            return AppRouter._buildComingSoonScreen(context, 'Configurações');
          },
        ),

        // ========== 🔔 NOTIFICAÇÕES ==========
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) {
            AppLogger.navigation('🔔 Building NotificationsScreen');
            return AppRouter._buildComingSoonScreen(context, 'Notificações');
          },
        ),
      ],

      // ❌ Tratamento de erros
      errorBuilder: (context, state) {
        AppLogger.error('❌ Erro de rota: ${state.error}');
        return AppRouter._buildErrorScreen(context, state.error);
      },
    );
  }

  /// 🔗 Context do navigator
  static BuildContext? get context => _rootNavigatorKey.currentContext;

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

  /// 🚧 Tela "Em breve"
  static Widget _buildComingSoonScreen(BuildContext context, String feature) {
    return Scaffold(
      appBar: AppBar(
        title: Text(feature),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '🚧 $feature',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Esta funcionalidade será implementada em breve!\nEstamos trabalhando para trazer a melhor experiência.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Ir para Home'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ❌ Tela de erro
  static Widget _buildErrorScreen(BuildContext context, Exception? error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
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
                'Ops! Algo deu errado',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error?.toString() ?? 'Erro desconhecido',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Ir para Home'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    child: const Text('Tentar Novamente'),
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

  // ✅ MINI-GAMES
  static const String miniGames = '/mini-games';
  static String miniGame(String gameType) => '/mini-games/$gameType';
  static const String miniGamesLeaderboard = '/mini-games/leaderboard';
  static const String miniGamesHistory = '/mini-games/history';

  // ✅ RANKINGS IMPLEMENTADOS
  static const String rankings = '/rankings';
  static String rankingsCategory(String category) => '/rankings/$category';

  // Navegação Bottom
  static const String profile = '/profile';
  static String userProfile(String userId) => '/profile/$userId';
  static const String settings = '/settings';
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

    // Notificar apenas em mudanças significativas
    return previous.isAuthenticated != current.isAuthenticated ||
        previous.needsOnboarding != current.needsOnboarding ||
        (previous.isLoading && !current.isLoading);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// 🛠️ Extensões úteis para navegação
extension AppRouterExtensions on BuildContext {
  /// Navegar para home
  void goHome() => go('/home');

  /// Navegar para perfil
  void goProfile() => go('/profile');

  /// Navegar para grupos
  void goGroups() => go('/groups');

  /// Navegar para rankings
  void goRankings() => go('/rankings');

  /// Navegar para desafios
  void goChallenges() => go('/challenges');

  /// ✅ NOVO: Navegar para mini-games
  void goMiniGames() => go('/mini-games');

  /// ✅ NOVO: Navegar para jogo específico
  void goMiniGame(String gameType) => go('/mini-games/$gameType');

  /// ✅ NOVO: Navegar para leaderboard
  void goMiniGamesLeaderboard() => go('/mini-games/leaderboard');
}
