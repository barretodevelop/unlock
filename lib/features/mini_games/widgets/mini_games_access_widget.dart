// lib/features/mini_games/widgets/mini_games_access_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/models/mini_game_model.dart';
import 'package:unlock/providers/mini_game_provider.dart';

/// Widget de acesso rápido aos mini-games para ser usado na home
class MiniGamesAccessWidget extends ConsumerWidget {
  final bool isCompact;

  const MiniGamesAccessWidget({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalState = ref.watch(miniGameGlobalProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (!isCompact) ...[
            const SizedBox(height: 16),
            _buildQuickStats(context, globalState),
            const SizedBox(height: 16),
            _buildQuickGamesList(context),
          ],
          const SizedBox(height: 16),
          _buildMainButton(context),
        ],
      ),
    );
  }

  /// Cabeçalho do widget
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.blue],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.videogame_asset,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mini Games',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Teste suas habilidades',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ],
    );
  }

  /// Estatísticas rápidas
  Widget _buildQuickStats(BuildContext context, MiniGameGlobalState state) {
    final personalBests = state.personalBests.length;
    final totalRecords = state.personalBests.values
        .where((best) => best != null)
        .length;

    return Row(
      children: [
        _buildStatChip(
          context,
          icon: Icons.emoji_events,
          label: 'Recordes',
          value: totalRecords.toString(),
          color: Colors.amber,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context,
          icon: Icons.sports_esports,
          label: 'Jogos',
          value: GameType.values.length.toString(),
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context,
          icon: Icons.trending_up,
          label: 'Nível',
          value: _getBestRank(state),
          color: Colors.purple,
        ),
      ],
    );
  }

  /// Chip de estatística
  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista rápida de jogos
  Widget _buildQuickGamesList(BuildContext context) {
    return Row(
      children: GameType.values.take(3).map((gameType) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildQuickGameTile(context, gameType),
          ),
        );
      }).toList(),
    );
  }

  /// Tile rápido de jogo
  Widget _buildQuickGameTile(BuildContext context, GameType gameType) {
    return GestureDetector(
      onTap: () => _navigateToGame(context, gameType),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: gameType.themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: gameType.themeColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(gameType.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              gameType.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: gameType.themeColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Botão principal
  Widget _buildMainButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToMiniGames(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.videogame_asset),
        label: Text(
          isCompact ? 'Jogar' : 'Explorar Mini Games',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Navegar para mini-games
  void _navigateToMiniGames(BuildContext context) {
    context.push('/mini-games');
  }

  /// Navegar para jogo específico
  void _navigateToGame(BuildContext context, GameType gameType) {
    context.push('/mini-games/${gameType.id}');
  }

  /// Obter melhor rank
  String _getBestRank(MiniGameGlobalState state) {
    String bestRank = 'D';

    for (final best in state.personalBests.values) {
      if (best != null && best.rank.compareTo(bestRank) < 0) {
        bestRank = best.rank;
      }
    }

    return bestRank;
  }
}

/// Widget compacto para usar em cards menores
class MiniGamesQuickAccess extends StatelessWidget {
  const MiniGamesQuickAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/mini-games'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.purple, Colors.blue]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.videogame_asset, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mini Games',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Teste suas habilidades',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
