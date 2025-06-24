// lib/models/powerup_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para power-ups no sistema Unlock
class PowerUp {
  final String id;
  final PowerUpType type;
  final String name;
  final String description;
  final String emoji;
  final int coinsCost;
  final int? gemsCost;
  final int duration; // em segundos, 0 = instantâneo
  final int maxUses; // por jogo, -1 = ilimitado
  final bool isActive;
  final PowerUpRarity rarity;
  final List<String> gameModesAllowed;

  const PowerUp({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    required this.coinsCost,
    this.gemsCost,
    this.duration = 0,
    this.maxUses = 1,
    this.isActive = true,
    this.rarity = PowerUpRarity.common,
    this.gameModesAllowed = const [],
  });

  factory PowerUp.fromJson(Map<String, dynamic> json) {
    return PowerUp(
      id: json['id'] ?? '',
      type: PowerUpType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PowerUpType.extraHint,
      ),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      emoji: json['emoji'] ?? '⚡',
      coinsCost: json['coinsCost'] ?? 0,
      gemsCost: json['gemsCost'],
      duration: json['duration'] ?? 0,
      maxUses: json['maxUses'] ?? 1,
      isActive: json['isActive'] ?? true,
      rarity: PowerUpRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => PowerUpRarity.common,
      ),
      gameModesAllowed: List<String>.from(json['gameModesAllowed'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'description': description,
      'emoji': emoji,
      'coinsCost': coinsCost,
      'gemsCost': gemsCost,
      'duration': duration,
      'maxUses': maxUses,
      'isActive': isActive,
      'rarity': rarity.name,
      'gameModesAllowed': gameModesAllowed,
    };
  }

  PowerUp copyWith({
    String? id,
    PowerUpType? type,
    String? name,
    String? description,
    String? emoji,
    int? coinsCost,
    int? gemsCost,
    int? duration,
    int? maxUses,
    bool? isActive,
    PowerUpRarity? rarity,
    List<String>? gameModesAllowed,
  }) {
    return PowerUp(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      coinsCost: coinsCost ?? this.coinsCost,
      gemsCost: gemsCost ?? this.gemsCost,
      duration: duration ?? this.duration,
      maxUses: maxUses ?? this.maxUses,
      isActive: isActive ?? this.isActive,
      rarity: rarity ?? this.rarity,
      gameModesAllowed: gameModesAllowed ?? this.gameModesAllowed,
    );
  }

  /// Verifica se o power-up é premium (custa gemas)
  bool get isPremium => gemsCost != null && gemsCost! > 0;

  /// Verifica se o power-up tem duração limitada
  bool get isTemporary => duration > 0;

  /// Verifica se o power-up tem uso limitado
  bool get hasLimitedUses => maxUses > 0;
}

/// Power-up instanciado no inventário do usuário
class UserPowerUp {
  final String id;
  final String userId;
  final PowerUpType type;
  final int quantity;
  final DateTime acquiredAt;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const UserPowerUp({
    required this.id,
    required this.userId,
    required this.type,
    required this.quantity,
    required this.acquiredAt,
    this.expiresAt,
    this.isActive = true,
    this.metadata = const {},
  });

