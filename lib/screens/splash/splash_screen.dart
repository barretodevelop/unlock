// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Animações melhoradas
  late AnimationController _logoController;
  late AnimationController _dotsController;
  late AnimationController _fadeController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _dotsOpacity;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    // Logo animation (da SplashScreenAtual)
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Loading dots animation
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _dotsOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeInOut),
    );

    // Fade animation (da SplashScreen original)
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    _logoController.forward();
    _fadeController.forward();
    _dotsController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _dotsController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Debug logs (mantidos da SplashScreenAtual)
    print('🔄 SplashScreen Build:');
    print('  isInitialized: ${authState.isInitialized}');
    print('  isLoading: ${authState.isLoading}');
    print('  isAuthenticated: ${authState.isAuthenticated}');
    print('  status: ${authState.status}');
    print('  user: ${authState.user?.uid}');
    print('  needsOnboarding: ${authState.needsOnboarding}');

    // ✅ NAVEGAÇÃO CORRIGIDA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.isInitialized && !authState.isLoading) {
        if (!authState.isAuthenticated) {
          // ✅ Usuário NÃO logado → LoginScreen
          _navigateToLogin();
        } else if (authState.needsOnboarding) {
          // ✅ Usuário logado + onboarding PENDENTE → CadastroScreen
          _navigateToCadastro();
        } else {
          // ✅ Usuário logado + onboarding COMPLETO → HomeScreen
          _navigateToHome();
        }
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9333EA), // Purple
              Color(0xFF2563EB), // Blue
              Color(0xFF0D9488), // Teal
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeController, _logoController]),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo animado melhorado
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotation.value * 0.1,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.white24, Colors.white10],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '🔓',
                                  style: TextStyle(fontSize: 60),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Título principal
                        const Text(
                          'Desbloqueie',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtítulo
                        Text(
                          'Conectividade real',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 80),

                        // Status e loading baseado no authState
                        _buildStatusSection(authState),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODOS DE NAVEGAÇÃO CORRIGIDOS
  void _navigateToLogin() {
    // Navigator.pushReplacement(
    //   context,
    //   PageRouteBuilder(
    //     pageBuilder: (context, animation, secondaryAnimation) =>
    //         const LoginScreen(), // ← Tela de login
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       return FadeTransition(opacity: animation, child: child);
    //     },
    //     transitionDuration: const Duration(milliseconds: 500),
    //   ),
    // );
    context.go('/login');
  }

  void _navigateToCadastro() {
    // Navigator.pushReplacement(
    //   context,
    //   PageRouteBuilder(
    //     pageBuilder: (context, animation, secondaryAnimation) =>
    //         const CadastroScreen(), // ← Onboarding
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       return FadeTransition(opacity: animation, child: child);
    //     },
    //     transitionDuration: const Duration(milliseconds: 500),
    //   ),
    // );
    context.go('/cadastro');
  }

  void _navigateToHome() {
    // Navigator.pushReplacement(
    //   context,
    //   PageRouteBuilder(
    //     pageBuilder: (context, animation, secondaryAnimation) =>
    //         const HomeScreen(),
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       return FadeTransition(opacity: animation, child: child);
    //     },
    //     transitionDuration: const Duration(milliseconds: 500),
    //   ),
    // );
    context.go('/home');
  }

  Widget _buildStatusSection(AuthState authState) {
    return Column(
      children: [
        // Loading indicator
        if (!authState.isInitialized || authState.isLoading) ...[
          AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              return Opacity(
                opacity: _dotsOpacity.value,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Status message
          Text(
            _getStatusMessage(authState),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        // Error handling
        if (authState.error != null && authState.isInitialized) ...[
          const SizedBox(height: 20),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.4), width: 1),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Ops! Algo deu errado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  authState.error!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(authProvider.notifier).clearError();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF9333EA),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Success state indicator
        if (authState.isInitialized &&
            authState.error == null &&
            !authState.isLoading) ...[
          const SizedBox(height: 40),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  !authState.isAuthenticated
                      ? Icons.login
                      : authState.needsOnboarding
                      ? Icons.edit
                      : Icons.check_circle,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  !authState.isAuthenticated
                      ? 'Indo para login...'
                      : authState.needsOnboarding
                      ? 'Completando perfil...'
                      : 'Entrando no app...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusMessage(AuthState authState) {
    if (!authState.isInitialized) {
      return 'Inicializando...';
    }

    if (authState.isLoading) {
      switch (authState.status) {
        case AuthStatus.unknown:
          return 'Verificando autenticação...';
        case AuthStatus.authenticated:
          return authState.needsOnboarding
              ? 'Verificando perfil...'
              : 'Carregando seus dados...';
        case AuthStatus.unauthenticated:
          return 'Preparando tela de login...';
        case AuthStatus.error:
          return 'Processando erro...';
      }
    }

    // Estados finais
    if (!authState.isAuthenticated) {
      return 'Redirecionando para login...';
    } else if (authState.needsOnboarding) {
      return 'Finalizando seu perfil...';
    } else {
      return 'Bem-vindo de volta!';
    }
  }
}
