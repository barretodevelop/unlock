// lib/config/updated_app_router.dart - CORRIGIDO
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/screens/enhanced_matching_screen.dart';
import 'package:unlock/feature/social/screens/enhanced_test_screen_ui.dart';
import 'package:unlock/feature/support/test_users_admin_screen.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/screens/cadastro_screen.dart';
import 'package:unlock/screens/enhanced_home_screen.dart';
import 'package:unlock/screens/login_screen.dart';
import 'package:unlock/screens/settings_screen.dart';
import 'package:unlock/screens/splash_screen.dart';

// ============== PROVIDER ==============
final AppRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,

    // ✅ CORREÇÃO: Router com bypass de onboarding para rotas de teste
    // Substitua a função redirect no AppRouterProvider
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.uri.path;

      if (kDebugMode) {
        print('🧭 Router: $location | Auth: ${authState.isAuthenticated}');
      }

      // Splash sempre permitido
      if (location == '/splash') return null;

      // Se não autenticado, ir para login
      if (!authState.isAuthenticated && location != '/login') {
        if (kDebugMode) print('🔒 Redirecionando para login - não autenticado');
        return '/login';
      }

      // ✅ CORREÇÃO: Bypass onboarding para rotas de teste
      if (location.startsWith('/connection-test')) {
        if (kDebugMode) {
          print('🧪 Bypass onboarding para rota de teste: $location');
        }
        return null; // Permitir acesso direto à rota de teste
      }

      // Se autenticado mas precisa completar onboarding (APENAS para outras rotas)
      if (authState.needsOnboarding && location != '/cadastro') {
        if (kDebugMode) {
          print('🔍 Checking onboarding for ${authState.user?.uid}:');
          print(
            '  onboardingCompleted: ${authState.user?.onboardingCompleted}',
          );
          print('  codinome: "${authState.user?.codinome}"');
          print('  interesses.length: ${authState.user?.interesses.length}');
          print(
            '  relationshipInterest: "${authState.user?.relationshipInterest}"',
          );
          print('🔄 Redirecionando para cadastro - onboarding necessário');
        }
        return '/cadastro';
      }

      // Validações específicas para rotas protegidas (removidas para teste)
      if (RouteGuards.isProtectedRoute(location)) {
        // Sem validações por enquanto
        return null;
      }

      return null;
    },

    routes: [
      // ============== SPLASH ==============
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),

      // ============== AUTH ==============
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

      // ============== HOME ==============
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          key: state.pageKey,
          child: const EnhancedHomeScreen(),
        ),
      ),

      // ✅ NOVA ROTA: Settings Screen
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => PageTransitions.slideFromRight(
          // Ou outra transição de sua escolha
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),

      GoRoute(
        path: '/admin/test-users',
        name: 'test-users',
        pageBuilder: (context, state) {
          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: TestUsersAdminScreen(),
          );
        },
      ),

      // ============== SOCIAL FEATURES ==============
      GoRoute(
        path: '/match',
        name: 'match',
        pageBuilder: (context, state) {
          final interessesUsuario = state.extra as List<String>? ?? [];
          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: EnhancedMatchingScreen(interessesUsuario: interessesUsuario),
          );
        },
      ),

      //   // ============== ✅ ENHANCED CONNECTION TEST - CORRIGIDO ==============
      //   // ✅ TESTE: Router SEM validações para identificar o problema
      //   // Substitua temporariamente a rota /connection-test por esta versão
      //   GoRoute(
      //     path: '/connection-test',
      //     name: 'connection-test',
      //     pageBuilder: (context, state) {
      //       print('🧭 === ROUTER DEBUG - /connection-test ===');

      //       final params = state.extra as Map<String, dynamic>? ?? {};
      //       print('📦 Parâmetros recebidos no router:');
      //       print('  params: $params');
      //       print('  params.keys: ${params.keys.toList()}');

      //       final chosenConnection =
      //           params['chosenConnection'] as Map<String, dynamic>? ?? {};
      //       final userInterests = params['userInterests'] as List<String>? ?? [];
      //       final inviteId = params['inviteId'] as String? ?? '';

      //       print('📋 Dados extraídos:');
      //       print('  chosenConnection.isEmpty: ${chosenConnection.isEmpty}');
      //       print('  chosenConnection.keys: ${chosenConnection.keys.toList()}');
      //       print('  userInterests.length: ${userInterests.length}');
      //       print('  inviteId: "$inviteId"');
      //       print('  inviteId.isEmpty: ${inviteId.isEmpty}');

      //       // ✅ SEM VALIDAÇÕES - Sempre permitir navegação
      //       print('✅ Router: Permitindo navegação sem validações');

      //       return PageTransitions.fadeTransition(
      //         key: state.pageKey,
      //         child: EnhancedTestScreenUI(
      //           chosenConnection: chosenConnection,
      //           userInterests: userInterests,
      //           inviteId: inviteId,
      //         ),
      //       );
      //     },
      //   ),
      //   // ============== FALLBACK - ROTA NÃO ENCONTRADA ==============
      GoRoute(
        path: '/connection-test',
        name: 'connection-test',
        pageBuilder: (context, state) {
          print('🧭 === ROUTER DEBUG ULTRA DETALHADO ===');
          print('📦 state.extra: ${state.extra}');
          print('📦 state.extra.runtimeType: ${state.extra.runtimeType}');

          final params = state.extra as Map<String, dynamic>? ?? {};
          print('📦 params após cast: $params');
          print('📦 params.runtimeType: ${params.runtimeType}');
          print('📦 params.keys: ${params.keys.toList()}');
          print('📦 params.length: ${params.length}');

          // Debug detalhado de cada chave
          params.forEach((key, value) {
            print('📋 params["$key"]:');
            print('    valor: $value');
            print('    tipo: ${value.runtimeType}');
            if (value is String) {
              print('    length: ${value.length}');
              print('    isEmpty: ${value.isEmpty}');
            }
          });

          final chosenConnection =
              params['chosenConnection'] as Map<String, dynamic>? ?? {};
          final userInterests = params['userInterests'] as List<String>? ?? [];
          final inviteId = params['inviteId'] as String? ?? '';

          print('📋 DADOS EXTRAÍDOS PELO ROUTER:');
          print('  chosenConnection: $chosenConnection');
          print('  chosenConnection.isEmpty: ${chosenConnection.isEmpty}');
          print('  chosenConnection.keys: ${chosenConnection.keys.toList()}');
          print('  userInterests: $userInterests');
          print('  userInterests.length: ${userInterests.length}');
          print('  inviteId EXTRAÍDO: "$inviteId"');
          print('  inviteId.runtimeType: ${inviteId.runtimeType}');
          print('  inviteId.length: ${inviteId.length}');
          print('  inviteId.isEmpty: ${inviteId.isEmpty}');

          // ✅ INVESTIGAR: Por que inviteId está vazio?
          if (inviteId.isEmpty) {
            print('🔍 === INVESTIGAÇÃO INVITEID VAZIO ===');
            print('❌ InviteId está vazio no router!');
            print('📋 Chaves disponíveis em params: ${params.keys.toList()}');
            print('📋 Verificando se inviteId existe com outro nome:');

            params.forEach((key, value) {
              if (key.toLowerCase().contains('invite') ||
                  key.toLowerCase().contains('id') ||
                  value.toString().length > 10) {
                print('    Possível inviteId em "$key": "$value"');
              }
            });

            // Tentar extrair inviteId de chosenConnection
            if (chosenConnection.isNotEmpty) {
              print('📋 Verificando chosenConnection para inviteId:');
              chosenConnection.forEach((key, value) {
                if (key.toLowerCase().contains('invite') ||
                    (key.toLowerCase().contains('id') &&
                        value.toString().length > 10)) {
                  print(
                    '    Possível inviteId em chosenConnection["$key"]: "$value"',
                  );
                }
              });
            }
          }

          print(
            '✅ Router: Prosseguindo com navegação (mesmo com inviteId vazio para debug)',
          );

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
    ],

    // ============== ERROR HANDLER ==============
    errorBuilder: (context, state) => ErrorScreen(
      context: context,
      message: 'Página não encontrada: ${state.uri.path}',
      onBack: () => context.go('/home'),
    ),
  );
});

