// lib/models/unlock_match_model.dart
import 'package:equatable/equatable.dart';
import 'package:unlock/enums/enums.dart';
import 'package:unlock/models/affinity_test_model.dart';
import 'package:unlock/models/unlock_requirement.dart';

class UnlockMatchModel extends Equatable {
  final String id;
  final String userId;
  final String targetUserId;
  final String targetCodinome;
  final String? targetAvatarUrl;
  final List<String> commonInterests;
  final double compatibilityScore;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime? unlockedAt;
  final DateTime? expiresAt;
  final List<AffinityTestModel> completedTests;
  final int totalTestsRequired;
  final bool canStartChat;

  const UnlockMatchModel({
    required this.id,
    required this.userId,
    required this.targetUserId,
    required this.targetCodinome,
    this.targetAvatarUrl,
    required this.commonInterests,
    required this.compatibilityScore,
    this.status = MatchStatus.pending,
    required this.createdAt,
    this.unlockedAt,
    this.expiresAt,
    this.completedTests = const [],
    this.totalTestsRequired = 3,
    this.canStartChat = false,
    required String currentUserId,
    required String targetUserCodinome,
    required bool isUnlocked,
    required UnlockRequirement unlockRequirement,
  });

  // Getters para lógica de unlock
  bool get isUnlocked => status == MatchStatus.unlocked;
  bool get canTakeTests =>
      status == MatchStatus.testing || status == MatchStatus.pending;
  double get testProgress => completedTests.length / totalTestsRequired;
  bool get hasPassedAllTests =>
      completedTests.length >= totalTestsRequired &&
      completedTests.every((test) => test.hasPassed);

  @override
  List<Object?> get props => [
    id,
    userId,
    targetUserId,
    targetCodinome,
    targetAvatarUrl,
    commonInterests,
    compatibilityScore,
    status,
    createdAt,
    unlockedAt,
    expiresAt,
    completedTests,
    totalTestsRequired,
    canStartChat,
  ];

  UnlockMatchModel copyWith({
    String? id,
    String? userId,
    String? targetUserId,
    String? targetCodinome,
    String? targetAvatarUrl,
    List<String>? commonInterests,
    double? compatibilityScore,
    MatchStatus? status,
    DateTime? createdAt,
    DateTime? unlockedAt,
    DateTime? expiresAt,
    List<AffinityTestModel>? completedTests,
    int? totalTestsRequired,
    bool? canStartChat,
  }) {
    return UnlockMatchModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetUserId: targetUserId ?? this.targetUserId,
      targetCodinome: targetCodinome ?? this.targetCodinome,
      targetAvatarUrl: targetAvatarUrl ?? this.targetAvatarUrl,
      commonInterests: commonInterests ?? this.commonInterests,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedTests: completedTests ?? this.completedTests,
      totalTestsRequired: totalTestsRequired ?? this.totalTestsRequired,
      canStartChat: canStartChat ?? this.canStartChat,
      currentUserId: '',
      targetUserCodinome: '',
      isUnlocked: null,
      unlockRequirement: null,
    );
  }
}
