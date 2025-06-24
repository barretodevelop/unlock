// lib/features/game/screens/active_games_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/theme/app_colors.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/game/widgets/game_tabs.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/providers/multi_game_provider.dart';
import 'package:unlock/shared/widgets/app_header_with_currency.dart';
import 'package:unlock/shared/widgets/user_avatar.dart';

/// Tela principal para gerenciar múltiplos jogos ativos
class ActiveGamesScreen extends ConsumerStatefulWidget {
  const ActiveGamesScreen({super.key});

  @override
  ConsumerState<ActiveGamesScreen> createState() => _ActiveGamesScreenState();
}

class _ActiveGamesScreenState extends ConsumerState<ActiveGamesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamesCategorized = ref.watch(gamesCategorizedProvider);
    final gameCounts = ref.watch(gameCountsProvider);
    final multiGameState = ref.watch(multiGameNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppHeaderWithCurrency(
        title: 'Jogos Ativos',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Header com estatísticas
          _StatsHeader(counts: gameCounts),

          // Tab bar
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                0.6,
              ),
              tabs: [
                Tab(
                  child: _TabWithBadge(
                    title: 'Convites',
                    count: gameCounts['pending'] ?? 0,
                    icon: Icons.inbox_outlined,
                  ),
                ),
                Tab(
                  child: _TabWithBadge(
                    title: 'Sua Vez',
                    count: gameCounts['active'] ?? 0,
                    icon: Icons.play_circle_outline,
                  ),
                ),
                Tab(
                  child: _TabWithBadge(
                    title: 'Aguardando',
                    count: gameCounts['waiting'] ?? 0,
                    icon: Icons.schedule_outlined,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _GamesList(
                  games: gamesCategorized['pending'] ?? [],
                  type: GameListType.pending,
                ),
                _GamesList(
                  games: gamesCategorized['active'] ?? [],
                  type: GameListType.active,
                ),
                _GamesList(
                  games: gamesCategorized['waiting'] ?? [],
                  type: GameListType.waiting,
                ),
              ],
            ),
          ),
        ],
      ),

      // Botão para criar novo jogo
      floatingActionButton: _CreateGameFAB(),
    );
  }
}

/// Header com estatísticas dos jogos
class _StatsHeader extends StatelessWidget {
  final Map<String, int> counts;

