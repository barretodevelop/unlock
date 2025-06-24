// lib/features/game/widgets/game_tabs.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/theme/app_colors.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/providers/multi_game_provider.dart';
import 'package:unlock/shared/widgets/user_avatar.dart';

/// Widget de tabs compacto para navegação entre jogos na home
class GameTabs extends ConsumerWidget {
  final bool showHeader;
  final int maxGamesToShow;
  final VoidCallback? onSeeAll;

  const GameTabs({
    super.key,
    this.showHeader = true,
    this.maxGamesToShow = 3,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesCategorized = ref.watch(gamesCategorizedProvider);
    final gameCounts = ref.watch(gameCountsProvider);
    final theme = Theme.of(context);

    final totalGames = gameCounts['total'] ?? 0;

    if (totalGames == 0) {
      return _EmptyGamesWidget(
        onCreateGame: () => _showCreateGameOptions(context, ref),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) _GameTabsHeader(totalGames: totalGames),

          // Games preview
          _GamesPreview(
            gamesCategorized: gamesCategorized,
            maxToShow: maxGamesToShow,
          ),

          // Action buttons
          _ActionButtons(
            hasGames: totalGames > 0,
            onSeeAll: onSeeAll,
            onCreateGame: () => _showCreateGameOptions(context, ref),
          ),
        ],
      ),
    );
  }

  void _showCreateGameOptions(BuildContext context, WidgetRef ref) {
    // TODO: Implementar seleção de usuário para criar jogo
    context.push('/users'); // Navegar para lista de usuários
  }
}

/// Header do widget de tabs
class _GameTabsHeader extends StatelessWidget {
  final int totalGames;

  const _GameTabsHeader({required this.totalGames});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.sports_esports,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seus Jogos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$totalGames ${totalGames == 1 ? 'jogo ativo' : 'jogos ativos'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview dos jogos organizados por categoria
class _GamesPreview extends ConsumerWidget {
  final Map<String, List<GameRoomModel>> gamesCategorized;
  final int maxToShow;

  const _GamesPreview({
    required this.gamesCategorized,
    required this.maxToShow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGames = <GameRoomModel>[];

    // Prioriza convites pendentes, depois jogos ativos, depois aguardando
    allGames.addAll(gamesCategorized['pending'] ?? []);
    allGames.addAll(gamesCategorized['active'] ?? []);
    allGames.addAll(gamesCategorized['waiting'] ?? []);

    final gamesToShow = allGames.take(maxToShow).toList();

    return Column(
      children: gamesToShow.asMap().entries.map((entry) {
        final index = entry.key;
        final game = entry.value;

        return _GamePreviewTile(game: game, index: index)
            .animate(delay: (index * 100).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.2, end: 0);
      }).toList(),
    );
  }
}

/// Tile individual de preview do jogo
class _GamePreviewTile extends ConsumerWidget {
  final GameRoomModel game;
  final int index;

  const _GamePreviewTile({required this.game, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gameType = _getGameType(game);

    return InkWell(
      onTap: () => _handleTap(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            _GameStatusDot(type: gameType),
            const SizedBox(width: 12),

            // Game info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGameTitle(gameType),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getGameSubtitle(game),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            _ProgressIndicator(game: game),

            const SizedBox(width: 8),

            // Arrow
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    // Seleciona o jogo
    ref.read(multiGameNotifierProvider.notifier).selectGame(game.id);

    // Navega baseado no tipo
    final gameType = _getGameType(game);
    if (gameType == GamePreviewType.pending) {
      context.push('/game/${game.id}?action=review');
    } else {
      context.push('/game/${game.id}');
    }
  }

  GamePreviewType _getGameType(GameRoomModel game) {
    switch (GameStatus.values.firstWhere((s) => s.name == game.status)) {
      case GameStatus.pending:
        return GamePreviewType.pending;
      case GameStatus.active:
        // TODO: Verificar se é a vez do usuário atual
        return GamePreviewType.active;
      default:
        return GamePreviewType.waiting;
    }
  }

  String _getGameTitle(GamePreviewType type) {
    switch (type) {
      case GamePreviewType.pending:
        return 'Novo Convite';
      case GamePreviewType.active:
        return 'Sua Vez';
      case GamePreviewType.waiting:
        return 'Aguardando';
    }
  }

  String _getGameSubtitle(GameRoomModel game) {
    final timeAgo = _getTimeAgo(game.updatedAt);
    return 'Atualizado $timeAgo';
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'agora';
    }
  }
}

/// Indicador de status do jogo (dot colorido)
class _GameStatusDot extends StatelessWidget {
  final GamePreviewType type;

  const _GameStatusDot({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (type) {
      case GamePreviewType.pending:
        color = AppColors.warning;
        break;
      case GamePreviewType.active:
        color = AppColors.success;
        break;
      case GamePreviewType.waiting:
        color = AppColors.info;
        break;
    }

    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.2, 1.2),
          duration: 1000.ms,
        );
  }
}

/// Indicador de progresso compacto
class _ProgressIndicator extends StatelessWidget {
  final GameRoomModel game;

  const _ProgressIndicator({required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = game.revealPercentage / 100;

    return Column(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: theme.colorScheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${game.revealPercentage.toInt()}%',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Botões de ação na parte inferior
class _ActionButtons extends ConsumerWidget {
  final bool hasGames;
  final VoidCallback? onSeeAll;
  final VoidCallback? onCreateGame;

  const _ActionButtons({
    required this.hasGames,
    this.onSeeAll,
    this.onCreateGame,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCreateAsync = ref.watch(canCreateGameProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (hasGames) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSeeAll ?? () => context.push('/games'),
                icon: const Icon(Icons.list_outlined),
                label: const Text('Ver Todos'),
              ),
            ),
            const SizedBox(width: 12),
          ],

          Expanded(
            child: canCreateAsync.when(
              data: (canCreate) => ElevatedButton.icon(
                onPressed: canCreate ? onCreateGame : null,
                icon: const Icon(Icons.add),
                label: Text(canCreate ? 'Novo Jogo' : 'Limite Atingido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canCreate ? AppColors.primary : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
              loading: () => const ElevatedButton(
                onPressed: null,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget quando não há jogos ativos
class _EmptyGamesWidget extends StatelessWidget {
  final VoidCallback? onCreateGame;

  const _EmptyGamesWidget({this.onCreateGame});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_esports_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum jogo ativo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Que tal começar sua primeira descoberta?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreateGame,
              icon: const Icon(Icons.add),
              label: const Text('Começar Jogo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }
}

/// Versão compacta do GameTabs para uso em outros lugares
class CompactGameTabs extends ConsumerWidget {
  const CompactGameTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameCounts = ref.watch(gameCountsProvider);
    final nextActionGame = ref.watch(nextActionGameProvider);
    final theme = Theme.of(context);

    final totalGames = gameCounts['total'] ?? 0;

    if (totalGames == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/games'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.sports_esports, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextActionGame != null
                          ? _getActionText(nextActionGame)
                          : 'Jogos Ativos',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '$totalGames ${totalGames == 1 ? 'jogo' : 'jogos'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (gameCounts['pending']! > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${gameCounts['pending']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionText(GameRoomModel game) {
    switch (GameStatus.values.firstWhere((s) => s.name == game.status)) {
      case GameStatus.pending:
        return 'Novo Convite Recebido';
      case GameStatus.active:
        return 'Sua Vez de Jogar';
      default:
        return 'Jogos Ativos';
    }
  }
}

/// Enum para tipos de preview de jogos
enum GamePreviewType { pending, active, waiting }
