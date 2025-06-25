// lib/features/voting/utils/voting_validator.dart
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/voting/constants/voting_constants.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/models/submission_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/models/vote_model.dart';

/// Resultado de validação
class ValidationResult {
  final bool isValid;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const ValidationResult.success({this.metadata})
    : isValid = true,
      errorCode = null,
      errorMessage = null;

  const ValidationResult.failure({
    required this.errorCode,
    required this.errorMessage,
    this.metadata,
  }) : isValid = false;

  @override
  String toString() {
    return isValid
        ? 'ValidationResult.success'
        : 'ValidationResult.failure($errorCode: $errorMessage)';
  }
}

/// Validador principal do sistema de votação
class VotingValidator {
  VotingValidator._();

  // ========== VALIDAÇÕES DE USUÁRIO ==========

  /// Validar se usuário pode votar em geral
  static ValidationResult validateUserCanVote(UserModel? user) {
    if (user == null) {
      return const ValidationResult.failure(
        errorCode: 'user_not_authenticated',
        errorMessage: 'Usuário não autenticado',
      );
    }

    // Verificar se usuário está ativo
    if (user.createdAt.isAfter(
      DateTime.now().subtract(const Duration(hours: 24)),
    )) {
      return const ValidationResult.failure(
        errorCode: 'user_too_new',
        errorMessage: 'Conta muito recente para votar',
      );
    }

    // Verificar se usuário completou onboarding
    if (!user.onboardingCompleted) {
      return const ValidationResult.failure(
        errorCode: 'onboarding_incomplete',
        errorMessage: 'Complete seu perfil para votar',
      );
    }

    return const ValidationResult.success();
  }

  // ========== VALIDAÇÕES DE DESAFIO ==========

  /// Validar configuração de votação do desafio
  static ValidationResult validateChallengeVotingConfig(Challenge challenge) {
    if (!challenge.hasVoting) {
      return const ValidationResult.failure(
        errorCode: 'voting_not_enabled',
        errorMessage: 'Este desafio não tem votação habilitada',
      );
    }

    final config = challenge.votingConfig!;

    // Validar períodos de tempo
    if (config.votingStartsAt != null && config.votingEndsAt != null) {
      if (config.votingStartsAt!.isAfter(config.votingEndsAt!)) {
        return const ValidationResult.failure(
          errorCode: 'invalid_voting_period',
          errorMessage: 'Período de votação inválido',
        );
      }

      final duration = config.votingEndsAt!.difference(config.votingStartsAt!);
      if (!VotingConstants.isValidVotingPeriod(
        config.votingStartsAt!,
        config.votingEndsAt!,
      )) {
        return ValidationResult.failure(
          errorCode: 'voting_period_out_of_range',
          errorMessage:
              'Período de votação deve ser entre ${VotingConstants.minVotingPeriod.inHours}h e ${VotingConstants.maxVotingPeriod.inDays}d',
        );
      }
    }

    // Validar tipos de voto permitidos
    if (!VotingConstants.isValidAllowedVoteTypes(config.allowedVoteTypes)) {
      return const ValidationResult.failure(
        errorCode: 'invalid_vote_types',
        errorMessage: 'Tipos de voto inválidos',
      );
    }

    // Validar configuração anti-manipulação
    if (!VotingConstants.isValidAntiManipulationConfig(
      config.antiManipulation,
    )) {
      return const ValidationResult.failure(
        errorCode: 'invalid_anti_manipulation_config',
        errorMessage: 'Configuração anti-manipulação inválida',
      );
    }

    return const ValidationResult.success();
  }

  /// Validar se desafio está em período de votação
  static ValidationResult validateVotingPeriod(Challenge challenge) {
    if (!challenge.hasVoting) {
      return const ValidationResult.failure(
        errorCode: 'voting_not_enabled',
        errorMessage: 'Votação não habilitada para este desafio',
      );
    }

    if (challenge.status != ChallengeStatus.voting) {
      if (challenge.status == ChallengeStatus.active) {
        return const ValidationResult.failure(
          errorCode: 'voting_not_started',
          errorMessage: 'Período de votação ainda não iniciou',
        );
      } else if (challenge.status == ChallengeStatus.completed) {
        return const ValidationResult.failure(
          errorCode: 'voting_ended',
          errorMessage: 'Período de votação já encerrou',
        );
      } else {
        return const ValidationResult.failure(
          errorCode: 'challenge_not_available',
          errorMessage: 'Desafio não disponível para votação',
        );
      }
    }

    final config = challenge.votingConfig!;
    if (!config.isVotingActive) {
      final now = DateTime.now();

      if (config.votingStartsAt != null &&
          now.isBefore(config.votingStartsAt!)) {
        return ValidationResult.failure(
          errorCode: 'voting_not_started',
          errorMessage:
              'Votação inicia em ${VotingConstants.formatTimeRemaining(config.votingStartsAt!.difference(now))}',
        );
      }

      if (config.votingEndsAt != null && now.isAfter(config.votingEndsAt!)) {
        return const ValidationResult.failure(
          errorCode: 'voting_ended',
          errorMessage: 'Período de votação encerrado',
        );
      }
    }

    return const ValidationResult.success();
  }

