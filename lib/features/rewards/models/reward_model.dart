// lib/features/rewards/models/reward_model.dart
// Modelo de dados para recompensas - Fase 3

import 'package:flutter/foundation.dart';

/// Tipos de recompensa disponíveis
enum RewardType {
  xp('xp', 'XP', '⚡'),
  coins('coins', 'Coins', '🪙'),
  gems('gems', 'Gems', '💎'),
  achievement('achievement', 'Conquista', '🏆'),
  item('item', 'Item', '🎁'),
  title('title', 'Título', '🏅'),
  boost('boost', 'Boost', '🚀');

  const RewardType(this.value, this.displayName, this.icon);
  final String value;
  final String displayName;
  final String icon;

  static RewardType fromString(String value) {
    return RewardType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RewardType.xp,
    );
  }
}

/// Fonte da recompensa
enum RewardSource {
  mission('mission', 'Missão'),
  levelUp('level_up', 'Subida de Nível'),
  dailyLogin('daily_login', 'Login Diário'),
  achievement('achievement', 'Conquista'),
  minigame('minigame', 'Minijogo'),
  connection('connection', 'Conexão'),
  purchase('purchase', 'Compra'),
  bonus('bonus', 'Bônus'),
  event('event', 'Evento');

  const RewardSource(this.value, this.displayName);
  final String value;
  final String displayName;

  static RewardSource fromString(String value) {
    return RewardSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => RewardSource.mission,
    );
  }
}

/// Modelo de recompensa
@immutable
class RewardModel {
  final String id;
  final RewardType type;
  final RewardSource source;
  final int amount;
  final String? itemId; // Para recompensas de item
  final String? achievementId; // Para conquistas
  final String? titleId; // Para títulos
  final String description;
  final DateTime createdAt;
  final bool isClaimed;
  final DateTime? claimedAt;
  final Map<String, dynamic> metadata;

  const RewardModel({
    required this.id,
    required this.type,
    required this.source,
    required this.amount,
    this.itemId,
    this.achievementId,
    this.titleId,
    required this.description,
    required this.createdAt,
    this.isClaimed = false,
    this.claimedAt,
    this.metadata = const {},
  });