  factory UserPowerUp.fromJson(Map<String, dynamic> json) {
    return UserPowerUp(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: PowerUpType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PowerUpType.extraHint,
      ),
      quantity: json['quantity'] ?? 1,
      acquiredAt: (json['acquiredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate(),
      isActive: json['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'quantity': quantity,
      'acquiredAt': Timestamp.fromDate(acquiredAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  UserPowerUp copyWith({
    String? id,
    String? userId,
    PowerUpType? type,
    int? quantity,
    DateTime? acquiredAt,
    DateTime? expiresAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return UserPowerUp(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Verifica se o power-up está expirado
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Verifica se o power-up está disponível para uso
  bool get isAvailable => isActive && !isExpired && quantity > 0;
}

/// Power-up usado em um jogo específico
class GamePowerUpUsage {
  final String id;
  final String gameRoomId;
  final String userId;
  final PowerUpType type;
  final DateTime usedAt;
  final Map<String, dynamic> effect;
  final bool isActive;

  const GamePowerUpUsage({
    required this.id,
    required this.gameRoomId,
    required this.userId,
    required this.type,
    required this.usedAt,
    this.effect = const {},
    this.isActive = true,
  });

  factory GamePowerUpUsage.fromJson(Map<String, dynamic> json) {
    return GamePowerUpUsage(
      id: json['id'] ?? '',
      gameRoomId: json['gameRoomId'] ?? '',
      userId: json['userId'] ?? '',
      type: PowerUpType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PowerUpType.extraHint,
      ),
      usedAt: (json['usedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      effect: Map<String, dynamic>.from(json['effect'] ?? {}),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameRoomId': gameRoomId,
      'userId': userId,
      'type': type.name,
      'usedAt': Timestamp.fromDate(usedAt),
      'effect': effect,
      'isActive': isActive,
    };
  }
}

/// Tipos de power-ups disponíveis
enum PowerUpType {
  extraHint('Dica Extra', 'Revela uma dica adicional sobre a resposta correta', '💡'),
  superQuestion('Super Pergunta', 'Faz uma pergunta que revela 25% a mais', '🔥'),
  matchBooster('Match Booster', 'Dobra a pontuação de revelação por 3 perguntas', '⚡'),
  timeFreeze('Congelar Tempo', 'Para o tempo por 30 segundos (modo rápido)', '❄️'),
  skipQuestion('Pular Pergunta', 'Pula uma pergunta difícil sem perder pontos', '⏭️'),
  doubleChance('Segunda Chance', 'Permite uma segunda tentativa na pergunta', '🎯'),
  xrayVision('Visão Raio-X', 'Mostra metade das opções incorretas', '👁️'),
  luckyGuess('Palpite Sortudo', 'Resposta aleatória com 75% de chance de acerto', '🍀');

  const PowerUpType(this.displayName, this.description, this.emoji);
  final String displayName;
  final String description;
  final String emoji;
}

/// Raridade dos power-ups
enum PowerUpRarity {
  common('Comum', 1.0, 0xFF4CAF50),
  rare('Raro', 2.0, 0xFF2196F3),
  epic('Épico', 3.0, 0xFF9C27B0),
  legendary('Lendário', 5.0, 0xFFFF9800);

  const PowerUpRarity(this.displayName, this.multiplier, this.colorValue);
  final String displayName;
  final double multiplier;
  final int colorValue;

  /// Cor da raridade
  int get color => colorValue;
}

/// Estado do inventário de power-ups
class PowerUpInventoryState {
  final List<UserPowerUp> inventory;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  const PowerUpInventoryState({
    this.inventory = const [],
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
  });

  PowerUpInventoryState copyWith({
    List<UserPowerUp>? inventory,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return PowerUpInventoryState(
      inventory: inventory ?? this.inventory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Retorna power-ups por tipo
  Map<PowerUpType, List<UserPowerUp>> get byType {
    final map = <PowerUpType, List<UserPowerUp>>{};
    for (final powerUp in inventory) {
      map.putIfAbsent(powerUp.type, () => []).add(powerUp);
    }
    return map;
  }

  /// Retorna power-ups disponíveis
  List<UserPowerUp> get available {
    return inventory.where((p) => p.isAvailable).toList();
  }

  /// Retorna quantidade total de um tipo específico
  int getQuantity(PowerUpType type) {
    return inventory
        .where((p) => p.type == type && p.isAvailable)
        .fold(0, (sum, p) => sum + p.quantity);
  }

  /// Verifica se tem um power-up específico
  bool hasPowerUp(PowerUpType type) {
    return getQuantity(type) > 0;
  }
}

/// Dados padrão dos power-ups
class PowerUpData {
  static const List<PowerUp> defaultPowerUps = [
    PowerUp(
      id: 'extra_hint',
      type: PowerUpType.extraHint,
      name: 'Dica Extra',
      description: 'Revela uma dica adicional sobre a resposta correta',
      emoji: '💡',
      coinsCost: 25,
      rarity: PowerUpRarity.common,
    ),
    PowerUp(
      id: 'super_question',
      type: PowerUpType.superQuestion,
      name: 'Super Pergunta',
      description: 'Faz uma pergunta que revela 25% a mais do perfil',
      emoji: '🔥',
      coinsCost: 50,
      rarity: PowerUpRarity.rare,
    ),
    PowerUp(
      id: 'match_booster',
      type: PowerUpType.matchBooster,
      name: 'Match Booster',
      description: 'Dobra a pontuação de revelação por 3 perguntas',
      emoji: '⚡',
      coinsCost: 75,
      rarity: PowerUpRarity.epic,
    ),
    PowerUp(
      id: 'time_freeze',
      type: PowerUpType.timeFreeze,
      name: 'Congelar Tempo',
      description: 'Para o tempo por 30 segundos no modo rápido',
      emoji: '❄️',
      coinsCost: 40,
      gemsCost: 2,
      duration: 30,
      rarity: PowerUpRarity.rare,
      gameModesAllowed: ['rapidFire'],
    ),
    PowerUp(
      id: 'skip_question',
      type: PowerUpType.skipQuestion,
      name: 'Pular Pergunta',
      description: 'Pula uma pergunta difícil sem perder pontos',
      emoji: '⏭️',
      coinsCost: 30,
      rarity: PowerUpRarity.common,
    ),
    PowerUp(
      id: 'double_chance',
      type: PowerUpType.doubleChance,
      name: 'Segunda Chance',
      description: 'Permite uma segunda tentativa na pergunta atual',
      emoji: '🎯',
      coinsCost: 35,
      rarity: PowerUpRarity.rare,
    ),
    PowerUp(
      id: 'xray_vision',
      type: PowerUpType.xrayVision,
      name: 'Visão Raio-X',
      description: 'Mostra metade das opções incorretas',
      emoji: '👁️',
      coinsCost: 45,
      gemsCost: 1,
      rarity: PowerUpRarity.epic,
    ),
    PowerUp(
      id: 'lucky_guess',
      type: PowerUpType.luckyGuess,
      name: 'Palpite Sortudo',
      description: 'Resposta aleatória com 75% de chance de acerto',
      emoji: '🍀',
      coinsCost: 100,
      gemsCost: 5,
      rarity: PowerUpRarity.legendary,
    ),
  ];

  /// Retorna power-up por ID
  static PowerUp? getPowerUpById(String id) {
    try {
      return defaultPowerUps.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Retorna power-up por tipo
  static PowerUp? getPowerUpByType(PowerUpType type) {
    try {
      return defaultPowerUps.firstWhere((p) => p.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Retorna power-ups por raridade
  static List<PowerUp> getPowerUpsByRarity(PowerUpRarity rarity) {
    return defaultPowerUps.where((p) => p.rarity == rarity).toList();
  }

  /// Retorna power-ups disponíveis para um modo de jogo
  static List<PowerUp> getPowerUpsForGameMode(String gameMode) {
    return defaultPowerUps.where((p) => 
      p.gameModesAllowed.isEmpty || p.gameModesAllowed.contains(gameMode)
    ).toList();
  }

  /// Retorna power-ups que o usuário pode comprar
  static List<PowerUp> getAffordablePowerUps(int coins, int gems) {
    return defaultPowerUps.where((p) => 
      p.coinsCost <= coins && (p.gemsCost == null || p.gemsCost! <= gems)
    ).toList();
  }
}