  // ========== VALIDAÇÕES DE SUBMISSÃO ==========

  /// Validar se submissão pode receber votos
  static ValidationResult validateSubmissionForVoting(
    Submission submission,
    Challenge challenge,
  ) {
    // Verificar se submissão pertence ao desafio
    if (submission.challengeId != challenge.id) {
      return const ValidationResult.failure(
        errorCode: 'submission_mismatch',
        errorMessage: 'Submissão não pertence a este desafio',
      );
    }

    // Verificar se submissão foi enviada no período correto
    if (submission.submittedAt.isAfter(challenge.effectiveSubmissionEnd)) {
      return const ValidationResult.failure(
        errorCode: 'late_submission',
        errorMessage: 'Submissão enviada fora do prazo',
      );
    }

    return const ValidationResult.success();
  }

  // ========== VALIDAÇÕES DE VOTO ==========

  /// Validar voto específico
  static ValidationResult validateVote({
    required UserModel user,
    required Submission submission,
    required Challenge challenge,
    required VoteType voteType,
    Vote? existingVote,
    int? currentUserVoteCount,
  }) {
    AppLogger.debug(
      '🔍 Validando voto: ${voteType.emoji} para submissão ${submission.id}',
    );

    // Validação básica do usuário
    final userValidation = validateUserCanVote(user);
    if (!userValidation.isValid) return userValidation;

    // Validação do desafio
    final challengeValidation = validateChallengeVotingConfig(challenge);
    if (!challengeValidation.isValid) return challengeValidation;

    // Validação do período de votação
    final periodValidation = validateVotingPeriod(challenge);
    if (!periodValidation.isValid) return periodValidation;

    // Validação da submissão
    final submissionValidation = validateSubmissionForVoting(
      submission,
      challenge,
    );
    if (!submissionValidation.isValid) return submissionValidation;

    final config = challenge.votingConfig!;

    // Verificar auto-voto
    if (submission.userId == user.uid && !config.allowSelfVoting) {
      return const ValidationResult.failure(
        errorCode: 'self_voting_not_allowed',
        errorMessage: 'Não é possível votar na própria submissão',
      );
    }

    // Verificar tipo de voto permitido
    if (!config.allowedVoteTypes.contains(voteType)) {
      return ValidationResult.failure(
        errorCode: 'vote_type_not_allowed',
        errorMessage:
            'Tipo de voto ${voteType.label} não permitido neste desafio',
      );
    }

    // Verificar limite de votos por usuário
    if (currentUserVoteCount != null) {
      final wouldExceedLimit = existingVote == null
          ? currentUserVoteCount >= config.maxVotesPerUser
          : false; // Se existe voto, está apenas mudando

      if (wouldExceedLimit) {
        return ValidationResult.failure(
          errorCode: 'max_votes_reached',
          errorMessage: 'Limite de ${config.maxVotesPerUser} votos atingido',
        );
      }
    }

    // Verificar se pode alterar voto existente
    if (existingVote != null && !config.allowMultipleVotes) {
      return const ValidationResult.failure(
        errorCode: 'vote_change_not_allowed',
        errorMessage: 'Não é possível alterar voto neste desafio',
      );
    }

    return ValidationResult.success(
      metadata: {
        'isNewVote': existingVote == null,
        'isVoteChange': existingVote != null && existingVote.type != voteType,
        'previousVoteType': existingVote?.type.id,
      },
    );
  }

  // ========== VALIDAÇÕES DE CRIAÇÃO ==========

