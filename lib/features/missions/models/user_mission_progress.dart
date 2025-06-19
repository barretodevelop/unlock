// lib/features/missions/models/user_mission_progress.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Assuming Firestore for persistence
import 'package:flutter/foundation.dart'; // For @immutable

/// Representa o progresso de um usuário em uma missão específica.
/// Este modelo é imutável.
@immutable
class UserMissionProgress {
  final String userId;
  final String missionId;
  final int currentProgress;
  final bool isCompleted;
  final bool isClaimed;
  final DateTime? lastUpdateDate;

  const UserMissionProgress({
    required this.userId,
    required this.missionId,
    this.currentProgress = 0,
    this.isCompleted = false,
    this.isClaimed = false,
    this.lastUpdateDate,
  });

  /// Creates a new instance of UserMissionProgress with updated fields.
  UserMissionProgress copyWith({
    String? userId,
    String? missionId,
    int? currentProgress,
    bool? isCompleted,
    bool? isClaimed,
    DateTime? lastUpdateDate,
  }) {
    return UserMissionProgress(
      userId: userId ?? this.userId,
      missionId: missionId ?? this.missionId,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
    );
  }

  /// Creates a UserMissionProgress instance from a JSON map (e.g., from Firestore).
  factory UserMissionProgress.fromJson(Map<String, dynamic> json) {
    return UserMissionProgress(
      userId: json['userId'] as String? ?? '',
      missionId: json['missionId'] as String? ?? '',
      currentProgress: json['currentProgress'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
      lastUpdateDate: (json['lastUpdateDate'] is Timestamp)
          ? (json['lastUpdateDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts this instance to a JSON map (e.g., for Firestore).
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'missionId': missionId,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      'isClaimed': isClaimed,
      'lastUpdateDate': lastUpdateDate != null
          ? Timestamp.fromDate(lastUpdateDate!)
          : null,
    };
  }

  @override
  String toString() {
    return 'UserMissionProgress(userId: $userId, missionId: $missionId, currentProgress: $currentProgress, isCompleted: $isCompleted, isClaimed: $isClaimed, lastUpdateDate: $lastUpdateDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserMissionProgress &&
        other.userId == userId &&
        other.missionId == missionId &&
        other.currentProgress == currentProgress &&
        other.isCompleted == isCompleted &&
        other.isClaimed == isClaimed &&
        other.lastUpdateDate == lastUpdateDate;
  }

  @override
  int get hashCode => Object.hash(
    userId,
    missionId,
    currentProgress,
    isCompleted,
    isClaimed,
    lastUpdateDate,
  );
}
