// lib/shared/screens/splash_screen.dart - SIMPLIFICADO PARA SISTEMA ESCALÁVEL
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/navigation/navigation_providers.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/providers/auth_provider.dart';

/// SplashScreen que delega navegação para o sistema de providers
///
/// Esta tela NÃO faz navegação manual - apenas exibe uma animação
/// enquanto o sistema de providers/GoRouter decide para onde navegar.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ========== CONTROLADORES DE ANIMAÇÃO ==========

  late AnimationController _logoAnimationController;
  late AnimationController _progressAnimationController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _progressAnimation;

  // ========== ESTADO ==========

  bool _hasLoggedInitialState = false;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🚀 SplashScreen iniciado (sistema escalável)');

    _initializeAnimations();
    _startAnimations();
  }

  /// Inicializar animações
  void _initializeAnimations() {
    // Animação do logo
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Animação do progresso
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Iniciar animações
  void _startAnimations() {
    _logoAnimationController.forward();

    // Iniciar progresso após delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _progressAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _progressAnimationController.dispose();
    AppLogger.info('🧹 SplashScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ========== ESCUTAR MUDANÇAS DE ESTADO PARA DEBUG ==========

    ref.listen<AuthState>(authProvider, (previous, current) {
      _logAuthStateChange(previous, current);
    });

    ref.listen<NavigationRoute>(currentRouteProvider, (previous, current) {
      _logNavigationChange(previous, current);
    });

    // ========== CONSTRUIR UI ==========

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: _buildSplashContent(context),
    );
  }

  /// Construir conteúdo do splash
  Widget _buildSplashContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Área principal com logo
            Expanded(flex: 3, child: _buildLogoSection(context)),

            // Área de status e progresso
            Expanded(flex: 1, child: _buildStatusSection(context)),
          ],
        ),
      ),
    );
  }

  /// Seção do logo
  Widget _buildLogoSection(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _logoAnimationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _logoFadeAnimation,
            child: ScaleTransition(
              scale: _logoScaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Container do logo
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      size: 70,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nome do app
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Slogan
                  Text(
                    'Conecte-se de forma autêntica',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Seção de status e progresso
  Widget _buildStatusSection(BuildContext context) {
    return Column(
      children: [
        // Indicador de progresso
        _buildProgressIndicator(),

        const SizedBox(height: 24),

        // Status dinâmico
        _buildDynamicStatus(context),

        const SizedBox(height: 16),

        // // Versão do app (apenas em debug)
        // if (AppConstants.isDebugMode) ...[
        //   Text(
        //     'v${AppConstants.appVersion}',
        //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
        //       color: Colors.white.withOpacity(0.6),
        //     ),
        //   ),
        // ],
      ],
    );
  }

  /// Indicador de progresso animado
  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: _progressAnimation.value,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Status dinâmico baseado no estado de auth
  Widget _buildDynamicStatus(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);
        final currentRoute = ref.watch(currentRouteProvider);

        String statusText = _getStatusText(authState, currentRoute);
        Color statusColor = _getStatusColor(authState);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            statusText,
            key: ValueKey(statusText),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  /// Obter texto de status baseado no estado
  String _getStatusText(AuthState authState, NavigationRoute currentRoute) {
    if (!authState.isInitialized) {
      return 'Inicializando...';
    }

    if (authState.isLoading) {
      return 'Carregando...';
    }

    if (authState.error != null) {
      return 'Verificando conexão...';
    }

    if (!authState.isAuthenticated) {
      return 'Preparando login...';
    }

    if (authState.needsOnboarding) {
      return 'Preparando cadastro...';
    }

    return 'Bem-vindo de volta!';
  }

  /// Obter cor de status baseado no estado
  Color _getStatusColor(AuthState authState) {
    if (authState.error != null) {
      return Colors.orange.withOpacity(0.9);
    }

    if (authState.isAuthenticated && !authState.needsOnboarding) {
      return Colors.green.withOpacity(0.9);
    }

    return Colors.white.withOpacity(0.8);
  }

  // ========== MÉTODOS DE DEBUG ==========

  /// Log mudanças no estado de auth
  void _logAuthStateChange(AuthState? previous, AuthState current) {
    if (!_hasLoggedInitialState) {
      _hasLoggedInitialState = true;
      AppLogger.navigation(
        '🎯 SPLASH: Estado inicial de auth',
        data: NavigationCalculator.getNavigationDebugInfo(current),
      );
    } else {
      AppLogger.navigation(
        '🔄 SPLASH: Auth state mudou',
        data: {
          'previous_authenticated': previous?.isAuthenticated,
          'current_authenticated': current.isAuthenticated,
          'previous_needsOnboarding': previous?.needsOnboarding,
          'current_needsOnboarding': current.needsOnboarding,
          'previous_initialized': previous?.isInitialized,
          'current_initialized': current.isInitialized,
        },
      );
    }
  }

  /// Log mudanças na navegação
  void _logNavigationChange(
    NavigationRoute? previous,
    NavigationRoute current,
  ) {
    AppLogger.navigation(
      '🧭 SPLASH: Navigation route mudou',
      data: {
        'previous_path': previous?.path,
        'current_path': current.path,
        'reason': current.reason,
        'params': current.params,
      },
    );
  }
}
