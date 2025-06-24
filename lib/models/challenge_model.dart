// lib/models/challenge_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType {
  creative('creative', '🎨', 'Criativo'),
  performance('performance', '🎮', 'Performance'),
  knowledge('knowledge', '🧠', 'Conhecimento'),
  realWorld('real_world', '🏃', 'Mundo Real');

  const ChallengeType(this.id, this.icon, this.label);
  final String id;
  final String icon;
  final String label;
}

enum ArenaType {
  duel('duel', '⚔️', '1v1'),
  group('group', '👥', 'Grupo'),
  tournament('tournament', '🏆', 'Torneio');

  const ArenaType(this.id, this.icon, this.label);
  final String id;
  final String icon;
  final String label;
}

enum ChallengeStatus { draft, active, voting, completed, cancelled }

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ArenaType arena;
  final String creatorId;
  final DateTime createdAt;
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime? votingEndsAt;
  final ChallengeStatus status;
  final List<String> participants;
  final Map<String, dynamic> rules;
  final int maxParticipants;
  final int entryFee;
  final Map<String, int> rewards;
  final List<String> tags;
  final String? groupId;
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

  bool get isActive =>
      status == ChallengeStatus.active &&
      DateTime.now().isAfter(startsAt) &&
      DateTime.now().isBefore(endsAt);

  bool get canJoin => isActive && participants.length < maxParticipants;

  bool get isVoting => status == ChallengeStatus.voting;

  Duration get timeLeft => endsAt.difference(DateTime.now());

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
        (s) => s.name == json['status'],
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
      'status': status.name,
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
}
