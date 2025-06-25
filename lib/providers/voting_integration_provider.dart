// lib/providers/voting_integration_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/models/submission_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/challenge_provider.dart';
import 'package:unlock/services/challenge_service.dart';

// ========== PROVIDERS DE INTEGRAÇÃO ==========

/// Provider para desafios em votação
final votingChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  AppLogger.debug('🗳️ Carregando desafios em votação');
  return ChallengeService.getVotingChallenges();
});

/// Provider para desafios prestes a entrar em votação
final upcomingVotingChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  AppLogger.debug('⏰ Carregando desafios com votação próxima');
  return ChallengeService.getUpcomingVotingChallenges();
});

/// Provider para estatísticas de um desafio
final challengeStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, challengeId) {
      AppLogger.debug('📊 Carregando estatísticas do desafio: $challengeId');
      return ChallengeService.getVotingStatistics(challengeId);
    });

/// Provider para detalhes completos de um desafio
final challengeDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, challengeId) {
      AppLogger.debug(
        '🔍 Carregando detalhes completos do desafio: $challengeId',
      );
      return ChallengeService.getChallengeWithDetails(challengeId);
    });

/// Provider para submissões mais votadas globalmente
final topVotedSubmissionsProvider = StreamProvider<List<Submission>>((ref) {
  AppLogger.debug('🏆 Carregando submissões mais votadas');
  return ChallengeService.getTopVotedSubmissions(limit: 10);
});

// ========== MONITORAMENTO AUTOMÁTICO ==========

/// Estado do monitoramento de votação
class VotingMonitorState {
  final bool isActive;
  final DateTime? lastCheck;
  final int challengesMonitored;
  final int statusUpdates;
  final String? error;

  const VotingMonitorState({
    this.isActive = false,
    this.lastCheck,
    this.challengesMonitored = 0,
    this.statusUpdates = 0,
    this.error,
  });

  VotingMonitorState copyWith({
    bool? isActive,
    DateTime? lastCheck,
    int? challengesMonitored,
    int? statusUpdates,
    String? error,
  }) {
    return VotingMonitorState(
      isActive: isActive ?? this.isActive,
      lastCheck: lastCheck ?? this.lastCheck,
      challengesMonitored: challengesMonitored ?? this.challengesMonitored,
      statusUpdates: statusUpdates ?? this.statusUpdates,
      error: error,
    );
  }
}

/// Provider para monitoramento automático de votação
final votingMonitorProvider =
    StateNotifierProvider<VotingMonitorNotifier, VotingMonitorState>((ref) {
      return VotingMonitorNotifier();
    });

/// Notifier para monitoramento de votação
class VotingMonitorNotifier extends StateNotifier<VotingMonitorState> {
  Timer? _monitorTimer;
  static const Duration _checkInterval = Duration(minutes: 5);

  VotingMonitorNotifier() : super(const VotingMonitorState());

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }

  /// Iniciar monitoramento automático
  void startMonitoring() {
    if (state.isActive) return;

    AppLogger.info('🤖 Iniciando monitoramento automático de votação');

    state = state.copyWith(isActive: true, error: null);

    _monitorTimer = Timer.periodic(_checkInterval, (_) => _performCheck());

    // Fazer primeira verificação imediatamente
    _performCheck();
  }

  /// Parar monitoramento
  void stopMonitoring() {
    if (!state.isActive) return;

    AppLogger.info('🛑 Parando monitoramento automático de votação');
    _stopMonitoring();
  }

  void _stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    state = state.copyWith(isActive: false);
  }

  /// Realizar verificação dos desafios
  Future<void> _performCheck() async {
    if (!state.isActive) return;

    try {
      AppLogger.debug('🔍 Verificando status de votação dos desafios...');

      await ChallengeService.scheduleVotingStatusChecks();

      state = state.copyWith(
        lastCheck: DateTime.now(),
        challengesMonitored: state.challengesMonitored + 1,
        error: null,
      );
    } catch (e) {
      AppLogger.error('❌ Erro no monitoramento de votação: $e');
      state = state.copyWith(lastCheck: DateTime.now(), error: e.toString());
    }
  }

  /// Forçar verificação manual
  Future<void> forceCheck() async {
    AppLogger.info('🔄 Verificação manual de status de votação');
    await _performCheck();
  }

  /// Obter estatísticas do monitoramento
  Map<String, dynamic> getMonitoringStats() {
    return {
      'isActive': state.isActive,
      'lastCheck': state.lastCheck?.toIso8601String(),
      'challengesMonitored': state.challengesMonitored,
      'statusUpdates': state.statusUpdates,
      'uptime': state.lastCheck != null
          ? DateTime.now().difference(state.lastCheck!).inMinutes
          : 0,
      'error': state.error,
    };
  }
}

