// lib/core/router/app_router.dart - SISTEMA SIMPLIFICADO
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/auth/screens/login_screen.dart';
import 'package:unlock/features/connections/screens/connections_screen.dart';
import 'package:unlock/features/games/screens/color_match_game_screen.dart';
import 'package:unlock/features/games/screens/games_screen.dart';
import 'package:unlock/features/games/screens/match_game_screen.dart';
import 'package:unlock/features/games/screens/memory_game_screen.dart';
import 'package:unlock/features/games/screens/number_game_screen.dart';
import 'package:unlock/features/games/screens/puzzle_game_screen.dart';
import 'package:unlock/features/games/screens/quiz_game_screen.dart';
import 'package:unlock/features/games/screens/reaction_game_screen.dart';
import 'package:unlock/features/games/screens/snake_game_screen.dart';
import 'package:unlock/features/games/screens/word_game_screen.dart';
import 'package:unlock/features/home/screens/home_screen.dart';
import 'package:unlock/features/missions/screens/missions_categorized_screen.dart';
import 'package:unlock/features/onboarding/onboarding_wrapper.dart';
import 'package:unlock/features/profile/screens/profile_screen.dart';
import 'package:unlock/features/profile/screens/user_public_profile_screen.dart';
import 'package:unlock/features/settings/screens/settings_screen.dart';
import 'package:unlock/models/game_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/screens/splash_screen.dart';

