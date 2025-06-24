// lib/features/home/widgets/home_mini_games_section.dart
// ✅ WIDGET PARA ADICIONAR NA HOME SCREEN EXISTENTE

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/features/mini_games/widgets/mini_games_access_widget.dart';
import 'package:unlock/models/mini_game_model.dart';

/// Seção de mini-games para adicionar na home screen
class HomeMiniGamesSection extends ConsumerWidget {
  const HomeMiniGamesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context),
          const SizedBox(height: 16),
          const MiniGamesAccessWidget(),
        ],
      ),
    );
  }

  /// Cabeçalho da seção
  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.videogame_asset,
            color: Colors.purple,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Desafie-se nos Mini Games',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Teste suas habilidades e estabeleça recordes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.push('/mini-games'),
          child: const Text('Ver Todos'),
        ),
      ],
    );
  }
}

/// Quick actions para mini-games (botões de ação rápida)
class MiniGamesQuickActions extends StatelessWidget {
  const MiniGamesQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Jogo rápido
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.flash_on,
                  title: 'Jogo Rápido',
                  subtitle: 'Partida aleatória',
                  color: Colors.orange,
                  onTap: () => _startRandomGame(context),
                ),
              ),
              const SizedBox(width: 12),

              // Ver rankings
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.leaderboard,
                  title: 'Rankings',
                  subtitle: 'Sua posição',
                  color: Colors.blue,
                  onTap: () => context.push('/mini-games/leaderboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card de ação rápida
  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Iniciar jogo aleatório
  void _startRandomGame(BuildContext context) {
    final games = GameType.values;
    final randomGame = games[DateTime.now().millisecond % games.length];
    context.push('/mini-games/${randomGame.id}');
  }
}

/// Floating Action Button para mini-games
class MiniGamesFAB extends StatelessWidget {
  const MiniGamesFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/mini-games'),
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.videogame_asset),
      label: const Text('Jogar'),
      tooltip: 'Abrir Mini Games',
    );
  }
}

/// Bottom sheet com mini-games
class MiniGamesBottomSheet extends StatelessWidget {
  const MiniGamesBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MiniGamesBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.videogame_asset, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Mini Games',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Lista de jogos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: GameType.values.length,
              itemBuilder: (context, index) {
                final gameType = GameType.values[index];
                return _buildGameListTile(context, gameType);
              },
            ),
          ),

          // Botão de ver todos
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/mini-games');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Explorar Todos os Jogos'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tile de jogo na lista
  Widget _buildGameListTile(BuildContext context, GameType gameType) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: gameType.themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(gameType.icon, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(
        gameType.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(gameType.description),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.of(context).pop();
        context.push('/mini-games/${gameType.id}');
      },
    );
  }
}