  /// Criar recompensa a partir de JSON/Firestore
  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] ?? '',
      type: RewardType.fromString(json['type'] ?? 'xp'),
      source: RewardSource.fromString(json['source'] ?? 'mission'),
      amount: json['amount'] ?? 0,
      itemId: json['itemId'],
      achievementId: json['achievementId'],
      titleId: json['titleId'],
      description: json['description'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isClaimed: json['isClaimed'] ?? false,
      claimedAt: json['claimedAt'] != null
          ? DateTime.tryParse(json['claimedAt'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Converter para JSON/Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'source': source.value,
      'amount': amount,
      'itemId': itemId,
      'achievementId': achievementId,
      'titleId': titleId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isClaimed': isClaimed,
      'claimedAt': claimedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Criar cópia com modificações
  RewardModel copyWith({
    String? id,
    RewardType? type,
    RewardSource? source,
    int? amount,
    String? itemId,
    String? achievementId,
    String? titleId,
    String? description,
    DateTime? createdAt,
    bool? isClaimed,
    DateTime? claimedAt,
    Map<String, dynamic>? metadata,
  }) {
    return RewardModel(
      id: id ?? this.id,
      type: type ?? this.type,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      itemId: itemId ?? this.itemId,
      achievementId: achievementId ?? this.achievementId,
      titleId: titleId ?? this.titleId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isClaimed: isClaimed ?? this.isClaimed,
      claimedAt: claimedAt ?? this.claimedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // ================================================================================================
  // GETTERS CONVENIENTES
  // ================================================================================================

  /// Ícone da recompensa
  String get icon => type.icon;

  /// Nome amigável da recompensa
  String get displayName => type.displayName;

  /// Texto formatado da quantidade
  String get formattedAmount {
    switch (type) {
      case RewardType.xp:
        return '+$amount XP';
      case RewardType.coins:
        return '+$amount 🪙';
      case RewardType.gems:
        return '+$amount 💎';
      case RewardType.achievement:
        return 'Nova conquista!';
      case RewardType.item:
        return 'Novo item!';
      case RewardType.title:
        return 'Novo título!';
      case RewardType.boost:
        return '${amount}x Boost';
    }
  }

  /// Cor da recompensa
  int get color {
    switch (type) {
      case RewardType.xp:
        return 0xFF2196F3; // Azul
      case RewardType.coins:
        return 0xFFFFD700; // Dourado
      case RewardType.gems:
        return 0xFF9C27B0; // Roxo
      case RewardType.achievement:
        return 0xFFFF9800; // Laranja
      case RewardType.item:
        return 0xFF4CAF50; // Verde
      case RewardType.title:
        return 0xFFE91E63; // Rosa
      case RewardType.boost:
        return 0xFFFF5722; // Vermelho-laranja
    }
  }

  /// Verificar se pode ser coletada
  bool get canBeClaimed => !isClaimed;

  /// Tempo desde criação
  Duration get timeSinceCreated => DateTime.now().difference(createdAt);

  /// Marcar como coletada
  RewardModel claim() {
    return copyWith(isClaimed: true, claimedAt: DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RewardModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RewardModel(id: $id, type: ${type.value}, amount: $amount, claimed: $isClaimed)';
  }

  // ================================================================================================
  // FACTORY CONSTRUCTORS CONVENIENTES
  // ================================================================================================

  /// Criar recompensa de XP
  factory RewardModel.xp({
    required String id,
    required int amount,
    required RewardSource source,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return RewardModel(
      id: id,
      type: RewardType.xp,
      source: source,
      amount: amount,
      description: description ?? '+$amount XP',
      createdAt: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Criar recompensa de coins
  factory RewardModel.coins({
    required String id,
    required int amount,
    required RewardSource source,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return RewardModel(
      id: id,
      type: RewardType.coins,
      source: source,
      amount: amount,
      description: description ?? '+$amount Coins',
      createdAt: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Criar recompensa de gems
  factory RewardModel.gems({
    required String id,
    required int amount,
    required RewardSource source,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return RewardModel(
      id: id,
      type: RewardType.gems,
      source: source,
      amount: amount,
      description: description ?? '+$amount Gems',
      createdAt: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Criar recompensa de conquista
  factory RewardModel.achievement({
    required String id,
    required String achievementId,
    required RewardSource source,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return RewardModel(
      id: id,
      type: RewardType.achievement,
      source: source,
      amount: 1,
      achievementId: achievementId,
      description: description ?? 'Nova conquista desbloqueada!',
      createdAt: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Criar recompensa de item
  factory RewardModel.item({
    required String id,
    required String itemId,
    required RewardSource source,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return RewardModel(
      id: id,
      type: RewardType.item,
      source: source,
      amount: 1,
      itemId: itemId,
      description: description ?? 'Novo item desbloqueado!',
      createdAt: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Criar recompensa de título
  factory RewardModel.title({
    required String id,
    required String titleId,
    required RewardSource source,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return RewardModel(
      id: id,
      type: RewardType.title,
      source: source,
      amount: 1,
      titleId: titleId,
      description: description ?? 'Novo título desbloqueado!',
      createdAt: DateTime.now(),
      metadata: metadata ?? {},
    );
  }
}

/// Coleção de recompensas (para quando múltiplas recompensas são dadas juntas)
@immutable
class RewardBundle {
  final String id;
  final String title;
  final String description;
  final List<RewardModel> rewards;
  final RewardSource source;
  final DateTime createdAt;
  final bool isClaimed;
  final DateTime? claimedAt;

  const RewardBundle({
    required this.id,
    required this.title,
    required this.description,
    required this.rewards,
    required this.source,
    required this.createdAt,
    this.isClaimed = false,
    this.claimedAt,
  });

  /// Calcular XP total do bundle
  int get totalXP => rewards
      .where((r) => r.type == RewardType.xp)
      .fold(0, (sum, r) => sum + r.amount);

  /// Calcular coins total do bundle
  int get totalCoins => rewards
      .where((r) => r.type == RewardType.coins)
      .fold(0, (sum, r) => sum + r.amount);

  /// Calcular gems total do bundle
  int get totalGems => rewards
      .where((r) => r.type == RewardType.gems)
      .fold(0, (sum, r) => sum + r.amount);

  /// Verificar se pode ser coletado
  bool get canBeClaimed => !isClaimed && rewards.isNotEmpty;

  /// Marcar bundle como coletado
  RewardBundle claim() {
    return RewardBundle(
      id: id,
      title: title,
      description: description,
      rewards: rewards.map((r) => r.claim()).toList(),
      source: source,
      createdAt: createdAt,
      isClaimed: true,
      claimedAt: DateTime.now(),
    );
  }

  /// Resumo textual das recompensas
  String get rewardsSummary {
    final parts = <String>[];

    if (totalXP > 0) parts.add('+$totalXP XP');
    if (totalCoins > 0) parts.add('+$totalCoins 🪙');
    if (totalGems > 0) parts.add('+$totalGems 💎');

    final achievements = rewards.where((r) => r.type == RewardType.achievement);
    if (achievements.isNotEmpty) {
      parts.add(
        '${achievements.length} conquista${achievements.length > 1 ? 's' : ''}',
      );
    }

    final items = rewards.where((r) => r.type == RewardType.item);
    if (items.isNotEmpty) {
      parts.add('${items.length} item${items.length > 1 ? 's' : ''}');
    }

    return parts.join(', ');
  }

  @override
  String toString() {
    return 'RewardBundle(id: $id, rewards: ${rewards.length}, claimed: $isClaimed)';
  }
}
