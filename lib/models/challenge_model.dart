// lib/models/challenge_model.dart - VERSÃO CORRIGIDA E ATUALIZADA
import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de desafio disponíveis no ClashUp
enum ChallengeType {
  creative('creative', '🎨', 'Criativo'),
  performance('performance', '🎮', 'Performance'),
  knowledge('knowledge', '🧠', 'Conhecimento'),
  realWorld('real_world', '🏃', 'Mundo Real');

  const ChallengeType(this.id, this.icon, this.label);
  final String id;
  final String icon;
  final String label;

  /// Descrição do tipo de desafio
  String get description {
    switch (this) {
      case ChallengeType.creative:
        return 'Fotos, vídeos, desenhos e outras criações artísticas';
      case ChallengeType.performance:
        return 'Mini-jogos e desafios de habilidade';
      case ChallengeType.knowledge:
        return 'Perguntas e respostas sobre diversos temas';
      case ChallengeType.realWorld:
        return 'Atividades físicas e do mundo real';
    }
  }
}

/// Tipos de arena para competição
enum ArenaType {
  duel('duel', '⚔️', '1v1'),
  group('group', '👥', 'Grupo'),
  tournament('tournament', '🏆', 'Torneio');

  const ArenaType(this.id, this.icon, this.label);
  final String id;
  final String icon;
  final String label;

  /// Descrição da arena
  String get description {
    switch (this) {
      case ArenaType.duel:
        return 'Desafie um amigo diretamente';
      case ArenaType.group:
        return 'Apenas para seu grupo de amigos';
      case ArenaType.tournament:
        return 'Aberto para todos na plataforma';
    }
  }
}

/// Status do desafio
enum ChallengeStatus {
  draft('draft', 'Rascunho'),
  active('active', 'Ativo'),
  voting('voting', 'Votação'),
  completed('completed', 'Concluído'),
  cancelled('cancelled', 'Cancelado');

  const ChallengeStatus(this.id, this.label);
  final String id;
  final String label;
}

/// Modelo principal do desafio
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ArenaType arena; // ✅ CORRIGIDO: Usar ArenaType
  final String creatorId;
  final DateTime createdAt;
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime? votingEndsAt;
  final ChallengeStatus status;
  final List<String> participants;
  final Map<String, dynamic> rules;
  final int maxParticipants;
  final int entryFee; // Custo em Faíscas para participar
  final Map<String, int> rewards; // Recompensas por posição
  final List<String> tags;
  final String? groupId; // Se for desafio de grupo específico
  final Map<String, dynamic> metadata;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.arena,
    required this.creatorId,
    required this.createdAt,
    required this.startsAt,
    required this.endsAt,
    this.votingEndsAt,
    required this.status,
    this.participants = const [],
    this.rules = const {},
    this.maxParticipants = 100,
    this.entryFee = 0,
    this.rewards = const {},
    this.tags = const [],
    this.groupId,
    this.metadata = const {},
  });

  /// Getters úteis
  bool get isActive =>
      status == ChallengeStatus.active &&
      DateTime.now().isAfter(startsAt) &&
      DateTime.now().isBefore(endsAt);

  bool get canJoin =>
      isActive && participants.length < maxParticipants && !hasEnded;

  bool get isVoting => status == ChallengeStatus.voting;

  bool get hasStarted => DateTime.now().isAfter(startsAt);

  bool get hasEnded => DateTime.now().isAfter(endsAt);

  Duration get timeLeft => endsAt.difference(DateTime.now());

  Duration get timeUntilStart => startsAt.difference(DateTime.now());

  bool get isGroupChallenge => groupId != null;

  bool get isPublicChallenge => groupId == null;

  /// Verificar se usuário pode participar
  bool canUserJoin(String userId) {
    return canJoin && !participants.contains(userId);
  }

  /// Verificar se usuário está participando
  bool isUserParticipating(String userId) {
    return participants.contains(userId);
  }

  /// Factory para criar desafio
  factory Challenge.create({
    required String title,
    required String description,
    required ChallengeType type,
    required ArenaType arena,
    required String creatorId,
    required DateTime startsAt,
    required DateTime endsAt,
    DateTime? votingEndsAt,
    int? maxParticipants,
    int? entryFee,
    Map<String, int>? rewards,
    List<String>? tags,
    String? groupId,
    Map<String, dynamic>? rules,
  }) {
    return Challenge(
      id: '', // Será preenchido pelo Firestore
      title: title,
      description: description,
      type: type,
      arena: arena,
      creatorId: creatorId,
      createdAt: DateTime.now(),
      startsAt: startsAt,
      endsAt: endsAt,
      votingEndsAt: votingEndsAt,
      status: ChallengeStatus.active,
      maxParticipants: maxParticipants ?? 100,
      entryFee: entryFee ?? 0,
      rewards: rewards ?? {},
      tags: tags ?? [],
      groupId: groupId,
      rules: rules ?? {},
    );
  }

  /// Criar a partir de JSON/Firestore
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: ChallengeType.values.firstWhere(
        (t) => t.id == json['type'],
        orElse: () => ChallengeType.creative,
      ),
      arena: ArenaType.values.firstWhere(
        (a) => a.id == json['arena'],
        orElse: () => ArenaType.tournament,
      ),
      creatorId: json['creatorId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startsAt: (json['startsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (json['endsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      votingEndsAt: (json['votingEndsAt'] as Timestamp?)?.toDate(),
      status: ChallengeStatus.values.firstWhere(
        (s) => s.id == json['status'],
        orElse: () => ChallengeStatus.draft,
      ),
      participants: List<String>.from(json['participants'] ?? []),
      rules: Map<String, dynamic>.from(json['rules'] ?? {}),
      maxParticipants: json['maxParticipants'] ?? 100,
      entryFee: json['entryFee'] ?? 0,
      rewards: Map<String, int>.from(json['rewards'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      groupId: json['groupId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Converter para JSON/Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.id,
      'arena': arena.id,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'startsAt': Timestamp.fromDate(startsAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'votingEndsAt': votingEndsAt != null
          ? Timestamp.fromDate(votingEndsAt!)
          : null,
      'status': status.id,
      'participants': participants,
      'rules': rules,
      'maxParticipants': maxParticipants,
      'entryFee': entryFee,
      'rewards': rewards,
      'tags': tags,
      'groupId': groupId,
      'metadata': metadata,
    };
  }

  /// Método copyWith para atualizações
  Challenge copyWith({
    String? title,
    String? description,
    ChallengeType? type,
    ArenaType? arena,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? votingEndsAt,
    ChallengeStatus? status,
    List<String>? participants,
    Map<String, dynamic>? rules,
    int? maxParticipants,
    int? entryFee,
    Map<String, int>? rewards,
    List<String>? tags,
    String? groupId,
    Map<String, dynamic>? metadata,
  }) {
    return Challenge(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      arena: arena ?? this.arena,
      creatorId: creatorId,
      createdAt: createdAt,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      votingEndsAt: votingEndsAt ?? this.votingEndsAt,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      rules: rules ?? this.rules,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      entryFee: entryFee ?? this.entryFee,
      rewards: rewards ?? this.rewards,
      tags: tags ?? this.tags,
      groupId: groupId ?? this.groupId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Challenge &&
        other.id == id &&
        other.title == title &&
        other.creatorId == creatorId &&
        other.type == type &&
        other.arena == arena;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, creatorId, type, arena);
  }

  @override
  String toString() {
    return 'Challenge(id: $id, title: $title, type: ${type.label}, arena: ${arena.label}, status: ${status.label})';
  }
}
