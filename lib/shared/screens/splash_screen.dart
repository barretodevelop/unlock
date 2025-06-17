// lib/shared/screens/splash_screen.dart - Splash Screen Simples
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/auth/screens/login_screen.dart';
import 'package:unlock/features/home/screens/home_screen.dart';
import 'package:unlock/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🚀 SplashScreen iniciado');

    // Configurar animações
    _animationController = AnimationController(
      duration: AppConstants.splashScreenDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Iniciar animação
    _animationController.forward();

    // Aguardar e verificar navegação
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Aguardar tempo mínimo do splash
    await Future.delayed(AppConstants.splashScreenDuration);

    if (!mounted) return;

    // Observar estado de autenticação
    final authState = ref.read(authProvider);

    AppLogger.navigation(
      'Verificando estado de auth no splash',
      data: {
        'isInitialized': authState.isInitialized,
        'isAuthenticated': authState.isAuthenticated,
        'needsOnboarding': authState.needsOnboarding,
      },
    );

    _navigateBasedOnAuthState(authState);
  }

  void _navigateBasedOnAuthState(AuthState authState) {
    if (!mounted) return;

    // Determinar próxima tela baseada no estado
    Widget nextScreen;
    String screenName;

    if (!authState.isInitialized) {
      // Ainda carregando, ficar no splash
      AppLogger.navigation(
        'Auth ainda não inicializado, permanecendo no splash',
      );
      return;
    } else if (!authState.isAuthenticated) {
      // Não autenticado, ir para login
      nextScreen = const LoginScreen();
      screenName = 'Login';
    } else if (authState.needsOnboarding) {
      // Precisa completar onboarding (implementar na Fase 2)
      nextScreen = const Scaffold(
        body: Center(
          child: Text(
            'Onboarding\n(Em Desenvolvimento)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
      screenName = 'Onboarding';
    } else {
      // Tudo OK, ir para home
      nextScreen = const HomeScreen();
      screenName = 'Home';
    }

    AppLogger.navigation('Navegando para $screenName');

    // Navegar com animação
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionDuration: AppConstants.animationDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escutar mudanças no estado de auth
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (mounted && next.canNavigate) {
        _navigateBasedOnAuthState(next);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Ícone principal
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_open,
                        size: 60,
                        color: Color(0xFF6366F1), // primaryColor
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nome do app
                    Text(
                      AppConstants.appName.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                    ),

                    const SizedBox(height: 8),

                    // Subtítulo
                    Text(
                      'Conexões autênticas',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Loading indicator
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    AppLogger.debug('SplashScreen disposed');
    super.dispose();
  }
}
