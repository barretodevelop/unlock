// lib/models/submission_model.dart - ATUALIZADO COM SISTEMA DE VOTAÇÃO
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/models/vote_model.dart';

enum SubmissionType { image, video, text, score, data }

/// Modelo de submissão - ATUALIZADO COM VOTAÇÃO
class Submission {
  final String id;
  final String challengeId;
  final String userId;
  final String username;
  final String userAvatar;
  final SubmissionType type;
  final Map<String, dynamic> content;
  final DateTime submittedAt;

  // ========== CAMPOS DE VOTAÇÃO - NOVOS ==========
  final int votes; // Total de votos
  final double score; // Score ponderado baseado nos tipos de voto
  final Map<String, int> voteCounts; // Contagem por tipo de voto
  final DateTime? lastVote; // Último voto recebido
  final int ranking; // Posição no ranking de votos
  final bool isLeading; // Se está em primeiro lugar

  // ========== CAMPOS EXISTENTES ==========
  final bool isWinner;
  final Map<String, dynamic> metadata;

  const Submission({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.type,
    required this.content,
    required this.submittedAt,

    // ✅ NOVOS CAMPOS DE VOTAÇÃO
    this.votes = 0,
    this.score = 0.0,
    this.voteCounts = const {},
    this.lastVote,
    this.ranking = 0,
    this.isLeading = false,

    // Campos existentes
    this.isWinner = false,
    this.metadata = const {},
  });

  /// ✅ NOVOS GETTERS PARA VOTAÇÃO

  /// Verificar se tem votos
  bool get hasVotes => votes > 0;

  /// Obter percentual de um tipo de voto
  double getVotePercentage(VoteType voteType) {
    if (votes == 0) return 0.0;
    final count = voteCounts[voteType.id] ?? 0;
    return (count / votes) * 100;
  }

  /// Obter tipo de voto mais popular
  VoteType? get mostPopularVote {
    if (votes == 0) return null;

    String? maxVoteTypeId;
    int maxCount = 0;

    voteCounts.forEach((typeId, count) {
      if (count > maxCount) {
        maxCount = count;
        maxVoteTypeId = typeId;
      }
    });

    if (maxVoteTypeId == null) return null;

    return VoteType.values.firstWhere(
      (type) => type.id == maxVoteTypeId,
      orElse: () => VoteType.like,
    );
  }

  /// Converter contagem de votos para estatísticas
  VotingStats get votingStats {
    final Map<VoteType, int> typeCountMap = {};

    // Inicializar contadores
    for (final type in VoteType.values) {
      typeCountMap[type] = 0;
    }

    // Preencher com dados atuais
    voteCounts.forEach((typeId, count) {
      final type = VoteType.values.firstWhere(
        (t) => t.id == typeId,
        orElse: () => VoteType.like,
      );
      typeCountMap[type] = count;
    });

    return VotingStats(
      submissionId: id,
      voteCounts: typeCountMap,
      totalVotes: votes,
      score: score,
      ranking: ranking,
      lastVote: lastVote ?? submittedAt,
      isLeading: isLeading,
    );
  }

  /// Factory para criar a partir de JSON/Firestore - ATUALIZADO
  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] ?? '',
      challengeId: json['challengeId'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userAvatar: json['userAvatar'] ?? '👤',
      type: SubmissionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SubmissionType.text,
      ),
      content: Map<String, dynamic>.from(json['content'] ?? {}),
      submittedAt:
          (json['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      // ✅ NOVOS CAMPOS DE VOTAÇÃO
      votes: json['votes'] ?? 0,
      score: (json['score'] ?? 0.0).toDouble(),
      voteCounts: Map<String, int>.from(json['voteCounts'] ?? {}),
      lastVote: (json['lastVote'] as Timestamp?)?.toDate(),
      ranking: json['ranking'] ?? 0,
      isLeading: json['isLeading'] ?? false,

      // Campos existentes
      isWinner: json['isWinner'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Converter para JSON/Firestore - ATUALIZADO
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'type': type.name,
      'content': content,
      'submittedAt': Timestamp.fromDate(submittedAt),

      // ✅ NOVOS CAMPOS DE VOTAÇÃO
      'votes': votes,
      'score': score,
      'voteCounts': voteCounts,
      'lastVote': lastVote != null ? Timestamp.fromDate(lastVote!) : null,
      'ranking': ranking,
      'isLeading': isLeading,

      // Campos existentes
      'isWinner': isWinner,
      'metadata': metadata,
    };
  }

  /// Método copyWith - ATUALIZADO
  Submission copyWith({
    String? username,
    String? userAvatar,
    Map<String, dynamic>? content,

    // ✅ NOVOS PARÂMETROS DE VOTAÇÃO
    int? votes,
    double? score,
    Map<String, int>? voteCounts,
    DateTime? lastVote,
    int? ranking,
    bool? isLeading,

    // Parâmetros existentes
    bool? isWinner,
    Map<String, dynamic>? metadata,
  }) {
    return Submission(
      id: id,
      challengeId: challengeId,
      userId: userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      type: type,
      content: content ?? this.content,
      submittedAt: submittedAt,

      // ✅ NOVOS CAMPOS DE VOTAÇÃO
      votes: votes ?? this.votes,
      score: score ?? this.score,
      voteCounts: voteCounts ?? this.voteCounts,
      lastVote: lastVote ?? this.lastVote,
      ranking: ranking ?? this.ranking,
      isLeading: isLeading ?? this.isLeading,

      // Campos existentes
      isWinner: isWinner ?? this.isWinner,
      metadata: metadata ?? this.metadata,
    );
  }

  /// ✅ NOVO: Atualizar com estatísticas de votação
  Submission updateWithVotingStats(VotingStats stats) {
    return copyWith(
      votes: stats.totalVotes,
      score: stats.score,
      voteCounts: stats.voteCounts.map((k, v) => MapEntry(k.id, v)),
      lastVote: stats.lastVote,
      ranking: stats.ranking,
      isLeading: stats.isLeading,
    );
  }

  /// ✅ NOVO: Factory para criar submissão inicial (sem votos)
  factory Submission.create({
    required String challengeId,
    required String userId,
    required String username,
    required String userAvatar,
    required SubmissionType type,
    required Map<String, dynamic> content,
    Map<String, dynamic>? metadata,
  }) {
    return Submission(
      id: '', // Será preenchido pelo Firestore
      challengeId: challengeId,
      userId: userId,
      username: username,
      userAvatar: userAvatar,
      type: type,
      content: content,
      submittedAt: DateTime.now(),

      // Inicializar campos de votação zerados
      votes: 0,
      score: 0.0,
      voteCounts: {},
      lastVote: null,
      ranking: 0,
      isLeading: false,

      isWinner: false,
      metadata: metadata ?? {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Submission &&
        other.id == id &&
        other.challengeId == challengeId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(id, challengeId, userId);

  @override
  String toString() {
    return 'Submission(id: $id, challengeId: $challengeId, userId: $userId, votes: $votes, score: $score)';
  }
}
