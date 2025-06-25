// lib/features/voting/widgets/voting_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/submission_model.dart';
import 'package:unlock/models/vote_model.dart';
import 'package:unlock/providers/voting_provider.dart';

// ========== VOTE BUTTON ROW ==========

/// Widget de botões de votação horizontal
class VoteButtonRow extends ConsumerStatefulWidget {
  final Submission submission;
  final String challengeId;
  final VotingConfig? votingConfig;
  final bool isCompact;
  final bool showCounts;

  const VoteButtonRow({
    super.key,
    required this.submission,
    required this.challengeId,
    this.votingConfig,
    this.isCompact = false,
    this.showCounts = true,
  });

  @override
  ConsumerState<VoteButtonRow> createState() => _VoteButtonRowState();
}

class _VoteButtonRowState extends ConsumerState<VoteButtonRow>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  VoteType? _currentUserVote;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _loadCurrentUserVote();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Carregar voto atual do usuário
  void _loadCurrentUserVote() async {
    final votingNotifier = ref.read(votingActionProvider.notifier);
    final currentVote = await votingNotifier.getCurrentUserVote(
      widget.submission.id,
    );
    if (mounted) {
      setState(() {
        _currentUserVote = currentVote;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final votingState = ref.watch(votingActionProvider);
    final allowedVoteTypes =
        widget.votingConfig?.allowedVoteTypes ?? VoteType.values;

    return Container(
      padding: EdgeInsets.all(widget.isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(widget.isCompact ? 16 : 20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Botões de votação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: allowedVoteTypes.map((voteType) {
              return _buildVoteButton(context, voteType, votingState.isLoading);
            }).toList(),
          ),

          // Contadores (se habilitado)
          if (widget.showCounts && !widget.isCompact) ...[
            const SizedBox(height: 8),
            _buildVoteCounts(context),
          ],
        ],
      ),
    );
  }

  /// Construir botão individual de voto
  Widget _buildVoteButton(
    BuildContext context,
    VoteType voteType,
    bool isLoading,
  ) {
    final isSelected = _currentUserVote == voteType;
    final voteCount = widget.submission.voteCounts[voteType.id] ?? 0;
    final canVote = _canUserVote();

    return GestureDetector(
      onTap: canVote && !isLoading ? () => _handleVote(voteType) : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: EdgeInsets.all(widget.isCompact ? 8 : 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    voteType.emoji,
                    style: TextStyle(fontSize: widget.isCompact ? 20 : 24),
                  ),
                  if (widget.showCounts) ...[
                    const SizedBox(height: 4),
                    Text(
                      voteCount.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construir contadores de votos
  Widget _buildVoteCounts(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatChip(
          context,
          '${widget.submission.votes}',
          'votos',
          Icons.how_to_vote,
        ),
        _buildStatChip(
          context,
          widget.submission.score.toStringAsFixed(1),
          'pontos',
          Icons.star,
        ),
        if (widget.submission.ranking > 0)
          _buildStatChip(
            context,
            '#${widget.submission.ranking}',
            'posição',
            Icons.emoji_events,
          ),
      ],
    );
  }

  /// Construir chip de estatística
  Widget _buildStatChip(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Verificar se usuário pode votar
  bool _canUserVote() {
    final votingNotifier = ref.read(votingActionProvider.notifier);
    return votingNotifier.canUserVote(
      submissionId: widget.submission.id,
      submissionUserId: widget.submission.userId,
      config: widget.votingConfig,
    );
  }

  /// Lidar com votação
  Future<void> _handleVote(VoteType voteType) async {
    AppLogger.debug('🗳️ Votando: ${voteType.emoji}');

    // Animação de feedback
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final votingNotifier = ref.read(votingActionProvider.notifier);

    final success = await votingNotifier.voteOnSubmission(
      submissionId: widget.submission.id,
      challengeId: widget.challengeId,
      voteType: voteType,
      config: widget.votingConfig,
    );

    if (success) {
      setState(() {
        _currentUserVote = voteType;
      });
    }
  }
}

// ========== VOTE STATS CARD ==========

/// Widget de estatísticas de votação
class VoteStatsCard extends ConsumerWidget {
  final Submission submission;
  final bool isCompact;

  const VoteStatsCard({
    super.key,
    required this.submission,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = submission.votingStats;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.poll,
                  color: Theme.of(context).colorScheme.primary,
                  size: isCompact ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Votação',
                  style:
                      (isCompact
                              ? Theme.of(context).textTheme.titleSmall
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
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
                          'Líder',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Estatísticas principais
            Row(
              children: [
                _buildStatItem(
                  context,
                  submission.votes.toString(),
                  'Total de Votos',
                  Icons.how_to_vote,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  context,
                  submission.score.toStringAsFixed(1),
                  'Pontuação',
                  Icons.star,
                ),
                if (submission.ranking > 0) ...[
                  const SizedBox(width: 16),
                  _buildStatItem(
                    context,
                    '#${submission.ranking}',
                    'Posição',
                    Icons.emoji_events,
                  ),
                ],
              ],
            ),

            if (!isCompact && submission.hasVotes) ...[
              const SizedBox(height: 16),

              // Distribuição dos votos
              Text(
                'Distribuição dos Votos',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              ...VoteType.values.map((voteType) {
                final count = submission.voteCounts[voteType.id] ?? 0;
                final percentage = submission.getVotePercentage(voteType);

                if (count == 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        voteType.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getVoteTypeColor(voteType),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count (${percentage.toStringAsFixed(1)}%)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  /// Construir item de estatística
  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Obter cor do tipo de voto
  Color _getVoteTypeColor(VoteType voteType) {
    switch (voteType) {
      case VoteType.like:
        return Colors.blue;
      case VoteType.love:
        return Colors.red;
      case VoteType.wow:
        return Colors.orange;
      case VoteType.laugh:
        return Colors.green;
      case VoteType.angry:
        return Colors.grey;
    }
  }
}

// ========== VOTING TIMER ==========

/// Widget do timer de votação
class VotingTimer extends StatefulWidget {
  final VotingConfig votingConfig;
  final bool isCompact;

  const VotingTimer({
    super.key,
    required this.votingConfig,
    this.isCompact = false,
  });

  @override
  State<VotingTimer> createState() => _VotingTimerState();
}

class _VotingTimerState extends State<VotingTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeRemaining = widget.votingConfig.timeUntilVotingEnds;

    if (timeRemaining == null || timeRemaining.isNegative) {
      return const SizedBox.shrink();
    }

    final isUrgent = timeRemaining.inHours < 1;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isUrgent ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 8 : 12,
              vertical: widget.isCompact ? 4 : 8,
            ),
            decoration: BoxDecoration(
              color: isUrgent
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(widget.isCompact ? 8 : 12),
              border: Border.all(
                color: isUrgent ? Colors.red : Colors.blue,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUrgent ? Icons.timer : Icons.access_time,
                  size: widget.isCompact ? 16 : 20,
                  color: isUrgent ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(timeRemaining),
                  style:
                      (widget.isCompact
                              ? Theme.of(context).textTheme.bodySmall
                              : Theme.of(context).textTheme.bodyMedium)
                          ?.copyWith(
                            color: isUrgent ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Formatar duração para exibição
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
