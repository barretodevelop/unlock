// lib/features/voting/screens/voting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/widgets/modern_app_bar.dart';
import 'package:unlock/features/voting/widgets/voting_utility_widgets.dart';
import 'package:unlock/features/voting/widgets/voting_widgets.dart';
import 'package:unlock/models/submission_model.dart';
import 'package:unlock/models/vote_model.dart';
import 'package:unlock/providers/challenge_provider.dart';
import 'package:unlock/providers/voting_provider.dart';

/// Tela principal de votação para um desafio
class VotingScreen extends ConsumerStatefulWidget {
  final String challengeId;

  const VotingScreen({super.key, required this.challengeId});

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late TabController _tabController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🗳️ VotingScreen iniciada: ${widget.challengeId}');

    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _tabController = TabController(length: 2, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(
      challengeSubmissionsProvider(widget.challengeId),
    );
    final rankingAsync = ref.watch(votingRankingProvider(widget.challengeId));

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Scaffold(
            appBar: ModernAppBar(
              title: 'Votação',
              // subtitle: 'Escolha os melhores!',
              // showBackButton: true,
              actions: [
                IconButton(
                  onPressed: () => _showVotingInfo(context),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            body: submissionsAsync.when(
              data: (submissions) =>
                  _buildVotingContent(context, submissions, rankingAsync),
              loading: () => const VotingLoadingWidget(
                message: 'Carregando submissões...',
              ),
              error: (error, stack) => VotingErrorWidget(
                message: 'Erro ao carregar submissões',
                onRetry: () => ref.refresh(
                  challengeSubmissionsProvider(widget.challengeId),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construir conteúdo principal da tela
  Widget _buildVotingContent(
    BuildContext context,
    List<Submission> submissions,
    AsyncValue<List<VotingStats>> rankingAsync,
  ) {
    if (submissions.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Timer de votação e informações
        _buildVotingHeader(context),

        // Tabs: Galeria vs Ranking
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: 'Galeria'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Ranking'),
          ],
        ),

        // Conteúdo das tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSubmissionsGallery(context, submissions),
              _buildVotingRanking(context, rankingAsync),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir cabeçalho com timer e informações
  Widget _buildVotingHeader(BuildContext context) {
    // Em um caso real, você obteria essas informações do desafio
    final mockVotingConfig = VotingConfig(
      isVotingEnabled: true,
      votingStartsAt: DateTime.now().subtract(const Duration(hours: 1)),
      votingEndsAt: DateTime.now().add(const Duration(hours: 23)),
      allowSelfVoting: false,
      maxVotesPerUser: 50,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.how_to_vote,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votação Ativa',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Vote nas suas submissões favoritas!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              VotingTimer(votingConfig: mockVotingConfig),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir galeria de submissões
  Widget _buildSubmissionsGallery(
    BuildContext context,
    List<Submission> submissions,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(challengeSubmissionsProvider(widget.challengeId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: submissions.length,
        itemBuilder: (context, index) {
          final submission = submissions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSubmissionCard(context, submission),
          );
        },
      ),
    );
  }

  /// Construir card de submissão
  Widget _buildSubmissionCard(BuildContext context, Submission submission) {
    // Configuração mock de votação - em produção viria do desafio
    final mockVotingConfig = VotingConfig(
      isVotingEnabled: true,
      votingStartsAt: DateTime.now().subtract(const Duration(hours: 1)),
      votingEndsAt: DateTime.now().add(const Duration(hours: 23)),
      allowSelfVoting: false,
      maxVotesPerUser: 50,
    );

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da submissão
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(submission.userAvatar),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.username,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatSubmissionTime(submission.submittedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (submission.isLeading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '1º',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Conteúdo da submissão (placeholder)
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getSubmissionIcon(submission.type),
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${submission.type.name.toUpperCase()} Submission',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botões de votação
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: VoteButtonRow(
              submission: submission,
              challengeId: widget.challengeId,
              votingConfig: mockVotingConfig,
              showCounts: true,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Construir ranking de votação
  Widget _buildVotingRanking(
    BuildContext context,
    AsyncValue<List<VotingStats>> rankingAsync,
  ) {
    return rankingAsync.when(
      data: (ranking) {
        if (ranking.isEmpty) {
          return _buildEmptyRankingState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ranking.length,
          itemBuilder: (context, index) {
            final stats = ranking[index];
            return _buildRankingItem(context, stats, index + 1);
          },
        );
      },
      loading: () =>
          const VotingLoadingWidget(message: 'Carregando ranking...'),
      error: (error, stack) => VotingErrorWidget(
        message: 'Erro ao carregar ranking',
        onRetry: () => ref.refresh(votingRankingProvider(widget.challengeId)),
      ),
    );
  }

  /// Construir item do ranking
  Widget _buildRankingItem(
    BuildContext context,
    VotingStats stats,
    int position,
  ) {
    final isTopThree = position <= 3;
    final medal = position == 1
        ? '🥇'
        : position == 2
        ? '🥈'
        : position == 3
        ? '🥉'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTopThree
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTopThree
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Posição
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTopThree
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                medal.isNotEmpty ? medal : position.toString(),
                style: TextStyle(
                  color: isTopThree
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: medal.isNotEmpty ? 20 : 16,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Estatísticas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submissão ${stats.submissionId.substring(0, 8)}...',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatChip(
                      context,
                      '${stats.totalVotes} votos',
                      Icons.how_to_vote,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      context,
                      '${stats.score.toStringAsFixed(1)} pts',
                      Icons.star,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Voto mais popular
          if (stats.mostPopularVote != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                stats.mostPopularVote!.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
        ],
      ),
    );
  }

  /// Construir chip de estatística pequeno
  Widget _buildStatChip(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Estado vazio para submissões
  Widget _buildEmptyState(BuildContext context) {
    return VotingEmptyWidget(
      title: 'Nenhuma submissão encontrada',
      subtitle: 'Aguarde até que participantes enviem suas criações.',
      icon: Icons.ballot,
    );
  }

  /// Estado vazio para ranking
  Widget _buildEmptyRankingState(BuildContext context) {
    return VotingEmptyWidget(
      title: 'Ranking ainda não disponível',
      subtitle: 'Aguarde os primeiros votos para ver o ranking.',
      icon: Icons.leaderboard,
      isCompact: true,
    );
  }

  /// Mostrar informações sobre votação
  void _showVotingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como Funciona a Votação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('👍', 'Curtir', '1 ponto'),
            _buildInfoItem('❤️', 'Amar', '3 pontos'),
            _buildInfoItem('😮', 'Uau', '2 pontos'),
            _buildInfoItem('😂', 'Rir', '2 pontos'),
            _buildInfoItem('😠', 'Raiva', '-1 ponto'),
            const SizedBox(height: 16),
            Text(
              'Você pode votar em múltiplas submissões e alterar seus votos durante o período de votação.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  /// Construir item de informação
  Widget _buildInfoItem(String emoji, String label, String points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            points,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: points.startsWith('-') ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  /// Obter ícone do tipo de submissão
  IconData _getSubmissionIcon(SubmissionType type) {
    switch (type) {
      case SubmissionType.image:
        return Icons.image;
      case SubmissionType.video:
        return Icons.video_camera_back;
      case SubmissionType.text:
        return Icons.text_fields;
      case SubmissionType.score:
        return Icons.emoji_events;
      case SubmissionType.data:
        return Icons.data_object;
    }
  }

  /// Formatar tempo da submissão
  String _formatSubmissionTime(DateTime submittedAt) {
    final now = DateTime.now();
    final difference = now.difference(submittedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora mesmo';
    }
  }
}
