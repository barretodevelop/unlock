// lib/features/onboarding/providers/onboarding_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/onboarding/constants/onboarding_data.dart';
import 'package:unlock/providers/auth_provider.dart'; // ✅ Importar authProvider
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';
import 'package:unlock/services/auth_service.dart';
import 'package:unlock/services/firestore_service.dart';

// Provider principal
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier(ref); // ✅ Passar ref
    });

@immutable
class OnboardingState {
  final DateTime? birthDate;
  final String? avatarId;
  final String? codinome;
  final String? bio;
  final List<String> selectedInterests;
  final int currentStep;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.birthDate,
    this.avatarId,
    this.codinome,
    this.bio,
    this.selectedInterests = const [],
    this.currentStep = 0,
    this.isLoading = false,
    this.error,
  });

  // ✅ VALIDAÇÕES POR STEP
  bool get canCompleteStep1 {
    return birthDate != null && OnboardingConstants.isValidAge(birthDate!);
  }

  bool get canCompleteStep2 {
    return avatarId != null &&
        codinome != null &&
        OnboardingConstants.isValidCodinome(codinome!) &&
        bio != null &&
        OnboardingConstants.isValidBio(bio!);
  }

  bool get canCompleteStep3 {
    return OnboardingConstants.isValidInterestSelection(selectedInterests);
  }

  bool get canComplete => canCompleteStep3;

  // ✅ COMPUTED PROPERTIES
  int? get age {
    if (birthDate == null) return null;
    return DateTime.now().difference(birthDate!).inDays ~/ 365;
  }

  bool get isMinor {
    if (age == null) return false;
    return age! < OnboardingConstants.adultAge;
  }

  double get progress => (currentStep + 1) / 3;

  // ✅ STEP VALIDATION
  bool canAdvanceFromStep(int step) {
    switch (step) {
      case 0:
        return canCompleteStep1;
      case 1:
        return canCompleteStep2;
      case 2:
        return canCompleteStep3;
      default:
        return false;
    }
  }

  OnboardingState copyWith({
    DateTime? birthDate,
    String? avatarId,
    String? codinome,
    String? bio,
    List<String>? selectedInterests,
    int? currentStep,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      birthDate: birthDate ?? this.birthDate,
      avatarId: avatarId ?? this.avatarId,
      codinome: codinome ?? this.codinome,
      bio: bio ?? this.bio,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  String toString() {
    return 'OnboardingState(step: $currentStep, canComplete: $canComplete, age: $age, bio: $bio)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingState &&
        other.birthDate == birthDate &&
        other.avatarId == avatarId &&
        other.codinome == codinome &&
        other.bio == bio &&
        listEquals(other.selectedInterests, selectedInterests) &&
        other.currentStep == currentStep &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      birthDate,
      avatarId,
      codinome,
      bio,
      selectedInterests,
      currentStep,
      isLoading,
      error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final FirestoreService _firestoreService = FirestoreService();
  final Ref _ref; // ✅ Adicionar Ref
  DateTime? _onboardingStartTime;

  OnboardingNotifier(this._ref) : super(const OnboardingState()) {
    // ✅ Receber Ref
    _onboardingStartTime = DateTime.now();
    AppLogger.info('🎬 OnboardingNotifier: Inicializado');
    _trackAnalyticsEvent('onboarding_started');
  }

  // ✅ STEP 1: IDADE
  Future<void> setBirthDate(DateTime birthDate) async {
    AppLogger.info(
      '📅 OnboardingNotifier: Definindo data de nascimento',
      data: {
        'birthDate': birthDate.toIso8601String(),
        'age': DateTime.now().difference(birthDate).inDays ~/ 365,
      },
    );

    if (!OnboardingConstants.isValidAge(birthDate)) {
      final age = DateTime.now().difference(birthDate).inDays ~/ 365;
      AppLogger.warning(
        '⚠️ OnboardingNotifier: Idade inválida',
        data: {'age': age, 'minAge': OnboardingConstants.minAge},
      );

      state = state.copyWith(
        error: 'Idade mínima de ${OnboardingConstants.minAge} anos necessária',
      );

      await _trackAnalyticsEvent(
        'onboarding_age_invalid',
        data: {'provided_age': age, 'min_age': OnboardingConstants.minAge},
      );

      return;
    }

    state = state.copyWith(birthDate: birthDate, error: null);

    await _trackAnalyticsEvent(
      'onboarding_age_set',
      data: {'age': state.age, 'is_minor': state.isMinor},
    );
  }

  // ✅ STEP 2: AVATAR
  void setAvatar(String avatarId) {
    AppLogger.info(
      '🎭 OnboardingNotifier: Definindo avatar',
      data: {'avatarId': avatarId},
    );

    state = state.copyWith(avatarId: avatarId, error: null);

    _trackAnalyticsEvent(
      'onboarding_avatar_selected',
      data: {
        'avatar_id': avatarId,
        'step_duration_ms': DateTime.now()
            .difference(_onboardingStartTime!)
            .inMilliseconds,
      },
    );
  }

  // ✅ STEP 2: CODINOME
  void setCodinome(String codinome) {
    AppLogger.info(
      '📝 OnboardingNotifier: Definindo codinome',
      data: {'codinome': codinome},
    );

    if (!OnboardingConstants.isValidCodinome(codinome)) {
      AppLogger.warning(
        '⚠️ OnboardingNotifier: Codinome inválido',
        data: {'codinome': codinome},
      );

      state = state.copyWith(
        error:
            'Nome deve ter entre 1 e ${OnboardingConstants.maxCodinomeLength} caracteres',
      );
      return;
    }

    state = state.copyWith(codinome: codinome.trim(), error: null);

    _trackAnalyticsEvent(
      'onboarding_codinome_set',
      data: {'codinome_length': codinome.trim().length},
    );
  }

  // ✅ STEP 2: BIO
  void setBio(String bio) {
    AppLogger.info(
      '📝 OnboardingNotifier: Definindo bio',
      data: {'bio_length': bio.length},
    );

    state = state.copyWith(bio: bio, error: null);

    _trackAnalyticsEvent(
      'onboarding_bio_set',
      data: {'bio_length': bio.length},
    );
  }

  // ✅ STEP 3: INTERESSES
  void toggleInterest(String interest) {
    final currentInterests = List<String>.from(state.selectedInterests);

    if (currentInterests.contains(interest)) {
      currentInterests.remove(interest);
      AppLogger.debug(
        '➖ OnboardingNotifier: Removendo interesse',
        data: {'interest': interest},
      );
    } else {
      if (currentInterests.length >= OnboardingConstants.maxInterests) {
        AppLogger.warning(
          '⚠️ OnboardingNotifier: Máximo de interesses atingido',
        );
        state = state.copyWith(
          error: 'Máximo de ${OnboardingConstants.maxInterests} interesses',
        );
        return;
      }
      currentInterests.add(interest);
      AppLogger.debug(
        '➕ OnboardingNotifier: Adicionando interesse',
        data: {'interest': interest},
      );
    }

    state = state.copyWith(selectedInterests: currentInterests, error: null);

    _trackAnalyticsEvent(
      'onboarding_interest_toggled',
      data: {
        'interest': interest,
        'action': currentInterests.contains(interest) ? 'added' : 'removed',
        'total_selected': currentInterests.length,
      },
    );
  }

  // ✅ QUICK FILL DE INTERESSES
  void useQuickFillInterests() {
    if (state.age == null) {
      AppLogger.warning(
        '⚠️ OnboardingNotifier: Idade não definida para quick fill',
      );
      return;
    }

    final suggestions = OnboardingConstants.getInterestSuggestionsForAge(
      state.age!,
    );

    AppLogger.info(
      '⚡ OnboardingNotifier: Usando quick fill',
      data: {'age': state.age, 'suggestions': suggestions},
    );

    state = state.copyWith(selectedInterests: suggestions, error: null);

    _trackAnalyticsEvent(
      'onboarding_quick_fill_used',
      data: {'age': state.age, 'suggested_interests': suggestions},
    );
  }

  // ✅ NAVEGAÇÃO ENTRE STEPS
  void nextStep() {
    if (!state.canAdvanceFromStep(state.currentStep)) {
      AppLogger.warning(
        '⚠️ OnboardingNotifier: Não pode avançar do step',
        data: {'currentStep': state.currentStep},
      );
      return;
    }

    final nextStep = state.currentStep + 1;

    AppLogger.info(
      '➡️ OnboardingNotifier: Avançando step',
      data: {'from': state.currentStep, 'to': nextStep},
    );

    state = state.copyWith(currentStep: nextStep, error: null);

    _trackAnalyticsEvent(
      'onboarding_step_completed',
      data: {
        'completed_step': state.currentStep - 1,
        'next_step': state.currentStep,
      },
    );
  }

  void previousStep() {
    if (state.currentStep <= 0) return;

    final prevStep = state.currentStep - 1;

    AppLogger.info(
      '⬅️ OnboardingNotifier: Voltando step',
      data: {'from': state.currentStep, 'to': prevStep},
    );

    state = state.copyWith(currentStep: prevStep, error: null);

    _trackAnalyticsEvent(
      'onboarding_step_back',
      data: {'from_step': state.currentStep + 1, 'to_step': state.currentStep},
    );
  }

  void goToStep(int step) {
    if (step < 0 || step > 2) return;

    AppLogger.info(
      '🎯 OnboardingNotifier: Indo para step',
      data: {'currentStep': state.currentStep, 'targetStep': step},
    );

    state = state.copyWith(currentStep: step, error: null);
  }

  // ✅ COMPLETION DO ONBOARDING
  Future<bool> completeOnboarding() async {
    if (!state.canComplete) {
      AppLogger.warning('⚠️ OnboardingNotifier: Não pode completar onboarding');
      state = state.copyWith(error: 'Preencha todos os campos obrigatórios');
      return false;
    }

    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      AppLogger.error('❌ OnboardingNotifier: Usuário não autenticado');
      state = state.copyWith(error: 'Usuário não autenticado');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info(
        '🎯 OnboardingNotifier: Completando onboarding',
        data: {
          'uid': currentUser.uid,
          'codinome': state.codinome,
          'avatarId': state.avatarId,
          'interesesCount': state.selectedInterests.length,
          'age': state.age,
        },
      );

      // Preparar dados para salvar
      final onboardingData = {
        'codinome': state.codinome!,
        'avatarId': state.avatarId!,
        'bio': state.bio!,
        'birthDate': state.birthDate!.toIso8601String(),
        'interesses': state.selectedInterests,
        'isMinor': state.isMinor,
        'connectionLevel': OnboardingConstants.defaultConnectionLevel,
        'onboardingCompleted': true,
        'onboardingCompletedAt': DateTime.now().toIso8601String(),
        // Manter relationshipGoal como null para definir depois
        'relationshipGoal': null,
      };

      // Salvar no Firestore
      await _firestoreService.updateUser(currentUser.uid, onboardingData);

      // ✅ Atualizar o AuthProvider localmente com os dados do onboarding
      // para evitar uma leitura extra do Firestore apenas para a navegação.
      final baseUser = _ref.read(authProvider).user;
      if (baseUser != null) {
        final updatedUser = baseUser.copyWith(
          codinome: state.codinome!,
          avatarId: state.avatarId!,
          bio: state.bio!,
          birthDate: state.birthDate!,
          interesses: state.selectedInterests,
          // isMinor: state.isMinor,
          onboardingCompleted: true,
          // Outros campos que podem ser atualizados/derivados no onboarding
          // connectionLevel: OnboardingConstants.defaultConnectionLevel,
          // relationshipGoal: null, // Se aplicável
        );
        _ref
            .read(authProvider.notifier)
            .updateUserWithOnboardingData(updatedUser);
        AppLogger.info(
          '🔄 AuthProvider atualizado localmente após onboarding',
          data: {
            'userId': updatedUser.uid,
            'onboardingCompleted': updatedUser.onboardingCompleted,
          },
        );
      } else {
        AppLogger.error(
          '❌ OnboardingNotifier: baseUser nulo no AuthProvider ao tentar atualizar localmente.',
        );
        // Como fallback, ou para garantir, poderia chamar refreshUser aqui, mas a ideia é evitar.
      }

      // Analytics de conclusão
      final completionDuration = DateTime.now().difference(
        _onboardingStartTime!,
      );

      await _trackAnalyticsEvent(
        'onboarding_completed',
        data: {
          'duration_ms': completionDuration.inMilliseconds,
          'age': state.age,
          'is_minor': state.isMinor,
          'interests_count': state.selectedInterests.length,
          'avatar_id': state.avatarId,
          'used_quick_fill': false, // TODO: track this
        },
      );

      AppLogger.info(
        '✅ OnboardingNotifier: Onboarding completado com sucesso',
        data: {
          'uid': currentUser.uid,
          'duration': '${completionDuration.inSeconds}s',
        },
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      AppLogger.error('❌ OnboardingNotifier: Erro ao completar onboarding: $e');

      await _trackAnalyticsEvent(
        'onboarding_completion_error',
        data: {
          'error_type': e.runtimeType.toString(),
          'error_message': e.toString(),
        },
      );

      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao salvar dados. Tente novamente.',
      );

      return false;
    }
  }

  // ✅ CLEAR ERROR
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // ✅ RESET
  void reset() {
    AppLogger.info('🔄 OnboardingNotifier: Reset');

    state = const OnboardingState();
    _onboardingStartTime = DateTime.now();

    _trackAnalyticsEvent('onboarding_reset');
  }

  // ✅ ANALYTICS HELPER
  Future<void> _trackAnalyticsEvent(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          eventName,
          parameters: data,
          category: EventCategory.user,
          priority: EventPriority.medium,
        );
      }
    } catch (e) {
      AppLogger.debug('Falha ao rastrear evento de onboarding: $e');
    }
  }

  @override
  void dispose() {
    AppLogger.info('🧹 OnboardingNotifier: Disposing');

    // Track abandonment if not completed
    if (!state.canComplete) {
      _trackAnalyticsEvent(
        'onboarding_abandoned',
        data: {
          'last_step': state.currentStep,
          'time_spent_ms': _onboardingStartTime != null
              ? DateTime.now().difference(_onboardingStartTime!).inMilliseconds
              : 0,
        },
      );
    }

    super.dispose();
  }
}

// ✅ PROVIDERS AUXILIARES
final onboardingProgressProvider = Provider<double>((ref) {
  final state = ref.watch(onboardingProvider);
  return state.progress;
});

final canAdvanceProvider = Provider<bool>((ref) {
  final state = ref.watch(onboardingProvider);
  return state.canAdvanceFromStep(state.currentStep);
});

final currentStepTitleProvider = Provider<String>((ref) {
  final state = ref.watch(onboardingProvider);
  return OnboardingConstants.stepTitles[state.currentStep] ?? '';
});

final currentStepSubtitleProvider = Provider<String>((ref) {
  final state = ref.watch(onboardingProvider);
  return OnboardingConstants.stepSubtitles[state.currentStep] ?? '';
});

final currentStepButtonTextProvider = Provider<String>((ref) {
  final state = ref.watch(onboardingProvider);
  return OnboardingConstants.stepButtons[state.currentStep] ?? 'Continuar';
});
