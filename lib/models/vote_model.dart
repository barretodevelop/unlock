// lib/models/vote_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de voto disponíveis
enum VoteType {
  like('like', '👍', 'Curtir'),
  love('love', '❤️', 'Amar'),
  wow('wow', '😮', 'Uau'),
  laugh('laugh', '😂', 'Rir'),
  angry('angry', '😠', 'Raiva');

  const VoteType(this.id, this.emoji, this.label);
  final String id;
  final String emoji;
  final String label;

  /// Peso do voto para cálculo de score
  int get weight {
    switch (this) {
      case VoteType.like:
        return 1;
      case VoteType.love:
        return 3;
      case VoteType.wow:
        return 2;
      case VoteType.laugh:
        return 2;
      case VoteType.angry:
        return -1;
    }
  }
}

/// Modelo de voto individual
class Vote {
  final String id;
  final String submissionId;
  final String challengeId;
  final String voterId;
  final String voterUsername;
  final VoteType type;
  final DateTime createdAt;
  final String? ipAddress; // Para anti-manipulação
  final String? deviceId; // Para anti-manipulação
  final Map<String, dynamic> metadata;

  const Vote({
    required this.id,
    required this.submissionId,
    required this.challengeId,
    required this.voterId,
    required this.voterUsername,
    required this.type,
    required this.createdAt,
    this.ipAddress,
    this.deviceId,
    this.metadata = const {},
  });

  /// Criar a partir de JSON/Firestore
  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'] ?? '',
      submissionId: json['submissionId'] ?? '',
      challengeId: json['challengeId'] ?? '',
      voterId: json['voterId'] ?? '',
      voterUsername: json['voterUsername'] ?? '',
      type: VoteType.values.firstWhere(
        (t) => t.id == json['type'],
        orElse: () => VoteType.like,
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: json['ipAddress'],
      deviceId: json['deviceId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Converter para JSON/Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submissionId': submissionId,
      'challengeId': challengeId,
      'voterId': voterId,
      'voterUsername': voterUsername,
      'type': type.id,
      'createdAt': Timestamp.fromDate(createdAt),
      'ipAddress': ipAddress,
      'deviceId': deviceId,
      'metadata': metadata,
    };
  }

  Vote copyWith({VoteType? type, Map<String, dynamic>? metadata}) {
    return Vote(
      id: id,
      submissionId: submissionId,
      challengeId: challengeId,
      voterId: voterId,
      voterUsername: voterUsername,
      type: type ?? this.type,
      createdAt: createdAt,
      ipAddress: ipAddress,
      deviceId: deviceId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vote &&
        other.id == id &&
        other.submissionId == submissionId &&
        other.voterId == voterId;
  }

  @override
  int get hashCode => Object.hash(id, submissionId, voterId);
}

/// Estatísticas de votação de uma submissão
class VotingStats {
  final String submissionId;
  final Map<VoteType, int> voteCounts;
  final int totalVotes;
  final double score; // Score ponderado baseado nos pesos
  final int ranking; // Posição no ranking de votos
  final DateTime lastVote;
  final bool isLeading; // Se está em primeiro lugar

  const VotingStats({
    required this.submissionId,
    required this.voteCounts,
    required this.totalVotes,
    required this.score,
    required this.ranking,
    required this.lastVote,
    required this.isLeading,
  });

  /// Criar a partir de lista de votos
  factory VotingStats.fromVotes(String submissionId, List<Vote> votes) {
    final Map<VoteType, int> counts = {};
    double totalScore = 0;

    // Inicializar contadores
    for (final type in VoteType.values) {
      counts[type] = 0;
    }

    // Contar votos e calcular score
    for (final vote in votes) {
      counts[vote.type] = (counts[vote.type] ?? 0) + 1;
      totalScore += vote.type.weight;
    }

    return VotingStats(
      submissionId: submissionId,
      voteCounts: counts,
      totalVotes: votes.length,
      score: totalScore,
      ranking: 0, // Será calculado externamente
      lastVote: votes.isNotEmpty
          ? votes.map((v) => v.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
          : DateTime.now(),
      isLeading: false, // Será calculado externamente
    );
  }

  /// Obter percentual de um tipo de voto
  double getVotePercentage(VoteType type) {
    if (totalVotes == 0) return 0.0;
    return (voteCounts[type] ?? 0) / totalVotes * 100;
  }

  /// Obter tipo de voto mais popular
  VoteType? get mostPopularVote {
    if (totalVotes == 0) return null;

    VoteType? maxType;
    int maxCount = 0;

    voteCounts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        maxType = type;
      }
    });

