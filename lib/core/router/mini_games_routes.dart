// lib/core/routes/mini_games_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/features/mini_games/screens/game_play_screen.dart';
import 'package:unlock/features/mini_games/screens/mini_games_screen.dart';

/// Rotas dos mini-games
class MiniGamesRoutes {
  /// Lista de rotas dos mini-games
  static List<RouteBase> get routes => [
    // Tela principal dos mini-games
    GoRoute(
      path: '/mini-games',
      name: 'mini-games',
      builder: (context, state) => const MiniGamesScreen(),
    ),

    // Jogo específico
    GoRoute(
      path: '/mini-games/:gameType',
      name: 'mini-game-play',
      builder: (context, state) {
        final gameType = state.pathParameters['gameType']!;
        return GamePlayScreen(gameTypeId: gameType);
      },
    ),

    // Leaderboard (para implementação futura)
    GoRoute(
      path: '/mini-games/leaderboard',
      name: 'mini-games-leaderboard',
      builder: (context, state) => const MiniGamesLeaderboardScreen(),
    ),

    // Histórico (para implementação futura)
    GoRoute(
      path: '/mini-games/history',
      name: 'mini-games-history',
      builder: (context, state) => const MiniGamesHistoryScreen(),
    ),
  ];
}

/// Placeholder para leaderboard (implementação futura)
class MiniGamesLeaderboardScreen extends StatelessWidget {
  const MiniGamesLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: const Center(
        child: Text('Leaderboard dos Mini-Games\n(Em desenvolvimento)'),
      ),
    );
  }
}

/// Placeholder para histórico (implementação futura)
class MiniGamesHistoryScreen extends StatelessWidget {
  const MiniGamesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: const Center(
        child: Text('Histórico de Jogos\n(Em desenvolvimento)'),
      ),
    );
  }
}
