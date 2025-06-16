// lib/models/unlock_requirement.dart
import 'package:equatable/equatable.dart';

enum RequirementType {
  minCompatibility,
  commonInterests,
  affinityTestScore,
  userLevel,
  premiumFeature,
  timeRestriction,
  mutualConnection,
  verifiedProfile,
  ageRange,
  locationProximity,
}

enum RequirementStatus { pending, met, failed, checking }

class UnlockRequirement extends Equatable {
  final String id;
  final RequirementType type;
  final String title;
  final String description;
  final dynamic requiredValue;
  final dynamic currentValue;
  final RequirementStatus status;
  final bool isOptional;
  final int priority;
  final String? iconEmoji;
  final Map<String, dynamic>? metadata;

  const UnlockRequirement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.requiredValue,
    this.currentValue,
    this.status = RequirementStatus.pending,
    this.isOptional = false,
    this.priority = 0,
    this.iconEmoji,
    this.metadata,
  });

  bool get isMet => status == RequirementStatus.met;
  bool get isFailed => status == RequirementStatus.failed;
  bool get isPending => status == RequirementStatus.pending;
  bool get isChecking => status == RequirementStatus.checking;

  double get progressPercentage {
    if (currentValue == null || requiredValue == null) return 0.0;

    try {
      if (requiredValue is num && currentValue is num) {
        return ((currentValue as num) / (requiredValue as num)).clamp(0.0, 1.0);
      }
      return isMet ? 1.0 : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  String get statusText {
    switch (status) {
      case RequirementStatus.met:
        return '✅ Requisito atendido';
      case RequirementStatus.failed:
        return '❌ Requisito não atendido';
      case RequirementStatus.checking:
        return '🔍 Verificando...';
      case RequirementStatus.pending:
        return '⏳ Pendente';
    }
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    description,
    requiredValue,
    currentValue,
    status,
    isOptional,
    priority,
    iconEmoji,
    metadata,
  ];

  UnlockRequirement copyWith({
    String? id,
    RequirementType? type,
    String? title,
    String? description,
    dynamic requiredValue,
    dynamic currentValue,
    RequirementStatus? status,
    bool? isOptional,
    int? priority,
    String? iconEmoji,
    Map<String, dynamic>? metadata,
  }) {
    return UnlockRequirement(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredValue: requiredValue ?? this.requiredValue,
      currentValue: currentValue ?? this.currentValue,
      status: status ?? this.status,
      isOptional: isOptional ?? this.isOptional,
      priority: priority ?? this.priority,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'requiredValue': requiredValue,
      'currentValue': currentValue,
      'status': status.name,
      'isOptional': isOptional,
      'priority': priority,
      'iconEmoji': iconEmoji,
      'metadata': metadata,
    };
  }

  factory UnlockRequirement.fromJson(Map<String, dynamic> json) {
    return UnlockRequirement(
      id: json['id'] ?? '',
      type: RequirementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RequirementType.minCompatibility,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requiredValue: json['requiredValue'],
      currentValue: json['currentValue'],
      status: RequirementStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RequirementStatus.pending,
      ),
      isOptional: json['isOptional'] ?? false,
      priority: json['priority'] ?? 0,
      iconEmoji: json['iconEmoji'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  // Factory methods para tipos comuns de requisitos
  factory UnlockRequirement.minCompatibility({
    required double requiredScore,
    double? currentScore,
  }) {
    return UnlockRequirement(
      id: 'min_compatibility',
      type: RequirementType.minCompatibility,
      title: 'Compatibilidade Mínima',
      description: 'Alcance ${requiredScore.toInt()}% de compatibilidade',
      requiredValue: requiredScore,
      currentValue: currentScore,
      iconEmoji: '💝',
      priority: 1,
    );
  }

  factory UnlockRequirement.commonInterests({
    required int requiredCount,
    int? currentCount,
  }) {
    return UnlockRequirement(
      id: 'common_interests',
      type: RequirementType.commonInterests,
      title: 'Interesses em Comum',
      description: 'Tenham pelo menos $requiredCount interesses em comum',
      requiredValue: requiredCount,
      currentValue: currentCount,
      iconEmoji: '🎯',
      priority: 2,
    );
  }

  factory UnlockRequirement.affinityTestScore({
    required double requiredScore,
    double? currentScore,
  }) {
    return UnlockRequirement(
      id: 'affinity_test',
      type: RequirementType.affinityTestScore,
      title: 'Teste de Afinidade',
      description: 'Alcance ${requiredScore.toInt()}% no teste de afinidade',
      requiredValue: requiredScore,
      currentValue: currentScore,
      iconEmoji: '🧠',
      priority: 1,
    );
  }

  factory UnlockRequirement.userLevel({
    required int requiredLevel,
    int? currentLevel,
  }) {
    return UnlockRequirement(
      id: 'user_level',
      type: RequirementType.userLevel,
      title: 'Nível do Usuário',
      description: 'Alcance o nível $requiredLevel',
      requiredValue: requiredLevel,
      currentValue: currentLevel,
      iconEmoji: '⭐',
      priority: 3,
    );
  }

  factory UnlockRequirement.verifiedProfile() {
    return const UnlockRequirement(
      id: 'verified_profile',
      type: RequirementType.verifiedProfile,
      title: 'Perfil Verificado',
      description: 'Tenha um perfil verificado',
      requiredValue: true,
      iconEmoji: '✅',
      priority: 2,
    );
  }

  factory UnlockRequirement.ageRange({
    required int minAge,
    required int maxAge,
    int? currentAge,
  }) {
    return UnlockRequirement(
      id: 'age_range',
      type: RequirementType.ageRange,
      title: 'Faixa Etária',
      description: 'Idade entre $minAge e $maxAge anos',
      requiredValue: {'min': minAge, 'max': maxAge},
      currentValue: currentAge,
      iconEmoji: '🎂',
      priority: 2,
    );
  }

  factory UnlockRequirement.locationProximity({
    required double maxDistanceKm,
    double? currentDistanceKm,
  }) {
    return UnlockRequirement(
      id: 'location_proximity',
      type: RequirementType.locationProximity,
      title: 'Proximidade',
      description: 'Esteja a menos de ${maxDistanceKm}km de distância',
      requiredValue: maxDistanceKm,
      currentValue: currentDistanceKm,
      iconEmoji: '📍',
      priority: 3,
      isOptional: true,
    );
  }
}
