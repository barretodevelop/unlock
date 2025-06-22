// lib/models/game_model.dart

import 'package:flutter/material.dart';
import 'package:unlock/features/rewards/models/reward_model.dart'; // Importe RewardType

/// Representa um mini-game disponível no aplicativo.
///
/// Este modelo define as propriedades de cada jogo, incluindo informações
/// de exibição, rota de navegação e recompensas base.
class GameModel {
  final String id;
  final String name;
  final String description;
  final IconData icon; // Ícone para exibição na lista
  final String route; // Rota GoRouter para a tela do jogo
  final Map<RewardType, int> baseRewards; // Recompensas base por tipo
  final bool isAvailable; // Para controlar se o jogo está ativo/desbloqueado

  const GameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.route,
    this.baseRewards = const {},
    this.isAvailable = true,
  });

  /// Factory para criar um GameModel a partir de um JSON (Firestore, etc.)
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      route: json['route'] as String,
      baseRewards:
          (json['baseRewards'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(RewardType.fromString(key), value as int),
          ) ??
          {},
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  /// Converte o GameModel para JSON (para salvar no Firestore, etc.)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'route': route,
      'baseRewards': baseRewards.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'isAvailable': isAvailable,
    };
  }
}
