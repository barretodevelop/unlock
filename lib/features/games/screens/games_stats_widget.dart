// lib/features/games/widgets/games_stats_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Estatísticas de jogos de um usuário
class GameStats {
  final String gameId;
  final String gameName;
  final int timesPlayed;
  final int totalScore;
  final int bestScore;
  final Duration totalPlayTime;
  final DateTime lastPlayed;
  final double averagePerformance;

  const GameStats({
    required this.gameId,
    required this.gameName,
    required this.timesPlayed,
    required this.totalScore,
    required this.bestScore,
    required this.totalPlayTime,
    required this.lastPlayed,
    required this.averagePerformance,
  });
}

/// Provider para estatísticas de jogos (mockado por enquanto)
final gameStatsProvider = Provider<List<GameStats>>((ref) {
  // Dados mockados - substituir por dados reais do backend
  return [
    GameStats(
      gameId: 'memory_game',
      gameName: 'Jogo da Memória',
      timesPlayed: 15,
      totalScore: 750,
      bestScore: 80,
      totalPlayTime: const Duration(minutes: 45),
      lastPlayed: DateTime.now().subtract(const Duration(hours: 2)),
      averagePerformance: 0.75,
    ),
    GameStats(
      gameId: 'quiz_game',
      gameName: 'Quiz de Conhecimento',
      timesPlayed: 8,
      totalScore: 560,
      bestScore: 95,
      totalPlayTime: const Duration(minutes: 32),
      lastPlayed: DateTime.now().subtract(const Duration(days: 1)),
      averagePerformance: 0.82,
    ),
    GameStats(
      gameId: 'puzzle_game',
      gameName: 'Quebra-Cabeça',
      timesPlayed: 12,
      totalScore: 480,
      bestScore: 60,
      totalPlayTime: const Duration(minutes: 28),
      lastPlayed: DateTime.now().subtract(const Duration(hours: 6)),
      averagePerformance: 0.68,
    ),
  ];
});

/// Widget que exibe estatísticas detalhadas dos jogos do usuário.
///
/// Pode ser usado em dashboards, perfil do usuário ou tela de estatísticas.
class GamesStatsWidget extends ConsumerWidget {
  final bool showHeader;
  final bool isCompact;
  final int maxGamesToShow;

  const GamesStatsWidget({
    super.key,
    this.showHeader = true,
    this.isCompact = false,
    this.maxGamesToShow = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(gameStatsProvider);
    final userAsync = ref.watch(authProvider);
    return Placeholder();
    // return userAsync.when(
    //   loading: () => _buildLoadingState(),
    //   error: (error, stack) => _buildErrorState(context),
    //   data: (user) => user == null
    //       ? _buildNotLoggedInState(context)
    //       : _buildStatsContent(context, stats),
    // );
  }

  Widget _buildLoadingState() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Erro ao carregar estatísticas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.login,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Faça login para ver suas estatísticas',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, List<GameStats> stats) {
    final limitedStats = stats.take(maxGamesToShow).toList();

    return Card(
      elevation: isCompact ? 2 : 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              _buildHeader(context, stats),
              const SizedBox(height: 16),
            ],
            if (isCompact)
              _buildCompactStats(context, limitedStats)
            else
              _buildDetailedStats(context, limitedStats),
            if (stats.length > maxGamesToShow) ...[
              const SizedBox(height: 12),
              _buildViewAllButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<GameStats> stats) {
    final totalGames = stats.length;
    final totalPlays = stats.fold<int>(
      0,
      (sum, stat) => sum + stat.timesPlayed,
    );
    final totalTime = stats.fold<Duration>(
      Duration.zero,
      (sum, stat) => sum + stat.totalPlayTime,
    );

    return Row(
      children: [
        Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estatísticas dos Jogos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$totalGames jogos • $totalPlays partidas • ${_formatDuration(totalTime)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.pushNamed('gameStats'),
          icon: const Icon(Icons.open_in_new),
          tooltip: 'Ver detalhes',
        ),
      ],
    );
  }

  Widget _buildCompactStats(BuildContext context, List<GameStats> stats) {
    return Column(
      children: stats
          .map((stat) => _buildCompactStatItem(context, stat))
          .toList(),
    );
  }

  Widget _buildCompactStatItem(BuildContext context, GameStats stat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildPerformanceIndicator(stat.averagePerformance),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.gameName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${stat.timesPlayed} partidas • Melhor: ${stat.bestScore}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatLastPlayed(stat.lastPlayed),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context, List<GameStats> stats) {
    return Column(
      children: stats
          .map((stat) => _buildDetailedStatCard(context, stat))
          .toList(),
    );
  }

  Widget _buildDetailedStatCard(BuildContext context, GameStats stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.gameName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _buildPerformanceIndicator(stat.averagePerformance),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatMetric(
                  context,
                  'Partidas',
                  stat.timesPlayed.toString(),
                  Icons.play_circle,
                ),
              ),
              Expanded(
                child: _buildStatMetric(
                  context,
                  'Melhor Score',
                  stat.bestScore.toString(),
                  Icons.emoji_events,
                ),
              ),
              Expanded(
                child: _buildStatMetric(
                  context,
                  'Tempo Total',
                  _formatDuration(stat.totalPlayTime),
                  Icons.timer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Última partida: ${_formatLastPlayed(stat.lastPlayed)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicator(double performance) {
    Color color;
    IconData icon;

    if (performance >= 0.8) {
      color = Colors.green;
      icon = Icons.star;
    } else if (performance >= 0.6) {
      color = Colors.blue;
      icon = Icons.thumb_up;
    } else if (performance >= 0.4) {
      color = Colors.orange;
      icon = Icons.trending_up;
    } else {
      color = Colors.red;
      icon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${(performance * 100).round()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => context.pushNamed('gameStats'),
        icon: const Icon(Icons.visibility),
        label: const Text('Ver Todas as Estatísticas'),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }

  String _formatLastPlayed(DateTime lastPlayed) {
    final now = DateTime.now();
    final difference = now.difference(lastPlayed);

    if (difference.inDays > 7) {
      return '${difference.inDays} dias atrás';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} dia${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora mesmo';
    }
  }
}
