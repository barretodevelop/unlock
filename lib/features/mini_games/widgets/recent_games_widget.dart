// lib/features/mini_games/widgets/recent_games_widget.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/mini_game_model.dart';

/// Widget mostrando jogos recentes do usuário
class RecentGamesWidget extends StatefulWidget {
  final Map<GameType, List<GameResult>> recentGames;

  const RecentGamesWidget({
    super.key,
    required this.recentGames,
  });

  @override
  State<RecentGamesWidget> createState() => _RecentGamesWidgetState();
}

class _RecentGamesWidgetState extends State<RecentGamesWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allRecentGames = _getAllRecentGames();

    if (allRecentGames.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 16),
            _buildRecentGamesList(allRecentGames),
          ],
        ),
      ),
    );
  }

  /// Cabeçalho da seção
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.history,
            color: Colors.blue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atividade Recente',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Suas últimas partidas',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _viewAllHistory,
          child: const Text('Ver Todos'),
        ),
      ],
    );
  }

  /// Lista de jogos recentes
  Widget _buildRecentGamesList(List<GameResult> allRecentGames) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allRecentGames.length.clamp(0, 5), // Máximo 5 itens
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final game = allRecentGames[index];
        return _buildGameItem(game, index);
      },
    );
  }

  /// Item individual de jogo
  Widget _buildGameItem(GameResult game, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _buildGameCard(game),
          ),
        );
      },
    );
  }

  /// Card do jogo
  Widget _buildGameCard(GameResult game) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildGameIcon(game),
          const SizedBox(width: 12),
          Expanded(
            child: _buildGameInfo(game),
          ),
          _buildGameScore(game),
        ],
      ),
    );
  }

  /// Ícone do jogo
  Widget _buildGameIcon(GameResult game) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: game.type.themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: game.type.themeColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        game.type.icon,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  /// Informações do jogo
  Widget _buildGameInfo(GameResult game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              game.type.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            _buildRankBadge(game),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              _formatRelativeTime(game.completedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.timer,
              size: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(game.duration),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Badge do rank
  Widget _buildRankBadge(GameResult game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: game.rankColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: game.rankColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        game.rank,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: game.rankColor,
        ),
      ),
    );
  }

  /// Score do jogo
  Widget _buildGameScore(GameResult game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${game.finalScore}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: game.type.themeColor,
          ),
        ),
        Text(
          'pts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        if (game.isPersonalBest) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'PB',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Estado vazio
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.games_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum jogo recente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sua atividade de jogos aparecerá aqui',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ========== MÉTODOS AUXILIARES ==========

  /// Obter todos os jogos recentes ordenados por data
  List<GameResult> _getAllRecentGames() {
    final allGames = <GameResult>[];
    
    for (final games in widget.recentGames.values) {
      allGames.addAll(games);
    }
    
    // Ordenar por data mais recente
    allGames.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    
    return allGames;
  }

  /// Formatar tempo relativo
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  /// Formatar duração
  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Navegar para histórico completo
  void _viewAllHistory() {
    // Implementar navegação para tela de histórico
    // context.push('/mini-games/history');
  }
}