// ========== HELPER PROVIDERS ==========

/// Provider para verificar se usuário tem desafios em votação
final userHasVotingChallengesProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider.select((state) => state.user));
  if (user == null) return false;

  final votingChallenges = ref.watch(votingChallengesProvider);

  return votingChallenges.when(
    data: (challenges) => challenges.any(
      (challenge) =>
          challenge.creatorId == user.uid ||
          challenge.participants.contains(user.uid),
    ),
    loading: () => false,
    error: (error, stack) => false,
  );
});

/// Provider para contagem de notificações de votação
final votingNotificationsCountProvider = Provider<int>((ref) {
  final user = ref.watch(authProvider.select((state) => state.user));
  if (user == null) return 0;

  final upcomingChallenges = ref.watch(upcomingVotingChallengesProvider);
  final votingChallenges = ref.watch(votingChallengesProvider);

  int count = 0;

  // Contar desafios prestes a entrar em votação
  upcomingChallenges.whenData((challenges) {
    count += challenges
        .where(
          (challenge) =>
              challenge.creatorId == user.uid ||
              challenge.participants.contains(user.uid),
        )
        .length;
  });

  // Contar desafios em votação ativa
  votingChallenges.whenData((challenges) {
    count += challenges
        .where(
          (challenge) =>
              challenge.creatorId == user.uid ||
              challenge.participants.contains(user.uid),
        )
        .length;
  });

  return count;
});

/// Provider para próximo evento de votação do usuário
final nextVotingEventProvider = Provider<DateTime?>((ref) {
  final user = ref.watch(authProvider.select((state) => state.user));
  if (user == null) return null;

  final upcomingChallenges = ref.watch(upcomingVotingChallengesProvider);

  return upcomingChallenges.when(
    data: (challenges) {
      final userChallenges = challenges
          .where(
            (challenge) =>
                challenge.creatorId == user.uid ||
                challenge.participants.contains(user.uid),
          )
          .toList();

      if (userChallenges.isEmpty) return null;

      // Encontrar próximo evento (início de votação mais próximo)
      final now = DateTime.now();
      DateTime? nextEvent;

      for (final challenge in userChallenges) {
        final votingStart =
            challenge.votingConfig?.votingStartsAt ??
            challenge.effectiveSubmissionEnd;

        if (votingStart.isAfter(now)) {
          if (nextEvent == null || votingStart.isBefore(nextEvent)) {
            nextEvent = votingStart;
          }
        }
      }

      return nextEvent;
    },
    loading: () => null,
    error: (error, stack) => null,
  );
});

// ========== ACTIONS PROVIDER ==========

/// Estado das ações de integração de votação
class VotingIntegrationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final DateTime? lastAction;

  const VotingIntegrationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.lastAction,
  });

  VotingIntegrationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    DateTime? lastAction,
  }) {
    return VotingIntegrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  VotingIntegrationState clearMessages() {
    return copyWith(error: null, successMessage: null);
  }
}

/// Provider para ações de integração de votação
final votingIntegrationProvider =
    StateNotifierProvider<VotingIntegrationNotifier, VotingIntegrationState>((
      ref,
    ) {
      return VotingIntegrationNotifier(ref);
    });

/// Notifier para ações de integração
class VotingIntegrationNotifier extends StateNotifier<VotingIntegrationState> {
  final Ref _ref;
  Timer? _messageTimer;

