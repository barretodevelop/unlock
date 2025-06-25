// lib/features/voting/constants/voting_constants.dart
import 'package:unlock/models/vote_model.dart';

/// Constantes para o sistema de votação
class VotingConstants {
  VotingConstants._();

  // ========== LIMITES E CONFIGURAÇÕES ==========

  /// Limite mínimo de votos por usuário
  static const int minVotesPerUser = 1;

  /// Limite máximo de votos por usuário
  static const int maxVotesPerUser = 1000;

  /// Limite padrão de votos por usuário
  static const int defaultVotesPerUser = 100;

  /// Número mínimo de participantes para votação ser válida
  static const int minParticipantsForVoting = 2;

  /// Número máximo de submissões exibidas no ranking
  static const int maxRankingDisplay = 50;

  /// Limite de votos por IP (anti-manipulação)
  static const int defaultMaxVotesPerIP = 5;

  /// Limite de votos por dispositivo (anti-manipulação)
  static const int defaultMaxVotesPerDevice = 3;

  // ========== PERÍODOS DE TEMPO ==========

  /// Duração mínima do período de votação
  static const Duration minVotingPeriod = Duration(hours: 1);

  /// Duração máxima do período de votação
  static const Duration maxVotingPeriod = Duration(days: 30);

  /// Duração padrão do período de votação
  static const Duration defaultVotingPeriod = Duration(days: 2);

  /// Tempo mínimo entre fim das submissões e início da votação
  static const Duration minBufferTime = Duration(minutes: 30);

  /// Intervalo para notificações de urgência (votação terminando)
  static const Duration urgentNotificationThreshold = Duration(hours: 2);

  /// Intervalo para verificação automática de status
  static const Duration statusCheckInterval = Duration(minutes: 5);

  // ========== CONFIGURAÇÕES DE VOTAÇÃO ==========

  /// Configuração padrão para desafios criativos
  static VotingConfig get defaultCreativeConfig => const VotingConfig(
    isVotingEnabled: true,
    allowMultipleVotes: true,
    allowSelfVoting: false,
    maxVotesPerUser: defaultVotesPerUser,
    allowedVoteTypes: VoteType.values,
    antiManipulation: {
      'checkIP': true,
      'maxVotesPerIP': defaultMaxVotesPerIP,
      'checkDevice': true,
      'maxVotesPerDevice': defaultMaxVotesPerDevice,
    },
  );

  /// Configuração para desafios de conhecimento
  static VotingConfig get knowledgeConfig => const VotingConfig(
    isVotingEnabled: true,
    allowMultipleVotes: true,
    allowSelfVoting: false,
    maxVotesPerUser: 50,
    allowedVoteTypes: [VoteType.like, VoteType.love, VoteType.wow],
    antiManipulation: {
      'checkIP': true,
      'maxVotesPerIP': 3,
      'checkDevice': true,
      'maxVotesPerDevice': 2,
    },
  );

  /// Configuração para desafios do mundo real
  static VotingConfig get realWorldConfig => const VotingConfig(
    isVotingEnabled: true,
    allowMultipleVotes: true,
    allowSelfVoting: true, // Permitido para atividades físicas
    maxVotesPerUser: 200,
    allowedVoteTypes: [
      VoteType.like,
      VoteType.love,
      VoteType.wow,
      VoteType.laugh,
    ],
    antiManipulation: {
      'checkIP': false, // Menos rigoroso para atividades físicas
      'checkDevice': true,
      'maxVotesPerDevice': 5,
    },
  );

  // ========== MENSAGENS E TEXTOS ==========

  /// Mensagens de erro padrão
  static const Map<String, String> errorMessages = {
    'votingClosed': 'O período de votação já encerrou',
    'votingNotStarted': 'A votação ainda não começou',
    'maxVotesReached': 'Você atingiu o limite de votos',
    'selfVotingNotAllowed': 'Não é possível votar na própria submissão',
    'submissionNotFound': 'Submissão não encontrada',
    'challengeNotFound': 'Desafio não encontrado',
    'userNotAuthenticated': 'Usuário não autenticado',
    'antiSpamTriggered': 'Muitos votos detectados, tente novamente mais tarde',
    'networkError': 'Erro de rede, tente novamente',
    'unknownError': 'Erro inesperado, tente novamente',
  };