    return maxType;
  }

  VotingStats copyWith({int? ranking, bool? isLeading}) {
    return VotingStats(
      submissionId: submissionId,
      voteCounts: voteCounts,
      totalVotes: totalVotes,
      score: score,
      ranking: ranking ?? this.ranking,
      lastVote: lastVote,
      isLeading: isLeading ?? this.isLeading,
    );
  }
}

/// Configurações de votação para um desafio
class VotingConfig {
  final bool isVotingEnabled;
  final DateTime? votingStartsAt;
  final DateTime? votingEndsAt;
  final bool allowMultipleVotes; // Pode mudar o voto
  final bool allowSelfVoting; // Pode votar na própria submissão
  final int maxVotesPerUser; // Limite de votos por usuário
  final List<VoteType> allowedVoteTypes;
  final Map<String, dynamic> antiManipulation; // Configurações anti-spam

  const VotingConfig({
    this.isVotingEnabled = true,
    this.votingStartsAt,
    this.votingEndsAt,
    this.allowMultipleVotes = true,
    this.allowSelfVoting = false,
    this.maxVotesPerUser = 100,
    this.allowedVoteTypes = VoteType.values,
    this.antiManipulation = const {},
  });

  /// Verificar se votação está ativa
  bool get isVotingActive {
    if (!isVotingEnabled) return false;

    final now = DateTime.now();

    if (votingStartsAt != null && now.isBefore(votingStartsAt!)) {
      return false;
    }

    if (votingEndsAt != null && now.isAfter(votingEndsAt!)) {
      return false;
    }

    return true;
  }

  /// Tempo restante para votação
  Duration? get timeUntilVotingEnds {
    if (votingEndsAt == null) return null;
    final remaining = votingEndsAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Criar a partir de JSON
  factory VotingConfig.fromJson(Map<String, dynamic> json) {
    return VotingConfig(
      isVotingEnabled: json['isVotingEnabled'] ?? true,
      votingStartsAt: (json['votingStartsAt'] as Timestamp?)?.toDate(),
      votingEndsAt: (json['votingEndsAt'] as Timestamp?)?.toDate(),
      allowMultipleVotes: json['allowMultipleVotes'] ?? true,
      allowSelfVoting: json['allowSelfVoting'] ?? false,
      maxVotesPerUser: json['maxVotesPerUser'] ?? 100,
      allowedVoteTypes:
          (json['allowedVoteTypes'] as List<dynamic>?)
              ?.map(
                (type) => VoteType.values.firstWhere(
                  (t) => t.id == type,
                  orElse: () => VoteType.like,
                ),
              )
              .toList() ??
          VoteType.values,
      antiManipulation: Map<String, dynamic>.from(
        json['antiManipulation'] ?? {},
      ),
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'isVotingEnabled': isVotingEnabled,
      'votingStartsAt': votingStartsAt != null
          ? Timestamp.fromDate(votingStartsAt!)
          : null,
      'votingEndsAt': votingEndsAt != null
          ? Timestamp.fromDate(votingEndsAt!)
          : null,
      'allowMultipleVotes': allowMultipleVotes,
      'allowSelfVoting': allowSelfVoting,
      'maxVotesPerUser': maxVotesPerUser,
      'allowedVoteTypes': allowedVoteTypes.map((t) => t.id).toList(),
      'antiManipulation': antiManipulation,
    };
  }
}
