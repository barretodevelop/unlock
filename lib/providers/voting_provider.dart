// lib/providers/voting_provider.dart - VERSÃO COMPLETA COM TODOS OS PROVIDERS
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/models/submission_model.dart';
import 'package:unlock/models/vote_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/challenge_service.dart';
import 'package:unlock/services/voting_service.dart';

// ========== STREAM PROVIDERS ==========

/// Provider para votos de uma submissão
final submissionVotesProvider = StreamProvider.family<List<Vote>, String>((ref, submissionId) {
  AppLogger.debug('🗳️ Carregando votos da submissão: $submissionId');
  return VotingService.getSubmissionVotes(submissionId);
});

/// Provider para estatísticas de votação de uma submissão
final votingStatsProvider = FutureProvider.family<VotingStats, String>((ref, submissionId) {
  AppLogger.debug('📊 Carregando estatísticas de votação: $submissionId');
  return VotingService.getSubmissionVotingStats(submissionId);
});

/// Provider para ranking de votação de um desafio - AQUI ESTÁ!
final votingRankingProvider = StreamProvider.family<List<VotingStats>, String>((ref, challengeId) {
  AppLogger.debug('🏆 Carregando ranking de votação: $challengeId');
  return VotingService.getVotingRanking(challengeId: challengeId);
});

/// Provider para voto do usuário em uma submissão
final userVoteProvider = FutureProvider.family<Vote?, UserVoteQuery>((ref, query) {
  AppLogger.debug('👤 Verificando voto do usuário: ${query.submissionId}');
  return VotingService.getUserVoteOnSubmission(
    submissionId: query.submissionId,
    voterId: query.userId,
  );
});

/// Provider para votos do usuário em um desafio
final userChallengeVotesProvider = StreamProvider.family<List<Vote>, UserChallengeQuery>((ref, query) {
  AppLogger.debug('📋 Carregando votos do usuário no desafio: ${query.challengeId}');
  return VotingService.getUserVotesInChallenge(
    challengeId: query.challengeId,
    voterId: query.userId,
  );
});

/// Provider para submissões mais votadas globalmente
final topVotedSubmissionsProvider = StreamProvider<List<Submission>>((ref) {
  AppLogger.debug('🏆 Carregando submissões mais votadas');
  return ChallengeService.getTopVotedSubmissions(limit: 10);
});

// ========== STATE PROVIDERS ==========

/// Estado das ações de votação
class VotingActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String? lastVotedSubmissionId;
  final VoteType? lastVoteType;

  const VotingActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.lastVotedSubmissionId,
    this.lastVoteType,
  });

  VotingActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    String? lastVotedSubmissionId,
    VoteType? lastVoteType,
  }) {
    return VotingActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      lastVotedSubmissionId: lastVotedSubmissionId ?? this.lastVotedSubmissionId,
      lastVoteType: lastVoteType ?? this.lastVoteType,
    );
  }

  /// Reset de mensagens
  VotingActionState clearMessages() {
    return copyWith(error: null, successMessage: null);
  }
}

/// Provider para ações de votação
final votingActionProvider = StateNotifierProvider<VotingActionNotifier, VotingActionState>((ref) {
  return VotingActionNotifier(ref);
});

/// Notifier para ações de votação
class VotingActionNotifier extends StateNotifier<VotingActionState> {
  final Ref _ref;
  Timer? _messageTimer;