  /// Mensagens de sucesso padrão
  static const Map<String, String> successMessages = {
    'voteRegistered': 'Voto registrado com sucesso!',
    'voteUpdated': 'Voto atualizado!',
    'voteRemoved': 'Voto removido',
    'challengeCreated': 'Desafio criado com sistema de votação!',
    'votingStarted': 'Período de votação iniciado!',
    'votingEnded': 'Votação encerrada, resultados disponíveis!',
  };

  // ========== CONFIGURAÇÕES DE UI ==========

  /// Cores para tipos de voto
  static const Map<VoteType, int> voteTypeColors = {
    VoteType.like: 0xFF2196F3, // Azul
    VoteType.love: 0xFFE91E63, // Rosa/Vermelho
    VoteType.wow: 0xFFFF9800, // Laranja
    VoteType.laugh: 0xFF4CAF50, // Verde
    VoteType.angry: 0xFF757575, // Cinza
  };

  /// Animações e durações
  static const Duration voteButtonAnimationDuration = Duration(
    milliseconds: 200,
  );
  static const Duration rankingUpdateAnimationDuration = Duration(
    milliseconds: 500,
  );
  static const Duration notificationDuration = Duration(seconds: 3);

  /// Tamanhos de fonte para diferentes contextos
  static const double voteEmojiSize = 24.0;
  static const double compactVoteEmojiSize = 20.0;
  static const double voteCountFontSize = 12.0;

  // ========== CONFIGURAÇÕES DE PERFORMANCE ==========

  /// Número máximo de votos carregados por vez
  static const int maxVotesPerPage = 100;

  /// Intervalo de debounce para atualizações de ranking
  static const Duration rankingUpdateDebounce = Duration(milliseconds: 500);

  /// Tempo de cache para estatísticas
  static const Duration statisticsCacheDuration = Duration(minutes: 5);

  // ========== REGRAS DE NEGÓCIO ==========

  /// Verificar se tipo de desafio suporta votação
  static bool challengeTypeSupportsVoting(String challengeTypeId) {
    switch (challengeTypeId) {
      case 'creative':
      case 'knowledge':
      case 'real_world':
        return true;
      case 'performance':
        return false; // Mini-games têm score automático
      default:
        return false;
    }
  }

  /// Obter configuração padrão por tipo de desafio
  static VotingConfig getDefaultConfigForChallengeType(String challengeTypeId) {
    switch (challengeTypeId) {
      case 'creative':
        return defaultCreativeConfig;
      case 'knowledge':
        return knowledgeConfig;
      case 'real_world':
        return realWorldConfig;
      default:
        return defaultCreativeConfig;
    }
  }

  /// Validar período de votação
  static bool isValidVotingPeriod(DateTime start, DateTime end) {
    final duration = end.difference(start);
    return duration >= minVotingPeriod && duration <= maxVotingPeriod;
  }

  /// Calcular duração recomendada de votação baseada no número de participantes
  static Duration getRecommendedVotingDuration(int participantCount) {
    if (participantCount <= 10) {
      return const Duration(days: 1);
    } else if (participantCount <= 50) {
      return const Duration(days: 2);
    } else if (participantCount <= 100) {
      return const Duration(days: 3);
    } else {
      return const Duration(days: 5);
    }
  }

  /// Verificar se é período urgente para votação
  static bool isUrgentVotingPeriod(DateTime votingEnd) {
    final timeRemaining = votingEnd.difference(DateTime.now());
    return timeRemaining <= urgentNotificationThreshold &&
        timeRemaining.isNegative == false;
  }

  // ========== VALIDAÇÕES ==========

  /// Validar configuração de anti-manipulação
  static bool isValidAntiManipulationConfig(Map<String, dynamic> config) {
    if (config.isEmpty) return true;

    final maxVotesPerIP = config['maxVotesPerIP'] as int?;
    final maxVotesPerDevice = config['maxVotesPerDevice'] as int?;

    if (maxVotesPerIP != null && (maxVotesPerIP < 1 || maxVotesPerIP > 100)) {
      return false;
    }

    if (maxVotesPerDevice != null &&
        (maxVotesPerDevice < 1 || maxVotesPerDevice > 50)) {
      return false;
    }

    return true;
  }