/// ✅ SISTEMA DE NAVEGAÇÃO SIMPLIFICADO
/// - Apenas 1 arquivo para toda a configuração
/// - Lógica clara e direta
/// - Fácil manutenção e debug
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

        // Onboarding Flow
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) {
            AppLogger.navigation('📝 Building OnboardingWrapper');
            return const OnboardingWrapper();
          },
        ),

        // Home Screen (Main App)
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) {
            AppLogger.navigation('🏠 Building HomeScreen');
            return HomeScreen();
          },
        ),

        // User Public Profile Screen (o que os outros veem)
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) {
            AppLogger.navigation('👤 Building UserPublicProfileScreen');
            return const UserPublicProfileScreen();
          },
        ),

        // Account Settings Screen (onde o usuário edita seus dados, o ProfileScreen atual)
        GoRoute(
          path: AppRoutes.accountSettings, // Nova rota
          name: 'accountSettings',
          builder: (context, state) {
            AppLogger.navigation('👤 Building ProfileScreen');
            return const ProfileScreen(); // Usar a ProfileScreen real
          },
        ),

        // Connections Screen
        GoRoute(
          path: '/connections',
          name: 'connections',
          builder: (context, state) {
            AppLogger.navigation('🔗 Building ConnectionsScreen');
            return const ConnectionsScreen(); // Usar a ConnectionsScreen (placeholder ou real)
          },
        ),

        // Missions Screen
        GoRoute(
          path: '/missions',
          name: 'missions',
          builder: (context, state) {
            AppLogger.navigation('🚩 Building MissionsCategorizedScreen');
            return const MissionsCategorizedScreen();
          },
        ),

        // Settings Screen
        GoRoute(
          path: AppRoutes.settings, // Usar constante de AppRoutes
          name: 'settings',
          builder: (context, state) {
            AppLogger.navigation('⚙️ Building SettingsScreen');
            return const SettingsScreen();
          },
        ),

        // Games Screen
        GoRoute(
          path: AppRoutes.games, // Usar constante de AppRoutes
          name: 'games',
          builder: (context, state) {
            AppLogger.navigation('🎮 Building GamesScreen');
            return const GamesListScreen();
          },
        ),

        // ===============================
        // 🎮 MINI-GAMES ROUTES
        // ===============================

        // Memory Game
        GoRoute(
          path: AppRoutes.memoryGame,
          name: 'memoryGame',
          builder: (context, state) {
            AppLogger.navigation('🧠 Building MemoryGameScreen');
            final game = state.extra as GameModel?;
            return game != null
                ? MemoryGameScreen(game: game)
                : const _PlaceholderScreen(
                    title: 'Erro no Jogo',
                    description: 'Jogo não encontrado.',
                  );
          },
        ),

        // Quiz Game
        GoRoute(
          path: AppRoutes.quizGame,
          name: 'quizGame',
          builder: (context, state) {
            AppLogger.navigation('❓ Building QuizGameScreen');
            final game = state.extra as GameModel?;
            return game != null
                ? QuizGameScreen(game: game)
                : const _PlaceholderScreen(
                    title: 'Erro no Jogo',
                    description: 'Jogo não encontrado.',
                  );
          },
        ),

        // Puzzle Game
        GoRoute(
          path: AppRoutes.puzzleGame,
          name: 'puzzleGame',
          builder: (context, state) {
            AppLogger.navigation('🧩 Building PuzzleGameScreen');
            final game = state.extra as GameModel?;
            return game != null
                ? PuzzleGameScreen(game: game)
                : const _PlaceholderScreen(
                    title: 'Erro no Jogo',
                    description: 'Jogo não encontrado.',
                  );
          },
        ),

        // Snake Game
        GoRoute(
          path: AppRoutes.snakeGame,
          name: 'snakeGame',
          builder: (context, state) {
            AppLogger.navigation('🐍 Building SnakeGameScreen');
            final game = state.extra as GameModel?;
            return game != null
                ? SnakeGameScreen(game: game)
                : const _PlaceholderScreen(
                    title: 'Erro no Jogo',
                    description: 'Jogo não encontrado.',
                  );
          },
        ),

        // Word Game (Caça Palavras)
        GoRoute(
          path: AppRoutes.wordGame,
          name: 'wordGame',
          builder: (context, state) {
            AppLogger.navigation('🔤 Building WordGameScreen');
            final game = state.extra as GameModel?;
            return game != null
                ? WordGameScreen(game: game)
                : const _PlaceholderScreen(
                    title: 'Erro no Jogo',
                    description: 'Jogo não encontrado.',
                  );
          },
        ),

        // Number Game (Sequência Numérica)
        GoRoute(
          path: AppRoutes.numberGame,
          name: 'numberGame',
          builder: (context, state) {
            AppLogger.navigation('🔢 Building NumberGameScreen');
            final game = state.extra as GameModel?;
            return game != null
                ? NumberGameScreen(game: game)
                : const _PlaceholderScreen(
                    title: 'Erro no Jogo',
                    description: 'Jogo não encontrado.',
                  );
          },
        ),

        // Color Match Game
        GoRoute(
          path: AppRoutes.colorMatchGame,
          name: 'colorMatchGame',
          builder: (context, state) {
            AppLogger.navigation('🎨 Building ColorMatchGameScreen');
            final game = state.extra as GameModel?;
            return game != null
                ? ColorMatchGameScreen(game: game)
                : const _PlaceholderScreen(
                    title: 'Erro no Jogo',
                    description: 'Jogo não encontrado.',
                  );
          },
        ),

        // Reaction Game (Teste de Reflexo)
        GoRoute(
          path: AppRoutes.reactionGame,
          name: 'reactionGame',
          builder: (context, state) {
            AppLogger.navigation('⚡ Building ReactionGameScreen');
            final game = state.extra as GameModel?;
            return game != null
                ? ReactionGameScreen(game: game)
                : const _PlaceholderScreen(
                    title: 'Erro no Jogo',
                    description: 'Jogo não encontrado.',
                  );
          },
        ),

        // Math Game (Desafio Matemático)
        GoRoute(
          path: AppRoutes.matchGame,
          name: 'matchGame',
          builder: (context, state) {
            AppLogger.navigation('🧮 Building MathGameScreen');
            final game = state.extra as GameModel?;
            return game != null
                ? MathGameScreen(game: game)
                : const _PlaceholderScreen(
                    title: 'Erro no Jogo',
                    description: 'Jogo não encontrado.',
                  );
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

      // ✅ PERMITIR NAVEGAÇÃO SE ESTÁ EM LOGIN OU SPLASH MESMO COM isLoading == true
      if (authState.isLoading) {
        AppLogger.navigation('⏳ Auth loading...');
        if (location == '/login' || location == '/') {
          return null; // permitir permanecer no login/splash
        }
        return null; // não redirecionar ainda
      }

      // ✅ AGORA QUE NÃO ESTÁ LOADING, TRATAR OS ESTADOS
      // Se não inicializado, mostrar splash
      if (!authState.isInitialized) {
        AppLogger.navigation('🎯 Redirect to splash (not initialized)');
        return '/';
      }

      // Se não autenticado, mostrar login
      if (!authState.isAuthenticated) {
        // Se não estiver já na tela de login, redireciona para login.
        // Isso permite que o splash ('/') seja exibido e, em seguida, redirecionado.
        if (location != '/login') {
          AppLogger.navigation('🔑 Redirect to login (not authenticated)');
          return '/login';
        }
        return null;
      }

      // Se precisa onboarding, mostrar onboarding
      if (authState.needsOnboarding) {
        if (!location.startsWith('/onboarding')) {
          AppLogger.navigation('📝 Redirect to onboarding (needs completion)');
          return '/onboarding';
        }
        return null;
      }

      // Se está autenticado e não precisa de onboarding
      if (authState.isAuthenticated && !authState.needsOnboarding) {
        // Se estiver tentando acessar login, onboarding ou splash, redireciona para home
        if (location == AppRoutes.login ||
            location == AppRoutes.onboarding ||
            location == AppRoutes.splash) {
          AppLogger.navigation(
            '🏠 User authenticated and onboarding complete. Redirecting from $location to home',
          );
          return AppRoutes.home;
        }
        return null; // Permite a navegação para a rota solicitada (ex: /profile, /settings, etc.)
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
  static const String games = '/games';

  // Rotas dos mini-games
  static const String memoryGame = '/games/memoryGame';
  static const String quizGame = '/games/quizGame';
  static const String puzzleGame = '/games/puzzleGame';
  static const String snakeGame = '/games/snakeGame';
  static const String wordGame = '/games/wordGame';
  static const String numberGame = '/games/numberGame';
  static const String colorMatchGame = '/games/colormatchGame';
  static const String reactionGame = '/games/reactionGame';
  static const String matchGame = '/games/matchGame';
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

  /// Navegar para um jogo específico
  static void navigateToGame(BuildContext context, GameModel game) {
    AppLogger.navigation('🎮 Navigating to game: ${game.id}');
    context.go(game.route, extra: game);
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

/// ✅ TELA DE PLACEHOLDER SIMPLES
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onBack;

  const _PlaceholderScreen({
    required this.title,
    required this.description,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => NavigationUtils.popOrHome(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onBack ?? () => NavigationUtils.popOrHome(context),
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