  VotingIntegrationNotifier(this._ref) : super(const VotingIntegrationState()) {
    // Iniciar monitoramento automaticamente quando o provider é criado
    _startMonitoringIfNeeded();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  /// Iniciar monitoramento se necessário
  void _startMonitoringIfNeeded() {
    final user = _ref.read(authProvider.select((state) => state.user));
    if (user != null) {
      // Aguardar um pouco antes de iniciar para evitar problemas de inicialização
      Timer(const Duration(seconds: 2), () {
        _ref.read(votingMonitorProvider.notifier).startMonitoring();
      });
    }
  }

  /// Atualizar status de desafio específico
  Future<bool> updateChallengeStatus(String challengeId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('🔄 Atualizando status do desafio: $challengeId');

      await ChallengeService.checkAndUpdateVotingStatus(challengeId);

      // Invalidar providers relacionados para atualização
      _ref.invalidate(challengeDetailsProvider(challengeId));
      _ref.invalidate(votingChallengesProvider);
      _ref.invalidate(upcomingVotingChallengesProvider);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Status atualizado com sucesso',
        lastAction: DateTime.now(),
      );

      _clearMessagesAfterDelay();
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro ao atualizar status: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar: ${e.toString()}',
      );
      _clearMessagesAfterDelay();
      return false;
    }
  }

  /// Sincronizar todos os desafios
  Future<bool> syncAllChallenges() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('🔄 Sincronizando todos os desafios...');

      await ChallengeService.scheduleVotingStatusChecks();

      // Invalidar todos os providers relacionados
      _ref.invalidate(votingChallengesProvider);
      _ref.invalidate(upcomingVotingChallengesProvider);
      _ref.invalidate(activeChallengesProvider);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Sincronização concluída',
        lastAction: DateTime.now(),
      );

      _clearMessagesAfterDelay();
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro na sincronização: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erro na sincronização: ${e.toString()}',
      );
      _clearMessagesAfterDelay();
      return false;
    }
  }

  /// Limpar mensagens
  void clearMessages() {
    state = state.clearMessages();
  }

  void _clearMessagesAfterDelay() {
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.clearMessages();
      }
    });
  }
}

// ========== DEBUG PROVIDERS ==========

/// Provider para informações de debug do sistema de votação
final votingDebugInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final monitorState = ref.watch(votingMonitorProvider);
  final votingChallenges = ref.watch(votingChallengesProvider);
  final upcomingChallenges = ref.watch(upcomingVotingChallengesProvider);
  final user = ref.watch(authProvider.select((state) => state.user));

  return {
    'monitor': {
      'isActive': monitorState.isActive,
      'lastCheck': monitorState.lastCheck?.toIso8601String(),
      'challengesMonitored': monitorState.challengesMonitored,
      'error': monitorState.error,
    },
    'challenges': {
      'voting': votingChallenges.when(
        data: (data) => data.length,
        loading: () => 'loading',
        error: (error, stack) => 'error: $error',
      ),
      'upcoming': upcomingChallenges.when(
        data: (data) => data.length,
        loading: () => 'loading',
        error: (error, stack) => 'error: $error',
      ),
    },
    'user': {
      'authenticated': user != null,
      'uid': user?.uid,
      'hasVotingChallenges': ref.watch(userHasVotingChallengesProvider),
      'notificationsCount': ref.watch(votingNotificationsCountProvider),
    },
    'nextEvent': ref.watch(nextVotingEventProvider)?.toIso8601String(),
    'timestamp': DateTime.now().toIso8601String(),
  };
});

// ========== INICIALIZAÇÃO ==========

/// Provider para inicialização do sistema de votação
final votingSystemInitProvider = FutureProvider<bool>((ref) async {
  AppLogger.info('🚀 Inicializando sistema de votação...');

  try {
    // Aguardar autenticação
    final user = ref.watch(authProvider.select((state) => state.user));
    if (user == null) {
      AppLogger.debug('⏳ Aguardando autenticação do usuário...');
      return false;
    }

    // Inicializar monitoramento
    await Future.delayed(const Duration(seconds: 1));
    ref.read(votingMonitorProvider.notifier).startMonitoring();

    // Carregar dados iniciais
    ref.read(votingChallengesProvider);
    ref.read(upcomingVotingChallengesProvider);

    AppLogger.info('✅ Sistema de votação inicializado com sucesso');
    return true;
  } catch (e) {
    AppLogger.error('❌ Erro na inicialização do sistema de votação: $e');
    return false;
  }
});

/// Invalidar todos os providers de votação (útil para refresh global)
void invalidateAllVotingProviders(Ref ref) {
  AppLogger.debug('🔄 Invalidando todos os providers de votação');

  ref.invalidate(votingChallengesProvider);
  ref.invalidate(upcomingVotingChallengesProvider);
  ref.invalidate(topVotedSubmissionsProvider);
  ref.invalidate(userHasVotingChallengesProvider);
  ref.invalidate(votingNotificationsCountProvider);
  ref.invalidate(nextVotingEventProvider);
}