  /// Validar criação de desafio com votação
  static ValidationResult validateChallengeCreation({
    required String title,
    required String description,
    required ChallengeType type,
    required DateTime startsAt,
    required DateTime submissionEndsAt,
    required DateTime votingEndsAt,
    required VotingConfig votingConfig,
    required UserModel creator,
  }) {
    // Validação básica do usuário criador
    final userValidation = validateUserCanVote(creator);
    if (!userValidation.isValid) return userValidation;

    // Validar campos obrigatórios
    if (title.trim().isEmpty) {
      return const ValidationResult.failure(
        errorCode: 'title_required',
        errorMessage: 'Título é obrigatório',
      );
    }

    if (title.length > 100) {
      return const ValidationResult.failure(
        errorCode: 'title_too_long',
        errorMessage: 'Título deve ter no máximo 100 caracteres',
      );
    }

    if (description.trim().isEmpty) {
      return const ValidationResult.failure(
        errorCode: 'description_required',
        errorMessage: 'Descrição é obrigatória',
      );
    }

    if (description.length > 1000) {
      return const ValidationResult.failure(
        errorCode: 'description_too_long',
        errorMessage: 'Descrição deve ter no máximo 1000 caracteres',
      );
    }

    // Validar tipo de desafio
    if (!type.supportsVoting) {
      return ValidationResult.failure(
        errorCode: 'type_not_supports_voting',
        errorMessage: 'Tipo ${type.label} não suporta votação',
      );
    }

    // Validar cronograma
    final now = DateTime.now();

    if (startsAt.isBefore(now)) {
      return const ValidationResult.failure(
        errorCode: 'start_time_past',
        errorMessage: 'Data de início deve ser no futuro',
      );
    }

    if (submissionEndsAt.isBefore(startsAt)) {
      return const ValidationResult.failure(
        errorCode: 'submission_end_before_start',
        errorMessage: 'Fim das submissões deve ser após o início',
      );
    }

    if (votingEndsAt.isBefore(submissionEndsAt)) {
      return const ValidationResult.failure(
        errorCode: 'voting_end_before_submission_end',
        errorMessage: 'Fim da votação deve ser após fim das submissões',
      );
    }

    // Verificar buffer mínimo entre submissões e votação
    final bufferTime = votingEndsAt.difference(submissionEndsAt);
    if (bufferTime < VotingConstants.minBufferTime) {
      return ValidationResult.failure(
        errorCode: 'insufficient_buffer_time',
        errorMessage:
            'Deve haver pelo menos ${VotingConstants.minBufferTime.inMinutes} minutos entre fim das submissões e início da votação',
      );
    }

    // Validar duração total do desafio
    final totalDuration = votingEndsAt.difference(startsAt);
    if (totalDuration > const Duration(days: 60)) {
      return const ValidationResult.failure(
        errorCode: 'challenge_too_long',
        errorMessage: 'Desafio não pode durar mais de 60 dias',
      );
    }

    // Validar configuração de votação
    final votingValidation = _validateVotingConfigForCreation(votingConfig);
    if (!votingValidation.isValid) return votingValidation;

    return const ValidationResult.success();
  }

  /// Validar configuração de votação para criação
  static ValidationResult _validateVotingConfigForCreation(
    VotingConfig config,
  ) {
    if (!config.isVotingEnabled) {
      return const ValidationResult.failure(
        errorCode: 'voting_disabled',
        errorMessage: 'Votação deve estar habilitada',
      );
    }

    if (config.maxVotesPerUser < VotingConstants.minVotesPerUser ||
        config.maxVotesPerUser > VotingConstants.maxVotesPerUser) {
      return ValidationResult.failure(
        errorCode: 'invalid_max_votes',
        errorMessage:
            'Limite de votos deve estar entre ${VotingConstants.minVotesPerUser} e ${VotingConstants.maxVotesPerUser}',
      );
    }

    if (!VotingConstants.isValidAllowedVoteTypes(config.allowedVoteTypes)) {
      return const ValidationResult.failure(
        errorCode: 'invalid_vote_types',
        errorMessage: 'Pelo menos um tipo de voto deve ser permitido',
      );
    }

    return const ValidationResult.success();
  }

  // ========== VALIDAÇÕES DE BUSINESS RULES ==========

