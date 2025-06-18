// lib/features/missions/models/mission_model.dart
// Modelo de dados para missões - Fase 3

import 'package:flutter/foundation.dart';

/// Tipos de missão disponíveis
enum MissionType {
  daily('daily', 'Diária'),
  weekly('weekly', 'Semanal'),
  collaborative('collaborative', 'Colaborativa'),
  automatic('automatic', 'Automática'),
  special('special', 'Especial');

  const MissionType(this.value, this.displayName);
  final String value;
  final String displayName;

  static MissionType fromString(String value) {
    return MissionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MissionType.daily,
    );
  }
}

/// Categorias de missão
enum MissionCategory {
  social('social', 'Social', '👥'),
  profile('profile', 'Perfil', '👤'),
  exploration('exploration', 'Exploração', '🔍'),
  gamification('gamification', 'Gamificação', '🎮');

  const MissionCategory(this.value, this.displayName, this.icon);
  final String value;
  final String displayName;
  final String icon;

  static MissionCategory fromString(String value) {
    return MissionCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => MissionCategory.social,
    );
  }
}

/// Status da missão
enum MissionStatus {
  available('available', 'Disponível'),
  active('active', 'Ativa'),
  completed('completed', 'Completa'),
  expired('expired', 'Expirada'),
  locked('locked', 'Bloqueada');

  const MissionStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static MissionStatus fromString(String value) {
    return MissionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MissionStatus.available,
    );
  }
}

/// Modelo de missão
@immutable
class MissionModel {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final MissionCategory category;
  final int xpReward;
  final int coinsReward;
  final int gemsReward;
  final int targetValue;
  final int difficulty; // 1-5
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> requirements;
  final bool isActive;
  final int? participantsRequired; // Para missões colaborativas
  final Map<String, dynamic> metadata;

  const MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.xpReward,
    required this.coinsReward,
    this.gemsReward = 0,
    required this.targetValue,
    this.difficulty = 1,
    required this.createdAt,
    required this.expiresAt,
    this.requirements = const [],
    this.isActive = true,
    this.participantsRequired,
    this.metadata = const {},
  });

  /// Criar missão a partir de JSON/Firestore
  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: MissionType.fromString(json['type'] ?? 'daily'),
      category: MissionCategory.fromString(json['category'] ?? 'social'),
      xpReward: json['xpReward'] ?? 0,
      coinsReward: json['coinsReward'] ?? 0,
      gemsReward: json['gemsReward'] ?? 0,
      targetValue: json['targetValue'] ?? 1,
      difficulty: json['difficulty'] ?? 1,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt'] ?? '') ?? DateTime.now(),
      requirements: List<String>.from(json['requirements'] ?? []),
      isActive: json['isActive'] ?? true,
      participantsRequired: json['participantsRequired'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Converter para JSON/Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'category': category.value,
      'xpReward': xpReward,
      'coinsReward': coinsReward,
      'gemsReward': gemsReward,
      'targetValue': targetValue,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'requirements': requirements,
      'isActive': isActive,
      'participantsRequired': participantsRequired,
      'metadata': metadata,
    };
  }

  /// Criar cópia com modificações
  MissionModel copyWith({
    String? id,
    String? title,
    String? description,
    MissionType? type,
    MissionCategory? category,
    int? xpReward,
    int? coinsReward,
    int? gemsReward,
    int? targetValue,
    int? difficulty,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? requirements,
    bool? isActive,
    int? participantsRequired,
    Map<String, dynamic>? metadata,
  }) {
    return MissionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      coinsReward: coinsReward ?? this.coinsReward,
      gemsReward: gemsReward ?? this.gemsReward,
      targetValue: targetValue ?? this.targetValue,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      requirements: requirements ?? this.requirements,
      isActive: isActive ?? this.isActive,
      participantsRequired: participantsRequired ?? this.participantsRequired,
      metadata: metadata ?? this.metadata,
    );
  }

  // ================================================================================================
  // GETTERS CONVENIENTES
  // ================================================================================================

  /// Verificar se a missão expirou
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Verificar se a missão é colaborativa
  bool get isCollaborative => type == MissionType.collaborative;

  /// Verificar se a missão tem recompensa de gems
  bool get hasGemsReward => gemsReward > 0;

  /// Obter tempo restante em horas
  int get hoursRemaining {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inHours;
  }

  /// Obter ícone da categoria
  String get categoryIcon => category.icon;

  /// Obter cor da dificuldade (hex)
  int get difficultyColor {
    const colors = {
      1: 0xFF4CAF50, // Verde
      2: 0xFF2196F3, // Azul
      3: 0xFFFF9800, // Laranja
      4: 0xFFE91E63, // Rosa
      5: 0xFF9C27B0, // Roxo
    };
    return colors[difficulty] ?? 0xFF757575;
  }

  /// Obter texto da dificuldade
  String get difficultyText {
    const texts = {
      1: 'Fácil',
      2: 'Normal',
      3: 'Médio',
      4: 'Difícil',
      5: 'Expert',
    };
    return texts[difficulty] ?? 'Normal';
  }

  /// Verificar se o usuário atende os requisitos
  bool meetsRequirements(Map<String, bool> userRequirements) {
    for (String requirement in requirements) {
      if (userRequirements[requirement] != true) {
        return false;
      }
    }
    return true;
  }

  /// Calcular recompensa total em "pontos"
  int get totalRewardPoints => xpReward + (coinsReward * 2) + (gemsReward * 20);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MissionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MissionModel(id: $id, title: $title, type: ${type.value}, difficulty: $difficulty)';
  }
}

