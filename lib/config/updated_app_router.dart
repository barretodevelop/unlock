// lib/config/updated_app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/games/ppt/ppt.dart';
import 'package:unlock/feature/social/screens/enhanced_matching_screen.dart';
import 'package:unlock/feature/social/screens/enhanced_test_screen_ui.dart';
import 'package:unlock/feature/social/screens/other_user_profile_screen.dart';
import 'package:unlock/feature/social/screens/unlocked_chat_screen.dart';
import 'package:unlock/feature/support/test_users_admin_screen.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/screens/cadastro_screen.dart';
import 'package:unlock/screens/enhanced_home_screen.dart';
import 'package:unlock/screens/login_screen.dart';
import 'package:unlock/screens/profile_screen.dart';
import 'package:unlock/screens/settings_screen.dart';
import 'package:unlock/screens/splash_screen.dart';
import 'package:unlock/utils/page_transitions.dart';

// ============== ROUTER NOTIFIER ==============
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Escutar mudanças no AuthProvider
    _ref.listen<AuthState>(authProvider, (previous, next) {
      // Notificar GoRouter quando estado de auth mudar
      if (previous?.isInitialized != next.isInitialized ||
          previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isLoading != next.isLoading ||
          previous?.needsOnboarding != next.needsOnboarding) {
        if (kDebugMode) {
          print('🔄 RouterNotifier: Auth state changed');
          print('  Authenticated: ${next.isAuthenticated}');
          print('  Needs Onboarding: ${next.needsOnboarding}');
          print('  Should Show Home: ${next.shouldShowHome}');
        }

        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('🔄 RouterNotifier: Disposing');
    }
    super.dispose();
  }
}

// ============== ROUTER PROVIDER ==============
final AppRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: routerNotifier,

    // ============== REDIRECT LOGIC ==============
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      if (kDebugMode) {
        print('🔄 Router redirect check:');
        print('  Location: $location');
        print('  Auth State: ${authState.toString()}');
      }

      // Permitir sempre /splash durante inicialização
      if (location == '/splash') {
        return null;
      }

      // Se ainda não inicializou, manter em splash
      if (!authState.isInitialized || authState.isLoading) {
        return '/splash';
      }

      // Se não está autenticado, ir para login
      if (!authState.isAuthenticated) {
        return '/login';
      }

      // Se precisa completar onboarding, ir para cadastro
      if (authState.needsOnboarding && location != '/cadastro') {
        return '/cadastro';
      }

      // Se está tudo ok e não é uma rota protegida, permitir navegação
      return null;
    },

    routes: [
      // ============== SPLASH SCREEN ==============
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),

      // ============== AUTH SCREENS ==============
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),

      GoRoute(
        path: '/cadastro',
        name: 'cadastro',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          key: state.pageKey,
          child: const CadastroScreen(),
        ),
      ),

      // ============== HOME SCREEN ==============
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          key: state.pageKey,
          child: const EnhancedHomeScreen(),
        ),
      ),

      // ============== SOCIAL FEATURES ==============
      GoRoute(
        path: '/match',
        name: 'match',
        pageBuilder: (context, state) {
          // Recuperar a lista do extra
          final interessesUsuario = state.extra as List<String>? ?? [];

          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: EnhancedMatchingScreen(interessesUsuario: interessesUsuario),
          );
        },
      ),

      // ============== ENHANCED CONNECTION TEST ==============
      GoRoute(
        path: '/connection-test',
        name: 'connection-test',
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>? ?? {};
          final chosenConnection =
              params['chosenConnection'] as Map<String, dynamic>? ?? {};
          final userInterests = params['userInterests'] as List<String>? ?? [];
          final inviteId = params['inviteId'] as String? ?? '';

          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: EnhancedTestScreenUI(
              chosenConnection: chosenConnection,
              userInterests: userInterests,
              inviteId: inviteId,
            ),
          );
        },
      ),

      // ============== UNLOCKED CHAT ==============
      GoRoute(
        path: '/unlocked-chat/:connectionId',
        name: 'unlocked_chat',
        pageBuilder: (context, state) {
          final connectionId = state.pathParameters['connectionId']!;
          final params = state.extra as Map<String, dynamic>? ?? {};

          // Extrair dados do outro usuário
          final otherUserData =
              params['otherUser'] as Map<String, dynamic>? ?? {};
          final otherUser = UserModel.fromJson(otherUserData);
          final compatibilityScore =
              params['compatibilityScore'] as double? ?? 0.0;

          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: UnlockedChatScreen(
              connectionId: connectionId,
              otherUser: otherUser,
              compatibilityScore: compatibilityScore,
            ),
          );
        },
      ),

      // ============== PROFILE SCREENS ==============
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),

      // ============== SETTINGS ==============
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),

      // GoRoute(
      GoRoute(
        path: '/game',
        name: 'game',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          // Ou outra transição de sua escolha
          key: state.pageKey,
          child: GameScreen(),
        ),
      ),

      GoRoute(
        path: '/other-perfil',
        name: 'other-perfil',
        pageBuilder: (context, state) {
          final Map<String, dynamic> connectionData =
              state.extra as Map<String, dynamic>;

          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: OtherUserProfileScreen(connectionData: connectionData),
          );
        },
      ),

      // ============== ADMIN/SUPPORT ==============

      //       GoRoute(
      //   path: '/profile-page',
      //   name: 'profile-page',
      //   pageBuilder: (context, state) {
      //     // final Map<String, dynamic> connectionData =
      //     //     state.extra as Map<String, dynamic>;

      //     return PageTransitions.fadeTransition(
      //       key: state.pageKey,
      //       child: ProfilesPage(),
      //     );
      //   },
      // ),
      GoRoute(
        path: '/admin/test-users',
        name: 'test-users',
        pageBuilder: (context, state) {
          // final Map<String, dynamic> connectionData =
          //     state.extra as Map<String, dynamic>;

          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: TestUsersAdminScreen(),
          );
        },
      ),
    ],

    // ============== ERROR HANDLER ==============
    errorBuilder: (context, state) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 24),
              const Text(
                'Página não encontrada',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'A página "${state.matchedLocation}" não existe.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ),
      );
    },
  );
});

