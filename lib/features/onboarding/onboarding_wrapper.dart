// lib/features/onboarding/onboarding_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/screens/home_screen.dart';
import 'package:unlock/features/onboarding/providers/onboarding_provider.dart';
import 'package:unlock/features/onboarding/screens/anonymous_identity_screen.dart';
import 'package:unlock/features/onboarding/screens/interests_selection_screen.dart';
import 'package:unlock/features/onboarding/screens/welcome_age_screen.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Wrapper principal do sistema de onboarding
///
/// Coordena a navegação entre as 3 telas do onboarding e gerencia
/// o estado global do processo, incluindo analytics e validações.
class OnboardingWrapper extends ConsumerStatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper>
    with TickerProviderStateMixin {
  // Controllers para animações e navegação
  late PageController _pageController;
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;

  // Estado interno
  bool _isInitialized = false;
  bool _canPop = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();

    _startTime = DateTime.now();
    AppLogger.info('🎬 OnboardingWrapper: Inicializado');

    // Configurar controllers
    _pageController = PageController(initialPage: 0);
    _transitionController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeIn),
    );

    // Inicialização assíncrona
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transitionController.dispose();

    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    AppLogger.info(
      '🧹 OnboardingWrapper: Disposed',
      data: {'sessionDuration': '${duration}s'},
    );

    super.dispose();
  }

  /// Inicialização do wrapper
  Future<void> _initialize() async {
    try {
      AppLogger.debug('🔄 OnboardingWrapper: Inicializando...');

      // Verificar se usuário está autenticado
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        AppLogger.warning('⚠️ OnboardingWrapper: Usuário não autenticado');
        _navigateToLogin();
        return;
      }

      // Verificar se realmente precisa de onboarding
      if (!authState.needsOnboarding) {
        AppLogger.info('ℹ️ OnboardingWrapper: Onboarding já completo');
        _navigateToHome();
        return;
      }

      // Reset do provider de onboarding
      ref.read(onboardingProvider.notifier).reset();

      // Iniciar animação de entrada
      await _transitionController.forward();

      setState(() {
        _isInitialized = true;
      });

      AppLogger.info('✅ OnboardingWrapper: Inicialização completa');
    } catch (e) {
      AppLogger.error('❌ OnboardingWrapper: Erro na inicialização: $e');
      _showErrorAndExit();
    }
  }

  /// Listener para mudanças no provider de onboarding
  void _listenToOnboardingChanges(
    OnboardingState? previous,
    OnboardingState current,
  ) {
    if (!_isInitialized) return;

    // Navegar para step específico se mudou
    if (previous?.currentStep != current.currentStep) {
      _navigateToStep(current.currentStep);
    }

    // Verificar se onboarding foi completado
    if (current.canComplete && !current.isLoading) {
      _checkForCompletion();
    }

    // Atualizar controle de voltar
    setState(() {
      _canPop = current.currentStep > 0;
    });
  }

  /// Navegar para step específico
  void _navigateToStep(int step) {
    if (step < 0 || step > 2) return;

    AppLogger.debug('🔄 OnboardingWrapper: Navegando para step $step');

    _pageController.animateToPage(
      step,
      duration: AppConstants.animationDuration,
      curve: Curves.easeInOut,
    );
  }

  /// Verificar se onboarding pode ser completado
  void _checkForCompletion() {
    final onboardingState = ref.read(onboardingProvider);

    if (onboardingState.currentStep == 2 && onboardingState.canComplete) {
      AppLogger.debug('🎯 OnboardingWrapper: Pronto para completion');
      // O completion será feito na InterestsSelectionScreen
    }
  }

  /// Handler para voltar no sistema
  Future<bool> _onWillPop() async {
    final onboardingState = ref.read(onboardingProvider);

    if (!_canPop || onboardingState.currentStep <= 0) {
      // Se estiver no primeiro step, confirmar saída
      return await _showExitConfirmation();
    }

    // Voltar ao step anterior
    ref.read(onboardingProvider.notifier).previousStep();
    return false; // Não sair do app
  }

  /// Confirmar saída do onboarding
  Future<bool> _showExitConfirmation() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do cadastro?'),
        content: const Text(
          'Você perderá o progresso atual. Tem certeza que deseja sair?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sair',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      AppLogger.info('🚪 OnboardingWrapper: Usuário optou por sair');
      _navigateToLogin();
    }

    return shouldExit ?? false;
  }

  /// Mostrar erro e sair
  void _showErrorAndExit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: const Text(
          'Ocorreu um erro durante o cadastro. '
          'Por favor, tente novamente.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLogin();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Navegar para login
  void _navigateToLogin() {
    AppLogger.info('🔑 OnboardingWrapper: Navegando para login');

    Navigator.of(context).pushReplacementNamed('/login');
  }

  /// Navegar para home após completion
  void _navigateToHome() {
    AppLogger.info('🏠 OnboardingWrapper: Navegando para home');

    final sessionDuration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
        transitionDuration: AppConstants.longAnimationDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );

    AppLogger.info(
      '✅ OnboardingWrapper: Navegação para home completa',
      data: {'sessionDuration': '${sessionDuration}s'},
    );
  }

  /// Listener para mudanças de page
  void _onPageChanged(int page) {
    final onboardingNotifier = ref.read(onboardingProvider.notifier);

    if (page != ref.read(onboardingProvider).currentStep) {
      onboardingNotifier.goToStep(page);
    }

    AppLogger.debug('📄 OnboardingWrapper: Page changed to $page');
  }

  @override
  Widget build(BuildContext context) {
    // Escutar mudanças no onboarding
    ref.listen<OnboardingState>(onboardingProvider, _listenToOnboardingChanges);

    // Escutar mudanças no auth (caso usuário seja deslogado)
    ref.listen<AuthState>(authProvider, (previous, current) {
      if (!current.isAuthenticated) {
        AppLogger.warning('⚠️ OnboardingWrapper: Usuário deslogado');
        _navigateToLogin();
      }
    });

    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: AnimatedBuilder(
          animation: _transitionController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics:
                    const NeverScrollableScrollPhysics(), // Navegação apenas por botões
                children: const [
                  WelcomeAgeScreen(),
                  AnonymousIdentityScreen(),
                  InterestsSelectionScreen(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Tela de loading durante inicialização
  Widget _buildLoadingScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_open_rounded,
                size: 40,
                color: theme.primaryColor,
              ),
            ),

            const SizedBox(height: 32),

            // Loading text
            Text(
              'Preparando seu cadastro...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),

            const SizedBox(height: 16),

            // Loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(theme.primaryColor),
              ),
            ),

            const SizedBox(height: 48),

            // App name
            Text(
              AppConstants.appName.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension para facilitar navegação do onboarding
extension OnboardingNavigation on BuildContext {
  /// Navegar para próxima tela do onboarding
  void nextOnboardingStep() {
    final container = ProviderScope.containerOf(this);
    container.read(onboardingProvider.notifier).nextStep();
  }

  /// Voltar na tela do onboarding
  void previousOnboardingStep() {
    final container = ProviderScope.containerOf(this);
    container.read(onboardingProvider.notifier).previousStep();
  }

  /// Ir para step específico
  void goToOnboardingStep(int step) {
    final container = ProviderScope.containerOf(this);
    container.read(onboardingProvider.notifier).goToStep(step);
  }

  /// Verificar se pode avançar no onboarding
  bool canAdvanceOnboarding() {
    final container = ProviderScope.containerOf(this);
    final state = container.read(onboardingProvider);
    return state.canAdvanceFromStep(state.currentStep);
  }

  /// Obter progresso atual do onboarding
  double getOnboardingProgress() {
    final container = ProviderScope.containerOf(this);
    final state = container.read(onboardingProvider);
    return state.progress;
  }
}

/// Utilities para o onboarding wrapper
class OnboardingWrapperUtils {
  /// Verificar se dispositivo suporta haptic feedback
  static bool get supportsHapticFeedback {
    return true; // Assumir que sim por padrão
  }

  /// Feedback haptic leve
  static void lightHaptic() {
    if (supportsHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  /// Feedback haptic médio
  static void mediumHaptic() {
    if (supportsHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Feedback haptic para seleção
  static void selectionHaptic() {
    if (supportsHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  /// Calcular tempo estimado restante
  static String getEstimatedTimeRemaining(int currentStep) {
    final stepsRemaining = 2 - currentStep;
    final timePerStep = 45; // segundos médios por step
    final totalSeconds = stepsRemaining * timePerStep;

    if (totalSeconds <= 0) return 'Finalizando...';
    if (totalSeconds < 60) return '${totalSeconds}s restantes';

    final minutes = totalSeconds ~/ 60;
    return '${minutes}min restantes';
  }

  /// Validar se pode pular step (apenas para desenvolvimento)
  static bool canSkipStep(int step) {
    // Em produção, sempre retornar false
    // Em desenvolvimento, pode permitir pular para testes
    return false;
  }
}
