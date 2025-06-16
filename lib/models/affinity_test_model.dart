// lib/models/affinity_test_model.dart
import 'package:equatable/equatable.dart';
import 'package:unlock/enums/enums.dart';
import 'package:unlock/models/affinity_question.dart';

class AffinityTestModel extends Equatable {
  final String id;
  final String matchId;
  final TestType type;
  final String question;
  final List<String> options;
  final String? userAnswer;
  final String? targetExpectedAnswer;
  final int scoreEarned;
  final int maxScore;
  final bool hasPassed;
  final DateTime? completedAt;
  final Duration timeSpent;

  const AffinityTestModel({
    required this.id,
    required this.matchId,
    required this.type,
    required this.question,
    required this.options,
    this.userAnswer,
    this.targetExpectedAnswer,
    this.scoreEarned = 0,
    this.maxScore = 100,
    this.hasPassed = false,
    this.completedAt,
    this.timeSpent = Duration.zero,
    required List<AffinityQuestion> questions,
    required DateTime createdAt,
    required Duration timeLimit,
  });

  double get successPercentage =>
      maxScore > 0 ? (scoreEarned / maxScore) * 100 : 0;

  @override
  List<Object?> get props => [
    id,
    matchId,
    type,
    question,
    options,
    userAnswer,
    targetExpectedAnswer,
    scoreEarned,
    maxScore,
    hasPassed,
    completedAt,
    timeSpent,
  ];

  AffinityTestModel copyWith({
    String? id,
    String? matchId,
    TestType? type,
    String? question,
    List<String>? options,
    String? userAnswer,
    String? targetExpectedAnswer,
    int? scoreEarned,
    int? maxScore,
    bool? hasPassed,
    DateTime? completedAt,
    Duration? timeSpent,
  }) {
    return AffinityTestModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      type: type ?? this.type,
      question: question ?? this.question,
      options: options ?? this.options,
      userAnswer: userAnswer ?? this.userAnswer,
      targetExpectedAnswer: targetExpectedAnswer ?? this.targetExpectedAnswer,
      scoreEarned: scoreEarned ?? this.scoreEarned,
      maxScore: maxScore ?? this.maxScore,
      hasPassed: hasPassed ?? this.hasPassed,
      completedAt: completedAt ?? this.completedAt,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }
}
