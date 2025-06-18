// lib/features/onboarding/screens/welcome_age_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/onboarding/constants/onboarding_data.dart';
import 'package:unlock/features/onboarding/providers/onboarding_provider.dart';
import 'package:unlock/features/onboarding/screens/anonymous_identity_screen.dart';
import 'package:unlock/features/onboarding/widgets/onboarding_progress_bar.dart';
import 'package:unlock/features/onboarding/widgets/step_navigation_buttons.dart';

class WelcomeAgeScreen extends ConsumerStatefulWidget {
  const WelcomeAgeScreen({super.key});

  @override
  ConsumerState<WelcomeAgeScreen> createState() => _WelcomeAgeScreenState();
}

class _WelcomeAgeScreenState extends ConsumerState<WelcomeAgeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime? _selectedDate;
  bool _showDatePicker = false;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🎬 WelcomeAgeScreen: Iniciado');

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

    // Reset do onboarding ao entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    AppLogger.debug('📅 WelcomeAgeScreen: Abrindo date picker');

    setState(() {
      _showDatePicker = true;
    });

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 20),
      ), // 20 anos atrás
      firstDate: DateTime.now().subtract(
        const Duration(days: 365 * 100),
      ), // 100 anos atrás
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 13),
      ), // 13 anos atrás
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    setState(() {
      _showDatePicker = false;
    });

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });

      // Atualizar provider
      await ref.read(onboardingProvider.notifier).setBirthDate(picked);

      AppLogger.info(
        '✅ WelcomeAgeScreen: Data selecionada',
        data: {
          'date': picked.toIso8601String(),
          'age': DateTime.now().difference(picked).inDays ~/ 365,
        },
      );
    }
  }

  void _handleNext() {
    AppLogger.info('➡️ WelcomeAgeScreen: Próxima tela');

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AnonymousIdentityScreen(),
        transitionDuration: AppConstants.animationDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Welcome Icon
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_open_rounded,
                                size: 50,
                                color: theme.primaryColor,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Title
                            Text(
                              OnboardingConstants.stepTitles[0]!,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 16),

                            // Subtitle
                            Text(
                              OnboardingConstants.stepSubtitles[0]!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 48),

                            // Date Picker Card
                            Card(
                              elevation: 2,
                              child: InkWell(
                                onTap: _showDatePicker ? null : _selectDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 32,
                                        color: _selectedDate != null
                                            ? theme.primaryColor
                                            : theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                      ),

                                      const SizedBox(height: 12),

                                      Text(
                                        _selectedDate != null
                                            ? 'Data selecionada:'
                                            : 'Quando você nasceu?',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                      ),

                                      if (_selectedDate != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                                          '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                                          '${_selectedDate!.year}',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          '${DateTime.now().difference(_selectedDate!).inDays ~/ 365} anos',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                        ),
                                      ],

                                      if (_showDatePicker) ...[
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              theme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Info Text
                            Text(
                              'Apenas para verificar idade mínima (${OnboardingConstants.minAge} anos)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),

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
                                    color: theme.colorScheme.error.withOpacity(
                                      0.3,
                                    ),
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
                          ],
                        ),
                      ),

                      // Bottom Navigation
                      StepNavigationButtons(
                        onNext: canAdvance ? _handleNext : null,
                        nextText: OnboardingConstants.stepButtons[0]!,
                        showBack: false,
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
