// lib/config/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/games/ppt/ppt.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/screens/cadastro_screen.dart';
import 'package:unlock/screens/chat_screen.dart';
import 'package:unlock/screens/connection_test_screen.dart';
import 'package:unlock/screens/home_screen.dart';
import 'package:unlock/screens/list_profiles.dart';
import 'package:unlock/screens/login_screen.dart';
import 'package:unlock/screens/matching_screen.dart';
import 'package:unlock/screens/other_user_profile_screen.dart';
import 'package:unlock/screens/profile_screen.dart';
import 'package:unlock/screens/settings_screen.dart'; // ✅ Adicionar import
import 'package:unlock/screens/splash_screen.dart';
import 'package:unlock/utils/page_transitions.dart';

// ✅ CORREÇÃO: RouterNotifier para escutar mudanças do AuthProvider
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Escutar mudanças no AuthProvider
    _ref.listen<AuthState>(authProvider, (previous, next) {
      // Notificar GoRouter quando estado de auth mudar
      if (previous?.isInitialized != next.isInitialized ||
          previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isLoading != next.isLoading) {
        print('🔄 RouterNotifier: Auth state changed, notifying GoRouter');
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    print('🔄 RouterNotifier: Disposing');
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // ✅ CORREÇÃO: Usar RouterNotifier
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true, // ✅ Ativar para debug
    refreshListenable: routerNotifier, // ✅ CORREÇÃO: Escutar mudanças
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),

      // Login Screen
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),

      // Home Screen
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => PageTransitions.slideFromRight(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),

      // Profile Screen
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => PageTransitions.slideFromBottom(
          key: state.pageKey,
          child: const ProfileScreen(),
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

      // ✅ NOVA ROTA: cadastro Screen
      GoRoute(
        path: '/cadastro',
        name: 'cadastro',
        pageBuilder: (context, state) => PageTransitions.fadeTransition(
          // Ou outra transição de sua escolha
          key: state.pageKey,
          child: const CadastroScreen(),
        ),
      ),
      GoRoute(
        path: '/match',
        name: 'match',
        pageBuilder: (context, state) {
          // Recuperar a lista do extra
          final interessesUsuario = state.extra as List<String>? ?? [];

          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: MatchingScreen(interessesUsuario: interessesUsuario),
          );
        },
      ),

      GoRoute(
        path: '/connection-test',
        name: 'connection-test',
        pageBuilder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final interesses = extras['userInterests'] as List<String>? ?? [];
          final connection = extras['chosenConnection'];

          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: ConnectionTestScreen(
              userInterests: interesses,
              chosenConnection: connection,
            ),
          );
        },
      ),

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

      GoRoute(
        path: '/chat-screen',
        name: 'chat-screen',
        pageBuilder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final isRealConnection = extras['isRealConnection'];
          final connectionData = extras['connectionData'];

          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: ChatScreen(
              connectionData: connectionData,
              isRealConnection: isRealConnection,
            ),
          );
        },
      ),

      GoRoute(
        path: '/profile-page',
        name: 'profile-page',
        pageBuilder: (context, state) {
          // final Map<String, dynamic> connectionData =
          //     state.extra as Map<String, dynamic>;

          return PageTransitions.fadeTransition(
            key: state.pageKey,
            child: ProfilesPage(),
          );
        },
      ),
    ],

    // Error page com transição
    errorPageBuilder: (context, state) => PageTransitions.fadeTransition(
      key: state.pageKey,
      child: ErrorScreen(error: state.error.toString()),
    ),

    // Redirect logic otimizada
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.uri.path;

      // Log para debug
      print('🔄 GoRouter Redirect:');
      print('  Location: $location');
      print('  isInitialized: ${authState.isInitialized}');
      print('  isAuthenticated: ${authState.isAuthenticated}');
      print('  isLoading: ${authState.isLoading}');
      print('  status: ${authState.status}');

      // ✅ LÓGICA SIMPLIFICADA:

      // 1. Se não inicializado, sempre na splash
      if (!authState.isInitialized) {
        if (location != '/splash') {
          print('  ➡️ Redirect to /splash (not initialized)');
          return '/splash';
        }
        return null;
      }

      // 2. Se inicializado mas carregando, ficar na splash
      if (authState.isInitialized && authState.isLoading) {
        if (location != '/splash') {
          print('  ➡️ Redirect to /splash (loading)');
          return '/splash';
        }
        return null;
      }

      // 3. App pronto (inicializado e não carregando)
      if (authState.isInitialized && !authState.isLoading) {
        // Usuário autenticado
        if (authState.isAuthenticated) {
          if (location == '/splash' || location == '/login') {
            print('  ➡️ Redirect to /home (authenticated)');
            return '/home';
          }
          // Já está em página autenticada
          return null;
        }

        // Usuário não autenticado
        if (!authState.isAuthenticated) {
          if (location != '/login') {
            print('  ➡️ Redirect to /login (not authenticated)');
            return '/login';
          }
          // Já está no login
          return null;
        }
      }

      // Nenhum redirecionamento
      print('  ✅ No redirect needed');
      return null;
    },
  );
});

// Tela de erro personalizada
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ops! Algo deu errado',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home),
                  label: const Text('Voltar ao Início'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
