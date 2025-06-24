// lib/models/submission_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SubmissionType { image, video, text, score, data }

class Submission {
  final String id;
  final String challengeId;
  final String userId;
  final String username;
  final String userAvatar;
  final SubmissionType type;
  final Map<String, dynamic> content;
  final DateTime submittedAt;
  final int votes;
  final double? score;
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
    this.votes = 0,
    this.score,
    this.isWinner = false,
    this.metadata = const {},
  });

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
      votes: json['votes'] ?? 0,
      score: json['score']?.toDouble(),
      isWinner: json['isWinner'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

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
      'votes': votes,
      'score': score,
      'isWinner': isWinner,
      'metadata': metadata,
    };
  }

  Submission copyWith({
    int? votes,
    double? score,
    bool? isWinner,
    Map<String, dynamic>? metadata,
  }) {
    return Submission(
      id: id,
      challengeId: challengeId,
      userId: userId,
      username: username,
      userAvatar: userAvatar,
      type: type,
      content: content,
      submittedAt: submittedAt,
      votes: votes ?? this.votes,
      score: score ?? this.score,
      isWinner: isWinner ?? this.isWinner,
      metadata: metadata ?? this.metadata,
    );
  }
}