  VotingActionNotifier(this._ref) : super(const VotingActionState());

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  /// Votar em uma submissão
  Future<bool> voteOnSubmission({
    required String submissionId,
    required String challengeId,
    required VoteType voteType,
    VotingConfig? config,
  }) async {
    final user = _ref.read(authProvider.select((state) => state.user));
    if (user == null) {
      _setError('Usuário não autenticado');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('🗳️ Votando: ${voteType.emoji} em $submissionId');

      final success = await VotingService.voteOnSubmission(
        submissionId: submissionId,
        challengeId: challengeId,
        voterId: user.uid,
        voterUsername: user.username,
        voteType: voteType,
        config: config,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Voto ${voteType.emoji} registrado!',
          lastVotedSubmissionId: submissionId,
          lastVoteType: voteType,
        );

        // Invalidar providers relacionados para atualização
        _ref.invalidate(submissionVotesProvider(submissionId));
        _ref.invalidate(votingStatsProvider(submissionId));
        _ref.invalidate(votingRankingProvider(challengeId));
        _ref.invalidate(userVoteProvider(UserVoteQuery(submissionId, user.uid)));

        _clearMessagesAfterDelay();
        AppLogger.info('✅ Voto registrado com sucesso');
        return true;
      } else {
        _setError('Não foi possível registrar o voto');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao votar: $e');
      _setError('Erro inesperado: ${e.toString()}');
      return false;
    }
  }

  /// Remover voto de uma submissão
  Future<bool> removeVote({
    required String submissionId,
    required String challengeId,
  }) async {
    final user = _ref.read(authProvider.select((state) => state.user));
    if (user == null) {
      _setError('Usuário não autenticado');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('🗑️ Removendo voto de $submissionId');

      final success = await VotingService.removeVote(
        submissionId: submissionId,
        voterId: user.uid,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Voto removido',
          lastVotedSubmissionId: submissionId,
          lastVoteType: null,
        );

        // Invalidar providers relacionados
        _ref.invalidate(submissionVotesProvider(submissionId));
        _ref.invalidate(votingStatsProvider(submissionId));
        _ref.invalidate(votingRankingProvider(challengeId));
        _ref.invalidate(userVoteProvider(UserVoteQuery(submissionId, user.uid)));

        _clearMessagesAfterDelay();
        AppLogger.info('✅ Voto removido com sucesso');
        return true;
      } else {
        _setError('Não foi possível remover o voto');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao remover voto: $e');
      _setError('Erro inesperado: ${e.toString()}');
      return false;
    }
  }

  /// Alterar tipo de voto (votar novamente)
  Future<bool> changeVote({
    required String submissionId,
    required String challengeId,
    required VoteType newVoteType,
    VotingConfig? config,
  }) async {
    AppLogger.info('🔄 Alterando voto para: ${newVoteType.emoji}');
    
    // Simplesmente votar novamente (o serviço cuida da substituição)
    return await voteOnSubmission(
      submissionId: submissionId,
      challengeId: challengeId,
      voteType: newVoteType,
      config: config,
    );
  }

  /// Verificar se usuário pode votar
  bool canUserVote({
    required String submissionId,
    required String submissionUserId,
    VotingConfig? config,
  }) {
    final user = _ref.read(authProvider.select((state) => state.user));
    if (user == null) return false;

    // Verificar configuração de votação
    if (config != null && !config.isVotingActive) {
      return false;
    }

    // Verificar auto-voto
    if (submissionUserId == user.uid && (config?.allowSelfVoting == false)) {
      return false;
    }

    return true;
  }

  /// Obter tipo de voto atual do usuário
  Future<VoteType?> getCurrentUserVote(String submissionId) async {
    final user = _ref.read(authProvider.select((state) => state.user));
    if (user == null) return null;

    try {
      final vote = await VotingService.getUserVoteOnSubmission(
        submissionId: submissionId,
        voterId: user.uid,
      );
      return vote?.type;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar voto atual: $e');
      return null;
    }
  }

  /// Limpar mensagens
  void clearMessages() {
    state = state.clearMessages();
  }

  // ========== MÉTODOS PRIVADOS ==========