  /// Validar regras de negócio para finalização de votação
  static ValidationResult validateVotingFinalization(
    Challenge challenge,
    List<Submission> submissions,
    Map<String, int> voteCounts,
  ) {
    if (challenge.status != ChallengeStatus.voting) {
      return const ValidationResult.failure(
        errorCode: 'not_in_voting_phase',
        errorMessage: 'Desafio não está em fase de votação',
      );
    }

    if (submissions.length < VotingConstants.minParticipantsForVoting) {
      return ValidationResult.failure(
        errorCode: 'insufficient_participants',
        errorMessage:
            'Mínimo de ${VotingConstants.minParticipantsForVoting} participantes necessário',
      );
    }

    final totalVotes = voteCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    if (totalVotes == 0) {
      return const ValidationResult.failure(
        errorCode: 'no_votes_cast',
        errorMessage: 'Nenhum voto foi registrado',
      );
    }

    // Verificar se há empate total (todos com mesmo score)
    final submissionScores = submissions.map((s) => s.score).toSet();
    if (submissionScores.length == 1 && submissions.length > 1) {
      AppLogger.warning('⚠️ Empate total detectado na votação');
      return ValidationResult.success(
        metadata: {'hasTotalTie': true, 'tiedScore': submissionScores.first},
      );
    }

    return ValidationResult.success(
      metadata: {
        'totalVotes': totalVotes,
        'totalSubmissions': submissions.length,
        'uniqueScores': submissionScores.length,
      },
    );
  }

  // ========== VALIDAÇÕES DE SEGURANÇA ==========

  /// Validar tentativa de voto para detectar padrões suspeitos
  static ValidationResult validateVotingSecurity({
    required UserModel user,
    required String submissionId,
    required List<Vote> recentVotes,
    String? ipAddress,
    String? deviceId,
  }) {
    final now = DateTime.now();
    final last5Minutes = now.subtract(const Duration(minutes: 5));

    // Verificar votos muito rápidos do mesmo usuário
    final recentUserVotes = recentVotes
        .where(
          (vote) =>
              vote.voterId == user.uid && vote.createdAt.isAfter(last5Minutes),
        )
        .length;

    if (recentUserVotes > 10) {
      return const ValidationResult.failure(
        errorCode: 'too_many_votes_user',
        errorMessage: 'Muitos votos em pouco tempo',
      );
    }

    // Verificar padrão de votação no mesmo horário
    if (ipAddress != null) {
      final recentIPVotes = recentVotes
          .where(
            (vote) =>
                vote.ipAddress == ipAddress &&
                vote.createdAt.isAfter(last5Minutes),
          )
          .length;

      if (recentIPVotes > 20) {
        return const ValidationResult.failure(
          errorCode: 'too_many_votes_ip',
          errorMessage: 'Muitos votos do mesmo IP',
        );
      }
    }

    // Verificar device
    if (deviceId != null) {
      final recentDeviceVotes = recentVotes
          .where(
            (vote) =>
                vote.deviceId == deviceId &&
                vote.createdAt.isAfter(last5Minutes),
          )
          .length;

      if (recentDeviceVotes > 15) {
        return const ValidationResult.failure(
          errorCode: 'too_many_votes_device',
          errorMessage: 'Muitos votos do mesmo dispositivo',
        );
      }
    }

    return const ValidationResult.success();
  }

  // ========== UTILITÁRIOS ==========

  /// Obter mensagem de erro amigável
  static String getFriendlyErrorMessage(String errorCode) {
    return VotingConstants.errorMessages[errorCode] ??
        VotingConstants.errorMessages['unknownError']!;
  }

  /// Obter configuração recomendada para tipo de desafio
  static VotingConfig getRecommendedConfig(
    ChallengeType type,
    int expectedParticipants,
  ) {
    final baseConfig = VotingConstants.getDefaultConfigForChallengeType(
      type.id,
    );

    // Ajustar configurações baseado no número de participantes
    final adjustedMaxVotes = expectedParticipants <= 20
        ? baseConfig.maxVotesPerUser
        : (baseConfig.maxVotesPerUser * 0.8).round();

    return VotingConfig(
      isVotingEnabled: baseConfig.isVotingEnabled,
      votingStartsAt: baseConfig.votingStartsAt,
      votingEndsAt: baseConfig.votingEndsAt,
      allowMultipleVotes: baseConfig.allowMultipleVotes,
      allowSelfVoting: baseConfig.allowSelfVoting,
      maxVotesPerUser: adjustedMaxVotes,
      allowedVoteTypes: baseConfig.allowedVoteTypes,
      antiManipulation: expectedParticipants > 50
          ? baseConfig.antiManipulation
          : {}, // Relaxar anti-manipulação para grupos pequenos
    );
  }
}
