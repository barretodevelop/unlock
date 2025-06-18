// lib/features/onboarding/screens/interests_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/onboarding/constants/onboarding_data.dart';
import 'package:unlock/features/onboarding/providers/onboarding_provider.dart';
import 'package:unlock/features/onboarding/widgets/interest_chip_grid.dart';
import 'package:unlock/features/onboarding/widgets/onboarding_progress_bar.dart';
import 'package:unlock/features/onboarding/widgets/step_navigation_buttons.dart';

class InterestsSelectionScreen extends ConsumerStatefulWidget {
  const InterestsSelectionScreen({super.key});

  @override
  ConsumerState<InterestsSelectionScreen> createState() =>
      _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState
    extends ConsumerState<InterestsSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🎯 InterestsSelectionScreen: Iniciado');

    // Configurar animações
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Iniciar animação
    _animationController.forward();

    // Atualizar step no provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).goToStep(2);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    AppLogger.info('🧹 InterestsSelectionScreen: Disposed');
    super.dispose();
  }

  void _onInterestToggled(String interest) {
    ref.read(onboardingProvider.notifier).toggleInterest(interest);
  }

  void _onQuickFill() {
    ref.read(onboardingProvider.notifier).useQuickFillInterests();
  }

  /// ✅ CORREÇÃO: Método de completar com navegação segura
  Future<void> _handleComplete() async {
    // ✅ Evitar múltiplas execuções
    if (_isCompleting) {
      AppLogger.navigation('⚠️ Complete already in progress, ignoring');
      return;
    }

    if (!mounted) {
      AppLogger.navigation('⚠️ Component not mounted, aborting');
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    AppLogger.info('🎊 InterestsSelectionScreen: Completando onboarding');

    try {
      // ✅ Completar onboarding
      final success = await ref
          .read(onboardingProvider.notifier)
          .completeOnboarding();

      // ✅ Verificar se ainda está montado após operação async
      if (!mounted) {
        AppLogger.navigation('⚠️ Component unmounted after completion');
        return;
      }

      if (success) {
        // ✅ Mostrar feedback de sucesso
        await _showSuccessDialog();

        // ✅ A navegação para home ocorrerá automaticamente via redirect do GoRouter
      } else {
        // ✅ Mostrar erro
        _showErrorSnackBar();
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ InterestsSelectionScreen: Erro ao completar onboarding',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        _showErrorSnackBar();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            Icons.celebration,
            color: Theme.of(context).primaryColor,
            size: 48,
          ),
          title: const Text('🎉 Perfil Criado!'),
          content: const Text(
            'Seu perfil anônimo foi criado com sucesso!\n\nVamos encontrar pessoas incríveis para você conhecer.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Começar!'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Erro ao criar perfil. Tente novamente.'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ✅ CORREÇÃO: Método de voltar usando GoRouter
  void _handleBack() {
    if (_isCompleting) {
      AppLogger.navigation('⚠️ Cannot go back while completing');
      return;
    }

    try {
      AppLogger.navigation('⬅️ InterestsSelectionScreen: Voltando');

      // ✅ Usar GoRouter para voltar
      if (context.canPop()) {
        context.pop();
      } else {
        // ✅ Fallback: ir para a tela anterior do onboarding
        context.go('/onboarding'); // ou a rota específica da tela anterior
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao voltar', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final canAdvance = ref.watch(canAdvanceProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Progress Bar
                      const OnboardingProgressBar(),

                      const SizedBox(height: 32),

                      // Main Content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Center(
                                child: Text(
                                  OnboardingConstants.stepTitles[2]!,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Subtitle
                              Center(
                                child: Text(
                                  OnboardingConstants.stepSubtitles[2]!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Preview Card (se tiver avatar e nome)
                              if (onboardingState.avatarId != null &&
                                  onboardingState.codinome != null &&
                                  onboardingState.codinome!.isNotEmpty) ...[
                                Card(
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // Avatar Preview
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              OnboardingConstants.freeAvatars
                                                  .firstWhere(
                                                    (a) =>
                                                        a.id ==
                                                        onboardingState
                                                            .avatarId,
                                                  )
                                                  .emoji,
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // Name
                                        Expanded(
                                          child: Text(
                                            onboardingState.codinome!,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),

                                        // Age if available
                                        if (onboardingState.age != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .colorScheme
                                                  .surfaceVariant,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${onboardingState.age}a',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                              ],

                              // Interest Selection
                              InterestChipGrid(
                                selectedInterests:
                                    onboardingState.selectedInterests,
                                onInterestToggled: _onInterestToggled,
                                onQuickFill: _onQuickFill,
                                userAge: onboardingState.age,
                              ),

                              const SizedBox(height: 16),

                              // Progress Indicator
                              if (onboardingState
                                  .selectedInterests
                                  .isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: canAdvance
                                        ? theme.primaryColor.withOpacity(0.1)
                                        : theme.colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: canAdvance
                                          ? theme.primaryColor.withOpacity(0.3)
                                          : theme.colorScheme.outline
                                                .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        canAdvance
                                            ? Icons.check_circle_outline
                                            : Icons.info_outline,
                                        color: canAdvance
                                            ? theme.primaryColor
                                            : theme.colorScheme.onSurface
                                                  .withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          canAdvance
                                              ? 'Perfeito! Você já pode continuar 🎉'
                                              : 'Escolha pelo menos ${OnboardingConstants.minInterests - onboardingState.selectedInterests.length} interesse(s) a mais',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: canAdvance
                                                    ? theme.primaryColor
                                                    : theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.8),
                                                fontWeight: canAdvance
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),
                              ],

                              // Error Display
                              if (onboardingState.error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.error
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: theme.colorScheme.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          onboardingState.error!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.colorScheme.error,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Navigation
                      StepNavigationButtons(
                        onNext: canAdvance && !_isCompleting
                            ? _handleComplete
                            : null,
                        onBack: _isCompleting ? null : _handleBack,
                        nextText: OnboardingConstants.stepButtons[2]!,
                        backText: 'Voltar',
                        showBack: true,
                        isLoading: _isCompleting,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