// ============== NAVIGATION EXTENSIONS ==============
extension NavigationExtensions on BuildContext {
  // ============== SOCIAL NAVIGATION ==============
  void goToEnhancedMatching(List<String> userInterests) {
    go('/match', extra: userInterests);
  }

  void goToEnhancedTest({
    required Map<String, dynamic> chosenConnection,
    required List<String> userInterests,
    required String inviteId,
  }) {
    go(
      '/connection-test',
      extra: {
        'chosenConnection': chosenConnection,
        'userInterests': userInterests,
        'inviteId': inviteId,
      },
    );
  }

  void goToUnlockedChat({
    required String connectionId,
    required UserModel otherUser,
    required double compatibilityScore,
  }) {
    go(
      '/unlocked-chat/$connectionId',
      extra: {
        'otherUser': otherUser.toJson(),
        'compatibilityScore': compatibilityScore,
      },
    );
  }

  // ============== PROFILE NAVIGATION ==============
  void goToOtherProfile({
    required String userId,
    Map<String, dynamic>? userData,
  }) {
    go('/other-profile/$userId', extra: userData ?? {});
  }

  // ============== CHAT NAVIGATION ==============
  void goToChat({required String userId, String? userName}) {
    final params = userName != null
        ? {'userName': userName}
        : <String, String>{};
    go(Uri(path: '/chat/$userId', queryParameters: params).toString());
  }

  // ============== UTILITY NAVIGATION ==============
  void goHomeWithReset() {
    go('/home');
  }

  void goToProfileWithData(Map<String, dynamic> userData) {
    go('/profile', extra: userData);
  }
}

// ============== ROUTE GUARDS ==============
class RouteGuards {
  static bool requiresAuth(String location) {
    const publicRoutes = ['/splash', '/login'];
    return !publicRoutes.contains(location);
  }

  static bool requiresOnboarding(String location) {
    const onboardingRoutes = ['/cadastro'];
    return onboardingRoutes.contains(location);
  }

  static bool isProtectedRoute(String location) {
    const protectedRoutes = [
      '/profile',
      '/settings',
      '/matching',
      '/enhanced-test',
      '/unlocked-chat',
      '/test-users-admin',
    ];

    return protectedRoutes.any((route) => location.startsWith(route));
  }
}

// ============== ROUTE CONSTANTS ==============
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String cadastro = '/cadastro';
  static const String home = '/home';
  static const String matching = '/match';
  static const String enhancedTest = '/enhanced-test';
  static const String unlockedChat = '/unlocked-chat';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String chat = '/chat';
  static const String testUsersAdmin = '/test-users-admin';

  // Helper para navegação type-safe
  static String unlockedChatWithId(String connectionId) =>
      '/unlocked-chat/$connectionId';
  static String chatWithId(String userId) => '/chat/$userId';
  static String otherProfileWithId(String userId) => '/other-profile/$userId';
}

// ============== NAVIGATION ANALYTICS ==============
class NavigationAnalytics {
  static void trackNavigation(String from, String to) {
    if (kDebugMode) {
      print('📱 Navigation: $from → $to');
    }

    // Aqui você pode adicionar analytics reais como Firebase Analytics
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'navigation',
    //   parameters: {'from': from, 'to': to},
    // );
  }

  static void trackTestFlow(String step, Map<String, dynamic> data) {
    if (kDebugMode) {
      print('🧪 Test Flow: $step - $data');
    }

    // Analytics específicos para o fluxo de teste
  }

  static void trackConnectionUnlock(String connectionId, double compatibility) {
    if (kDebugMode) {
      print(
        '🔓 Connection Unlocked: $connectionId (${compatibility.toStringAsFixed(1)}%)',
      );
    }

    // Analytics para unlock de conexões
  }
}