// ============== ROUTE VALIDATION ==============
String? _validateProtectedRoute(String location, GoRouterState state) {
  // ✅ CORREÇÃO: Remover validação muito restritiva
  if (kDebugMode) {
    print('🔍 Router: Validando rota protegida: $location');
  }
  return null; // Permitir todas as rotas protegidas
}

// ============== ERROR SCREEN CLASS ==============
class ErrorScreen extends StatelessWidget {
  final BuildContext context;
  final String message;
  final VoidCallback? onBack;

  const ErrorScreen({
    super.key,
    required this.context,
    required this.message,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erro'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              onBack ??
              () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/home');
                }
              },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 100, color: Colors.red[400]),
            const SizedBox(height: 32),
            const Text(
              'Oops! Algo deu errado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    onBack ??
                    () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/home');
                      }
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Voltar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============== ROUTE GUARDS ==============
class RouteGuards {
  static bool requiresAuth(String location) {
    const publicRoutes = ['/splash', '/login', '/cadastro'];
    return !publicRoutes.contains(location);
  }

  static bool requiresOnboarding(String location) {
    const onboardingRoutes = ['/cadastro'];
    return onboardingRoutes.contains(location);
  }

  static bool isProtectedRoute(String location) {
    const protectedRoutes = [
      '/connection-test',
      '/profile',
      '/settings',
      '/match',
      '/chat',
    ];
    return protectedRoutes.any((route) => location.startsWith(route));
  }
}

// ============== PAGE TRANSITIONS ==============
class PageTransitions {
  static Page<T> fadeTransition<T>({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static Page<T> slideFromRight<T>({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        );
      },
    );
  }
}

// ============== NAVIGATION HELPERS ==============
extension AppNavigationX on GoRouter {
  void goToConnectionTest({
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

  void goHomeWithReset() => go('/home');

  void goToErrorPage(String message) =>
      go('/error?message=${Uri.encodeQueryComponent(message)}');
}

// ============== ANALYTICS ==============
class NavigationAnalytics {
  static void trackNavigation(String from, String to) {
    if (kDebugMode) print('📱 Navigation: $from → $to');
  }

  static void trackTestFlow(String step, Map<String, dynamic> data) {
    if (kDebugMode) print('🧪 Test Flow: $step - $data');
  }

  static void trackError(String route, String error) {
    if (kDebugMode) print('❌ Navigation Error: $route - $error');
  }
}
