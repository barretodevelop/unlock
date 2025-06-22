// lib/shared/screens/splash_screen.dart - SIMPLIFICADA PARA NOVO SISTEMA
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/providers/auth_provider.dart';

/// ✅ SplashScreen simplificada - APENAS escuta AuthProvider
///
/// Esta tela NÃO faz navegação manual - apenas exibe uma animação
/// enquanto o GoRouter (AppRouter) decide automaticamente para onde navegar
/// baseado no estado do AuthProvider.
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

    AppLogger.info('🚀 SplashScreen iniciada (sistema simplificado)');

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
    // ✅ ESCUTAR APENAS AUTHPROVIDER - SEM DEPENDÊNCIAS COMPLEXAS
    ref.listen<AuthState>(authProvider, (previous, current) {
      _logAuthStateChange(previous, current);
    });

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
                    AppInfoConstants.appName,
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

        // Debug info (apenas em debug mode)
        // if (AppConstants.isDebugMode) ...[_buildDebugInfo(context)],
      ],
    );
  }

  /// Indicador de progresso animado
  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Barra de progresso
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Porcentagem
            Text(
              '${(_progressAnimation.value * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Status dinâmico baseado no AuthProvider
  Widget _buildDynamicStatus(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);

        return Column(
          children: [
            // Ícone de status
            Container(
              width: 24,
              height: 24,
              child: _buildStatusIcon(authState),
            ),

            const SizedBox(height: 8),

            // Texto de status
            Text(
              _getStatusText(authState),
              style: TextStyle(
                color: _getStatusColor(authState),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  /// Ícone de status baseado no estado
  Widget _buildStatusIcon(AuthState authState) {
    if (authState.error != null) {
      return const Icon(Icons.warning_rounded, color: Colors.orange, size: 24);
    }

    if (authState.isAuthenticated && !authState.needsOnboarding) {
      return const Icon(
        Icons.check_circle_rounded,
        color: Colors.green,
        size: 24,
      );
    }

    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  /// Texto de status baseado no estado
  String _getStatusText(AuthState authState) {
    if (authState.error != null) {
      return 'Erro na autenticação';
    }

    if (!authState.isInitialized) {
      return 'Inicializando...';
    }

    if (!authState.isAuthenticated) {
      return 'Verificando autenticação...';
    }

    if (authState.needsOnboarding) {
      return 'Redirecionando para cadastro...';
    }

    if (authState.isAuthenticated) {
      return 'Carregando sua conta...';
    }

    return 'Preparando aplicativo...';
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

  /// Info de debug (apenas em debug mode)
  Widget _buildDebugInfo(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEBUG INFO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Auth: ${authState.isAuthenticated ? "✅" : "❌"}',
                style: TextStyle(color: Colors.green, fontSize: 10),
              ),
              Text(
                'Init: ${authState.isInitialized ? "✅" : "❌"}',
                style: TextStyle(color: Colors.blue, fontSize: 10),
              ),
              Text(
                'Loading: ${authState.isLoading ? "⏳" : "✅"}',
                style: TextStyle(color: Colors.yellow, fontSize: 10),
              ),
              Text(
                'Onboarding: ${authState.needsOnboarding ? "📝" : "✅"}',
                style: TextStyle(color: Colors.purple, fontSize: 10),
              ),
              if (authState.user != null) ...[
                Text(
                  'User: ${authState.user!.uid.substring(0, 8)}...',
                  style: TextStyle(color: Colors.cyan, fontSize: 10),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ========== MÉTODOS DE DEBUG ==========

  /// Log mudanças no estado de auth (simplificado)
  void _logAuthStateChange(AuthState? previous, AuthState current) {
    if (!_hasLoggedInitialState) {
      _hasLoggedInitialState = true;
      AppLogger.info(
        '🎯 SPLASH: Estado inicial de auth',
        data: {
          'isAuthenticated': current.isAuthenticated,
          'isInitialized': current.isInitialized,
          'needsOnboarding': current.needsOnboarding,
          'isLoading': current.isLoading,
          'hasError': current.error != null,
          'userId': current.user?.uid,
        },
      );
    } else {
      AppLogger.info(
        '🔄 SPLASH: Auth state mudou',
        data: {
          'previous_authenticated': previous?.isAuthenticated,
          'current_authenticated': current.isAuthenticated,
          'previous_needsOnboarding': previous?.needsOnboarding,
          'current_needsOnboarding': current.needsOnboarding,
          'previous_initialized': previous?.isInitialized,
          'current_initialized': current.isInitialized,
          'previous_loading': previous?.isLoading,
          'current_loading': current.isLoading,
        },
      );
    }
  }
}
