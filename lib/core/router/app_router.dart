// lib/core/router/app_router.dart - ATUALIZADO COM GRUPOS
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/auth/screens/login_screen.dart';
import 'package:unlock/features/groups/screens/create_group_screen.dart';
import 'package:unlock/features/groups/screens/group_detail_screen.dart';
import 'package:unlock/features/groups/screens/groups_list_screen.dart';
import 'package:unlock/features/home/screens/home_screen.dart';
import 'package:unlock/onboarding/onboarding_wrapper.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/screens/splash_screen.dart';

/// ✅ SISTEMA DE NAVEGAÇÃO COM GRUPOS INTEGRADOS
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Criar router com rotas dos grupos
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: false,

      // ✅ REDIRECT SIMPLIFICADO - com verificação de grupos
      redirect: (context, state) => _handleRedirect(ref, state),

      // ✅ REFRESH LISTENER SIMPLES
      refreshListenable: _AuthChangeNotifier(ref),

      // ✅ ROTAS COMPLETAS COM GRUPOS
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

        // ========== ROTAS AUTENTICADAS ==========

        // Home Screen (Dashboard)
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) {
            AppLogger.navigation('🏠 Building HomeScreen');
            return const HomeScreen();
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

        // Criar Grupo - ✅ CORRIGIDO: Rota independente
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

        // Criar Desafio - ✅ CORRIGIDO: Rota independente
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

        // ========== ROTAS DE PERFIL (PLACEHOLDER) ==========
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) {
            AppLogger.navigation('👤 Building ProfileScreen');
            return _buildComingSoonScreen(context, 'Perfil');
          },
        ),

        // ========== ROTAS DE CONFIGURAÇÕES (PLACEHOLDER) ==========
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) {
            AppLogger.navigation('⚙️ Building SettingsScreen');
            return _buildComingSoonScreen(context, 'Configurações');
          },
        ),

        // ========== ROTAS DE RANKINGS (PLACEHOLDER) ==========
        GoRoute(
          path: '/rankings',
          name: 'rankings',
          builder: (context, state) {
            AppLogger.navigation('🏅 Building RankingsScreen');
            return _buildComingSoonScreen(context, 'Rankings');
          },
        ),

        // ========== ROTAS DE JOGOS (PLACEHOLDER) ==========
        GoRoute(
          path: '/games',
          name: 'games',
          builder: (context, state) {
            AppLogger.navigation('🎮 Building GamesScreen');
            return _buildComingSoonScreen(context, 'Mini-Games');
          },
        ),
      ],

      // ✅ ERROR HANDLER MELHORADO
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

      // Se autenticado e onboard completo, não pode acessar rotas públicas
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

  /// Tela "Em Breve" para funcionalidades não implementadas
  static Widget _buildComingSoonScreen(BuildContext context, String feature) {
    return Scaffold(
      appBar: AppBar(
        title: Text(feature),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.construction,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$feature em Desenvolvimento',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Esta funcionalidade estará disponível em breve. Estamos trabalhando para trazer a melhor experiência!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ GETTERS DE COMPATIBILIDADE
  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
  static BuildContext? get context => _rootNavigatorKey.currentContext;
}

/// ✅ CONSTANTES DE ROTAS CORRIGIDAS
class AppRoutes {
  // Rotas principais
  static const String splash = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String home = '/home';

  // Grupos - ✅ CORRIGIDO: Rotas independentes
  static const String groups = '/groups';
  static const String createGroup = '/groups/create';
  static String groupDetail(String id) => '/groups/$id';

  // Desafios - ✅ CORRIGIDO: Rotas independentes
  static const String challenges = '/challenges';
  static const String createChallenge = '/challenges/create';
  static String challengeDetail(String id) => '/challenges/$id';

  // Outras rotas
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String rankings = '/rankings';
  static const String games = '/games';
}

/// ✅ UTILITÁRIOS DE NAVEGAÇÃO MELHORADOS
class NavigationUtils {
  /// Navegar para rota
  static void navigateTo(BuildContext context, String path, {Object? extra}) {
    AppLogger.navigation('🧭 Navegando para: $path');
    context.go(path, extra: extra);
  }

  /// Push (manter no stack)
  static void pushTo(BuildContext context, String path, {Object? extra}) {
    AppLogger.navigation('📌 Pushing para: $path');
    context.push(path, extra: extra);
  }

  /// Voltar ou ir para home
  static void popOrHome(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      AppLogger.navigation('⬅️ Pop');
      context.pop();
    } else {
      AppLogger.navigation('🏠 Não pode pop, indo para home');
      context.go(AppRoutes.home);
    }
  }

  /// Ir para home e limpar stack
  static void goHome(BuildContext context) {
    AppLogger.navigation('🏠 Indo para home');
    context.go(AppRoutes.home);
  }

  /// Navegar para grupo
  static void goToGroup(BuildContext context, String groupId) {
    AppLogger.navigation('👥 Indo para grupo: $groupId');
    context.go(AppRoutes.groupDetail(groupId));
  }

  /// Navegar para criar grupo
  static void goToCreateGroup(BuildContext context) {
    AppLogger.navigation('➕ Indo para criar grupo');
    context.go(AppRoutes.createGroup);
  }

  /// Navegar para desafio
  static void goToChallenge(BuildContext context, String challengeId) {
    AppLogger.navigation('🏆 Indo para desafio: $challengeId');
    context.go(AppRoutes.challengeDetail(challengeId));
  }

  /// Verificar se pode voltar
  static bool canPop(BuildContext context) {
    return GoRouter.of(context).canPop();
  }
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

    // Mudança no status de autenticação
    if (previous.isAuthenticated != current.isAuthenticated) return true;

    // Mudança no status de carregamento
    if (previous.isLoading != current.isLoading) return true;

    // Mudança no onboarding
    if (previous.needsOnboarding != current.needsOnboarding) return true;

    return false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// ✅ TELA DE ERRO MELHORADA
class _ErrorScreen extends StatelessWidget {
  final String error;
  final String location;

  const _ErrorScreen({required this.error, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oops!'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                'Página Não Encontrada',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'A página "$location" não existe ou foi movida.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => NavigationUtils.goHome(context),
                    icon: const Icon(Icons.home),
                    label: const Text('Ir para Home'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => NavigationUtils.popOrHome(context),
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