/// Modelo de progresso da missão do usuário
@immutable
class UserMissionProgress {
  final String missionId;
  final String userId;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime startedAt;
  final Map<String, dynamic> metadata;

  const UserMissionProgress({
    required this.missionId,
    required this.userId,
    this.currentProgress = 0,
    required this.targetProgress,
    this.isCompleted = false,
    this.completedAt,
    required this.startedAt,
    this.metadata = const {},
  });

  /// Criar a partir de JSON/Firestore
  factory UserMissionProgress.fromJson(Map<String, dynamic> json) {
    return UserMissionProgress(
      missionId: json['missionId'] ?? '',
      userId: json['userId'] ?? '',
      currentProgress: json['currentProgress'] ?? 0,
      targetProgress: json['targetProgress'] ?? 1,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      startedAt: DateTime.tryParse(json['startedAt'] ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Converter para JSON/Firestore
  Map<String, dynamic> toJson() {
    return {
      'missionId': missionId,
      'userId': userId,
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'startedAt': startedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Criar cópia com modificações
  UserMissionProgress copyWith({
    String? missionId,
    String? userId,
    int? currentProgress,
    int? targetProgress,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? startedAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserMissionProgress(
      missionId: missionId ?? this.missionId,
      userId: userId ?? this.userId,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      startedAt: startedAt ?? this.startedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // ================================================================================================
  // GETTERS CONVENIENTES
  // ================================================================================================

  /// Progresso em percentual (0.0 - 1.0)
  double get progressPercentage {
    if (targetProgress <= 0) return 0.0;
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

  /// Progresso em percentual formatado (0-100%)
  String get progressPercentageFormatted {
    return '${(progressPercentage * 100).round()}%';
  }

  /// Verificar se está próximo da conclusão (>= 80%)
  bool get isNearCompletion => progressPercentage >= 0.8;

  /// Progresso restante
  int get remainingProgress {
    return (targetProgress - currentProgress).clamp(0, targetProgress);
  }

  /// Atualizar progresso
  UserMissionProgress updateProgress(int additionalProgress) {
    final newProgress = currentProgress + additionalProgress;
    final completed = newProgress >= targetProgress;

    return copyWith(
      currentProgress: newProgress,
      isCompleted: completed,
      completedAt: completed ? DateTime.now() : null,
    );
  }

  /// Completar missão
  UserMissionProgress complete() {
    return copyWith(
      currentProgress: targetProgress,
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserMissionProgress &&
        other.missionId == missionId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(missionId, userId);

  @override
  String toString() {
    return 'UserMissionProgress(missionId: $missionId, progress: $currentProgress/$targetProgress, completed: $isCompleted)';
  }
}