  /// Validar lista de tipos de voto permitidos
  static bool isValidAllowedVoteTypes(List<VoteType> allowedTypes) {
    return allowedTypes.isNotEmpty &&
        allowedTypes.length <= VoteType.values.length;
  }

  /// Calcular score total de uma submissão baseado nos votos
  static double calculateSubmissionScore(Map<VoteType, int> voteCounts) {
    double totalScore = 0.0;

    for (final entry in voteCounts.entries) {
      final voteType = entry.key;
      final count = entry.value;
      totalScore += (voteType.weight * count);
    }

    return totalScore;
  }

  // ========== FORMATAÇÃO ==========

  /// Formatar número de votos para exibição
  static String formatVoteCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// Formatar score para exibição
  static String formatScore(double score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toStringAsFixed(1);
  }

  /// Formatar tempo restante para votação
  static String formatTimeRemaining(Duration timeRemaining) {
    if (timeRemaining.isNegative) {
      return 'Encerrado';
    }

    if (timeRemaining.inDays > 0) {
      return '${timeRemaining.inDays}d ${timeRemaining.inHours % 24}h';
    } else if (timeRemaining.inHours > 0) {
      return '${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m';
    } else if (timeRemaining.inMinutes > 0) {
      return '${timeRemaining.inMinutes}m';
    } else {
      return '${timeRemaining.inSeconds}s';
    }
  }

  // ========== CONFIGURAÇÕES DE NOTIFICAÇÃO ==========

  /// Configurações para diferentes tipos de notificação
  static const Map<String, Map<String, dynamic>> notificationConfig = {
    'votingStarted': {
      'title': '🗳️ Votação Iniciada!',
      'priority': 'high',
      'sound': true,
    },
    'votingEnding': {
      'title': '⏰ Votação Terminando!',
      'priority': 'urgent',
      'sound': true,
    },
    'votingEnded': {
      'title': '🏁 Votação Encerrada!',
      'priority': 'medium',
      'sound': false,
    },
    'newVoteReceived': {
      'title': '👍 Novo Voto!',
      'priority': 'low',
      'sound': false,
    },
  };
}

/// Configurações específicas por ambiente
class VotingEnvironmentConfig {
  VotingEnvironmentConfig._();

  /// Configurações para desenvolvimento
  static const Map<String, dynamic> development = {
    'enableDebugLogging': true,
    'mockVotingDelay': 1000, // ms
    'enableTestVotes': true,
    'statusCheckInterval': 60000, // 1 minuto para dev
    'enableVotingSimulation': true,
  };

  /// Configurações para produção
  static const Map<String, dynamic> production = {
    'enableDebugLogging': false,
    'mockVotingDelay': 0,
    'enableTestVotes': false,
    'statusCheckInterval': 300000, // 5 minutos para produção
    'enableVotingSimulation': false,
  };

  /// Configurações para testes
  static const Map<String, dynamic> testing = {
    'enableDebugLogging': true,
    'mockVotingDelay': 100,
    'enableTestVotes': true,
    'statusCheckInterval': 10000, // 10 segundos para testes
    'enableVotingSimulation': true,
    'fastTimeProgression': true,
  };
}

/// Métricas e analytics para votação
class VotingMetrics {
  VotingMetrics._();

  /// Eventos para tracking
  static const Map<String, String> analyticsEvents = {
    'vote_cast': 'vote_cast',
    'vote_changed': 'vote_changed',
    'vote_removed': 'vote_removed',
    'voting_started': 'voting_started',
    'voting_ended': 'voting_ended',
    'challenge_created_with_voting': 'challenge_created_with_voting',
    'ranking_viewed': 'ranking_viewed',
    'submission_viewed_for_voting': 'submission_viewed_for_voting',
  };

  /// Propriedades padrão para eventos
  static Map<String, dynamic> getDefaultEventProperties({
    String? challengeId,
    String? submissionId,
    String? voteType,
    String? userId,
  }) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'challenge_id': challengeId,
      'submission_id': submissionId,
      'vote_type': voteType,
      'user_id': userId,
      'platform': 'flutter',
      'version': '1.0.0',
    };
  }
}
