// lib/providers/challenge_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/models/submission_model.dart';
import 'package:unlock/models/vote_model.dart';
import 'package:unlock/services/challenge_service.dart';
import 'package:unlock/services/voting_service.dart';

// Provider para desafios ativos
final activeChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  return ChallengeService.getActiveChallenges();
});

// Provider para desafios por tipo
final challengesByTypeProvider =
    StreamProvider.family<List<Challenge>, ChallengeType>((ref, type) {
      return ChallengeService.getChallengesByType(type);
    });

// Provider para meus desafios
final myChallengesProvider = StreamProvider.family<List<Challenge>, String>((
  ref,
  userId,
) {
  return ChallengeService.getMyChallenges(userId);
});

// Provider para submissões de um desafio
final challengeSubmissionsProvider =
    StreamProvider.family<List<Submission>, String>((ref, challengeId) {
      return ChallengeService.getChallengeSubmissions(challengeId);
    });

// Estado do provider de ações
class ChallengeActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ChallengeActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ChallengeActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ChallengeActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Provider para ações dos desafios
final challengeActionProvider =
    StateNotifierProvider<ChallengeActionNotifier, ChallengeActionState>((ref) {
      return ChallengeActionNotifier();
    });

class ChallengeActionNotifier extends StateNotifier<ChallengeActionState> {
  ChallengeActionNotifier() : super(const ChallengeActionState());

  // Participar de desafio
  Future<bool> joinChallenge(String challengeId, String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await ChallengeService.joinChallenge(challengeId, userId);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Você entrou no desafio!',
        );
        // Limpar mensagem após delay
        Timer(const Duration(seconds: 3), () {
          if (mounted) state = state.copyWith(successMessage: null);
        });
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Não foi possível entrar no desafio',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao entrar no desafio: ${e.toString()}',
      );
      return false;
    }
  }

  // Submeter entrada
  Future<Object?> submitEntry(
    String challengeId,
    String userId,
    String username,
    String userAvatar,
    SubmissionType type,
    Map<String, dynamic> content,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await ChallengeService.submitToChallenge(
        challengeId: challengeId,
        userId: userId,
        username: username,
        userAvatar: userAvatar,
        type: type,
        content: content,
      );

      if (success != null) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Submissão enviada com sucesso!',
        );
        Timer(const Duration(seconds: 3), () {
          if (mounted) state = state.copyWith(successMessage: null);
        });
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Erro ao enviar submissão',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao enviar: ${e.toString()}',
      );
      return false;
    }
  }

  // Votar em submissão
  Future<bool> voteSubmission({
    required String submissionId,
    required String userId,
    required String challengeId,
    required String voterUsername,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await VotingService.voteOnSubmission(
        submissionId: submissionId,
        voterId: userId,
        challengeId: challengeId,
        voterUsername: voterUsername,
        voteType: VoteType.like,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Voto computado!',
        );
        Timer(const Duration(seconds: 2), () {
          if (mounted) state = state.copyWith(successMessage: null);
        });
      } else {
        state = state.copyWith(isLoading: false, error: 'Erro ao votar');
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao votar: ${e.toString()}',
      );
      return false;
    }
  }

  // Criar desafio
  Future<String?> createChallenge({
    required String creatorId,
    required String title,
    required String description,
    required ChallengeType type,
    required ArenaType arena,
    required DateTime startsAt,
    required DateTime submissionEndsAt,
    required DateTime votingEndsAt,
    required bool allowSelfVoting,
    required int maxVotesPerUser,
    required List<VoteType> allowedVoteTypes,
    required Map<String, dynamic> antiManipulation,
    required int maxParticipants,
    required int entryFee,
    required List<String> tags,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final challengeId = await ChallengeService.createChallengeWithVoting(
        title: title,
        description: description,
        type: type,
        arena: arena,
        creatorId: creatorId,
        startsAt: startsAt,
        submissionEndsAt: submissionEndsAt,
        votingEndsAt: votingEndsAt,
        allowSelfVoting: allowSelfVoting,
        maxVotesPerUser: maxVotesPerUser,
        allowedVoteTypes: allowedVoteTypes,
        antiManipulation: antiManipulation,
        maxParticipants: maxParticipants,
        entryFee: entryFee,
        tags: tags,
      );

      if (challengeId != null) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Desafio criado com sucesso!',
        );
        Timer(const Duration(seconds: 3), () {
          if (mounted) state = state.copyWith(successMessage: null);
        });
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Erro ao criar desafio',
        );
      }

      return challengeId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar: ${e.toString()}',
      );
      return null;
    }
  }

  // Limpar erro
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Limpar mensagem de sucesso
  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }
}