  void _setError(String message) {
    state = state.copyWith(isLoading: false, error: message);
    _clearMessagesAfterDelay();
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

// ========== HELPER CLASSES ==========

/// Query para buscar voto específico do usuário
class UserVoteQuery {
  final String submissionId;
  final String userId;

  const UserVoteQuery(this.submissionId, this.userId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserVoteQuery &&
        other.submissionId == submissionId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(submissionId, userId);

  @override
  String toString() => 'UserVoteQuery($submissionId, $userId)';
}

/// Query para buscar votos do usuário em um desafio
class UserChallengeQuery {
  final String challengeId;
  final String userId;

  const UserChallengeQuery(this.challengeId, this.userId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserChallengeQuery &&
        other.challengeId == challengeId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(challengeId, userId);

  @override
  String toString() => 'UserChallengeQuery($challengeId, $userId)';
}

// ========== CONVENIENCE PROVIDERS ==========

/// Provider para verificar se submissão está em votação
final isVotingActiveProvider = Provider.family<bool, VotingConfig?>((ref, config) {
  return config?.isVotingActive ?? false;
});

/// Provider para tempo restante de votação
final votingTimeRemainingProvider = Provider.family<Duration?, VotingConfig?>((ref, config) {
  return config?.timeUntilVotingEnds;
});

/// Provider para top 3 no ranking de votos
final votingTop3Provider = Provider.family<List<VotingStats>, String>((ref, challengeId) {
  final rankingAsync = ref.watch(votingRankingProvider(challengeId));
  return rankingAsync.when(
    data: (ranking) => ranking.take(3).toList(),
    loading: () => [],
    error: (error, stack) => [],
  );
});

// ========== PROVIDERS DE INTEGRAÇÃO ==========

/// Provider para desafios em votação
final votingChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  AppLogger.debug('🗳️ Carregando desafios em votação');
  return ChallengeService.getChallengesByStatus(ChallengeStatus.voting);
});

/// Provider para desafios prestes a entrar em votação
final upcomingVotingChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  AppLogger.debug('⏰ Carregando desafios com votação próxima');
  return ChallengeService.getActiveChallenges().map((challenges) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    return challenges.where((challenge) {
      return challenge.hasVoting &&
             challenge.submissionEndsAt != null &&
             challenge.submissionEndsAt!.isAfter(now) &&
             challenge.submissionEndsAt!.isBefore(tomorrow);
    }).toList();
  });
});

/// Provider para verificar se usuário tem desafios em votação
final userHasVotingChallengesProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider.select((state) => state.user));
  if (user == null) return false;

  final votingChallenges = ref.watch(votingChallengesProvider);
  
  return votingChallenges.when(
    data: (challenges) => challenges.any((challenge) => 
        challenge.creatorId == user.uid || 
        challenge.participants.contains(user.uid)),
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
    count += challenges.where((challenge) => 
        challenge.creatorId == user.uid || 
        challenge.participants.contains(user.uid)).length;
  });
  
  // Contar desafios em votação ativa
  votingChallenges.whenData((challenges) {
    count += challenges.where((challenge) => 
        challenge.creatorId == user.uid || 
        challenge.participants.contains(user.uid)).length;
  });
  
  return count;
});

/// Provider para estatísticas de um desafio
final challengeStatisticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, challengeId) {
  AppLogger.debug('📊 Carregando estatísticas do desafio: $challengeId');
  return VotingService.getAggregatedVotingStats(challengeId);
});

// ========== EXEMPLO DE USO ==========

/*

// 1. Para usar o ranking de votação:
final rankingAsync = ref.watch(votingRankingProvider('challenge_id_aqui'));

rankingAsync.when(
  data: (rankings) => ListView.builder(
    itemCount: rankings.length,
    itemBuilder: (context, index) {
      final stats = rankings[index];
      return ListTile(
        title: Text('Submissão ${index + 1}'),
        subtitle: Text('${stats.totalVotes} votos - Score: ${stats.score}'),
        trailing: Text('#${stats.ranking}'),
      );
    },
  ),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Erro: $error'),
);

// 2. Para votar em uma submissão:
final votingNotifier = ref.read(votingActionProvider.notifier);

await votingNotifier.voteOnSubmission(
  submissionId: 'submission_id',
  challengeId: 'challenge_id', 
  voteType: VoteType.love,
  config: challenge.votingConfig,
);

// 3. Para verificar voto do usuário:
final userVoteAsync = ref.watch(
  userVoteProvider(UserVoteQuery('submission_id', 'user_id'))
);

*/