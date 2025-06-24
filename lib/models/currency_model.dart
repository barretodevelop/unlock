// lib/models/currency_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para transações de moeda no sistema Unlock
class CurrencyTransaction {
  final String id;
  final String userId;
  final int amount;
  final CurrencyType type;
  final CurrencyReason reason;
  final String? gameId;
  final String? description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const CurrencyTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.reason,
    this.gameId,
    this.description,
    required this.timestamp,
    this.metadata = const {},
  });

  factory CurrencyTransaction.fromJson(Map<String, dynamic> json) {
    return CurrencyTransaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: json['amount'] ?? 0,
      type: CurrencyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CurrencyType.coins,
      ),
      reason: CurrencyReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => CurrencyReason.unknown,
      ),
      gameId: json['gameId'],
      description: json['description'],
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'reason': reason.name,
      'gameId': gameId,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  CurrencyTransaction copyWith({
    String? id,
    String? userId,
    int? amount,
    CurrencyType? type,
    CurrencyReason? reason,
    String? gameId,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return CurrencyTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      gameId: gameId ?? this.gameId,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Tipos de moeda disponíveis
enum CurrencyType {
  coins('Moedas', '💰'),
  gems('Gemas', '💎');

  const CurrencyType(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

/// Razões para ganhar/perder moedas
enum CurrencyReason {
  gameCompleted('Quiz Completado', 50, CurrencyType.coins),
  connectionFormed('Conexão Formada', 100, CurrencyType.coins),
  dailyLogin('Login Diário', 20, CurrencyType.coins),
  firstConnection('Primeira Conexão', 200, CurrencyType.coins),
  loginStreak('Sequência de Login', 10, CurrencyType.coins),
  achievementUnlocked('Conquista Desbloqueada', 30, CurrencyType.coins),
  powerupPurchased('Power-up Comprado', -25, CurrencyType.coins),
  weeklyBonus('Bônus Semanal', 5, CurrencyType.gems),
  premiumReward('Recompensa Premium', 10, CurrencyType.gems),
  unknown('Desconhecido', 0, CurrencyType.coins);

  const CurrencyReason(this.description, this.defaultAmount, this.defaultType);
  final String description;
  final int defaultAmount;
  final CurrencyType defaultType;

  /// Verifica se é uma recompensa positiva
  bool get isReward => defaultAmount > 0;

  /// Verifica se é um gasto
  bool get isExpense => defaultAmount < 0;
}

/// Estado das moedas do usuário
class CurrencyState {
  final int coins;
  final int gems;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  const CurrencyState({
    this.coins = 0,
    this.gems = 0,
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
  });

  /// Estado inicial
  factory CurrencyState.initial() {
    return CurrencyState(
      coins: 200, // Bônus inicial
      gems: 20, // Bônus inicial
      lastUpdated: DateTime.now(),
    );
  }

  /// Estado de loading
  CurrencyState loading() {
    return copyWith(isLoading: true, error: null);
  }

  /// Estado de erro
  CurrencyState withError(String error) {
    return copyWith(isLoading: false, error: error);
  }

  /// Estado de sucesso com novos valores
  CurrencyState withBalances(int newCoins, int newGems) {
    return copyWith(
      coins: newCoins,
      gems: newGems,
      isLoading: false,
      error: null,
      lastUpdated: DateTime.now(),
    );
  }

  CurrencyState copyWith({
    int? coins,
    int? gems,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return CurrencyState(
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Verifica se o usuário pode gastar uma quantidade específica
  bool canAfford(int amount, CurrencyType type) {
    switch (type) {
      case CurrencyType.coins:
        return coins >= amount;
      case CurrencyType.gems:
        return gems >= amount;
    }
  }

  /// Retorna o saldo da moeda especificada
  int getBalance(CurrencyType type) {
    switch (type) {
      case CurrencyType.coins:
        return coins;
      case CurrencyType.gems:
        return gems;
    }
  }

  @override
  String toString() {
    return 'CurrencyState(coins: $coins, gems: $gems, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrencyState &&
        other.coins == coins &&
        other.gems == gems &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(coins, gems, isLoading, error);
  }
}