  const _StatsHeader({required this.counts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalGames = counts['total'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seus Jogos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalGames == 0
                      ? 'Nenhum jogo ativo'
                      : '$totalGames ${totalGames == 1 ? 'jogo ativo' : 'jogos ativos'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (totalGames > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$totalGames',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tab com badge de contagem
class _TabWithBadge extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _TabWithBadge({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Text(title),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Lista de jogos por tipo
class _GamesList extends ConsumerWidget {
  final List<GameRoomModel> games;
  final GameListType type;

  const _GamesList({required this.games, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (games.isEmpty) {
      return _EmptyState(type: type);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final game = games[index];
        return _GameCard(game: game, type: type, index: index)
            .animate(delay: (index * 100).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.2, end: 0);
      },
    );
  }
}

/// Card individual de jogo
class _GameCard extends ConsumerWidget {
  final GameRoomModel game;
  final GameListType type;
  final int index;

  const _GameCard({
    required this.game,
    required this.type,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSelected = ref.watch(isGameSelectedProvider(game.id));

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => _handleGameTap(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _GameStatusIndicator(type: type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGameTitle(type),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getGameSubtitle(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GameActionsMenu(game: game, type: type),
                ],
              ),

              const SizedBox(height: 16),

              // Progress or status
              _GameProgress(game: game),

              const SizedBox(height: 16),

              // Action buttons
              _GameActions(game: game, type: type),
            ],
          ),
        ),
      ),
    );
  }

  void _handleGameTap(BuildContext context, WidgetRef ref) {
    // Seleciona o jogo
    ref.read(multiGameNotifierProvider.notifier).selectGame(game.id);

    // Navega para o jogo se necessário
    if (type == GameListType.active || type == GameListType.waiting) {
      context.push('/game/${game.id}');
    }
  }

  String _getGameTitle(GameListType type) {
    switch (type) {
      case GameListType.pending:
        return 'Convite de Jogo';
      case GameListType.active:
        return 'Sua Vez de Jogar';
      case GameListType.waiting:
        return 'Aguardando Resposta';
    }
  }

  String _getGameSubtitle() {
    final timeAgo = _getTimeAgo(game.updatedAt);
    return 'Atualizado $timeAgo';
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'agora';
    }
  }
}

/// Indicador de status do jogo
class _GameStatusIndicator extends StatelessWidget {
  final GameListType type;

  const _GameStatusIndicator({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (type) {
      case GameListType.pending:
        color = AppColors.warning;
        icon = Icons.mail_outline;
        break;
      case GameListType.active:
        color = AppColors.success;
        icon = Icons.play_circle_fill;
        break;
      case GameListType.waiting:
        color = AppColors.info;
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// Progress do jogo
class _GameProgress extends StatelessWidget {
  final GameRoomModel game;

  const _GameProgress({required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = game.revealPercentage / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Revelação',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${game.revealPercentage.toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceContainer,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? AppColors.success : AppColors.primary,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

/// Ações do jogo
class _GameActions extends ConsumerWidget {
  final GameRoomModel game;
  final GameListType type;

  const _GameActions({required this.game, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (type) {
      case GameListType.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _declineInvite(context, ref),
                icon: const Icon(Icons.close),
                label: const Text('Recusar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptInvite(context, ref),
                icon: const Icon(Icons.check),
                label: const Text('Aceitar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case GameListType.active:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _playGame(context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Continuar Jogo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        );

      case GameListType.waiting:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _viewGame(context),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Ver Progresso'),
          ),
        );
    }
  }

  void _acceptInvite(BuildContext context, WidgetRef ref) {
    // TODO: Implementar aceitação de convite
    context.push('/game/${game.id}?action=accept');
  }

  void _declineInvite(BuildContext context, WidgetRef ref) {
    // TODO: Implementar recusa de convite
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar Convite'),
        content: const Text('Tem certeza que deseja recusar este convite?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar lógica de recusar
              AppLogger.info('Convite recusado: ${game.id}');
            },
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
  }

  void _playGame(BuildContext context) {
    context.push('/game/${game.id}');
  }

  void _viewGame(BuildContext context) {
    context.push('/game/${game.id}?readonly=true');
  }
}

/// Menu de ações do jogo
class _GameActionsMenu extends ConsumerWidget {
  final GameRoomModel game;
  final GameListType type;

  const _GameActionsMenu({required this.game, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) => _handleAction(context, ref, action),
      itemBuilder: (context) => [
        if (type != GameListType.pending)
          const PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(Icons.archive_outlined),
                SizedBox(width: 8),
                Text('Arquivar'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Excluir', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'archive':
        ref.read(multiGameNotifierProvider.notifier).archiveGame(game.id);
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Jogo'),
        content: const Text(
          'Esta ação não pode ser desfeita. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(multiGameNotifierProvider.notifier)
                  .finishGame(game.id, status: GameStatus.abandoned);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

/// Estado vazio para cada tipo de lista
class _EmptyState extends StatelessWidget {
  final GameListType type;

  const _EmptyState({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title, subtitle;
    IconData icon;

    switch (type) {
      case GameListType.pending:
        title = 'Nenhum convite';
        subtitle = 'Você não tem convites pendentes';
        icon = Icons.inbox_outlined;
        break;
      case GameListType.active:
        title = 'Nenhum jogo ativo';
        subtitle = 'Não é sua vez em nenhum jogo no momento';
        icon = Icons.play_circle_outline;
        break;
      case GameListType.waiting:
        title = 'Nenhum jogo aguardando';
        subtitle = 'Você não está aguardando respostas';
        icon = Icons.schedule_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// FAB para criar novo jogo
class _CreateGameFAB extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCreateAsync = ref.watch(canCreateGameProvider);
    final multiGameState = ref.watch(multiGameNotifierProvider);

    return canCreateAsync.when(
      data: (canCreate) => FloatingActionButton.extended(
        onPressed: canCreate && !multiGameState.isCreatingGame
            ? () => _showCreateGameDialog(context, ref)
            : null,
        backgroundColor: canCreate ? AppColors.primary : Colors.grey,
        icon: multiGameState.isCreatingGame
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add),
        label: Text(
          canCreate ? 'Novo Jogo' : 'Limite Atingido',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      loading: () => const FloatingActionButton(
        onPressed: null,
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _showCreateGameDialog(BuildContext context, WidgetRef ref) {
    // TODO: Implementar dialog para selecionar usuário para convite
    // Por enquanto, apenas mostra um placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Jogo'),
        content: const Text(
          'Funcionalidade em desenvolvimento. Em breve você poderá convidar outros usuários!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Enum para tipos de lista de jogos
enum GameListType { pending, active, waiting }
