// lib/features/games/providers/games_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/router/app_router.dart';
import 'package:unlock/features/rewards/models/reward_model.dart';
import 'package:unlock/models/game_model.dart';

/// Provider que gerencia a lista de mini-games disponíveis.
///
/// Por enquanto, a lista é estática. No futuro, pode ser estendida
/// para carregar jogos de um backend (ex: Firestore).
final gamesProvider = StateNotifierProvider<GamesNotifier, List<GameModel>>((
  ref,
) {
  return GamesNotifier();
});

class GamesNotifier extends StateNotifier<List<GameModel>> {
  GamesNotifier() : super(_initialGames);

  // Lista inicial de mini-games (pode ser carregada de um backend no futuro)
  static final List<GameModel> _initialGames = [
    GameModel(
      id: 'memory_game',
      name: 'Jogo da Memória',
      description: 'Teste sua memória e ganhe XP!',
      icon: Icons.memory,
      route: AppRoutes.memoryGame,
      baseRewards: {RewardType.xp: 50, RewardType.coins: 10},
    ),
    GameModel(
      id: 'quiz_game',
      name: 'Quiz de Conhecimento',
      description: 'Responda perguntas e ganhe moedas!',
      icon: Icons.quiz,
      route: AppRoutes.quizGame,
      baseRewards: {RewardType.xp: 30, RewardType.coins: 20},
    ),
    GameModel(
      id: 'puzzle_game',
      name: 'Quebra-Cabeça',
      description: 'Monte a imagem e ganhe gemas!',
      icon: Icons.extension,
      route: AppRoutes.puzzleGame,
      baseRewards: {RewardType.gems: 5, RewardType.xp: 75},
    ),
    GameModel(
      id: 'snake_game',
      name: 'Snake',
      description: 'Colete frutas e cresça sem bater!',
      icon: Icons.gamepad,
      route: AppRoutes.snakeGame,
      baseRewards: {RewardType.xp: 40, RewardType.coins: 15},
    ),
    GameModel(
      id: 'word_game',
      name: 'Caça Palavras',
      description: 'Encontre palavras escondidas!',
      icon: Icons.text_fields,
      route: AppRoutes.wordGame,
      baseRewards: {RewardType.xp: 60, RewardType.gems: 3},
    ),
    GameModel(
      id: 'number_game',
      name: 'Sequência Numérica',
      description: 'Ordene os números rapidamente!',
      icon: Icons.numbers,
      route: AppRoutes.numberGame,
      baseRewards: {RewardType.xp: 35, RewardType.coins: 12},
    ),
    GameModel(
      id: 'color_match_game',
      name: 'Combinação de Cores',
      description: 'Combine cores e ganhe pontos!',
      icon: Icons.palette,
      route: AppRoutes.colorMatchGame,
      baseRewards: {RewardType.xp: 45, RewardType.gems: 2, RewardType.coins: 8},
    ),
    GameModel(
      id: 'reaction_game',
      name: 'Teste de Reflexo',
      description: 'Teste sua velocidade de reação!',
      icon: Icons.flash_on,
      route: AppRoutes.reactionGame,
      baseRewards: {RewardType.xp: 25, RewardType.coins: 18},
    ),
    GameModel(
      id: 'match_game',
      name: 'Desafio Matemático',
      description: 'Resolva operações rapidamente!',
      icon: Icons.calculate,
      route: AppRoutes.matchGame,
      baseRewards: {RewardType.xp: 55, RewardType.gems: 4},
    ),
  ];
}
