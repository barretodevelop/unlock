// lib/features/voting/widgets/voting_notification_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/models/vote_model.dart';
import 'package:unlock/providers/voting_provider.dart';

// ========== VOTING BANNER ==========

/// Banner de notificação para período de votação
class VotingBanner extends StatefulWidget {
  final Challenge challenge;
  final VoidCallback? onTap;
  final bool canDismiss;

  const VotingBanner({
    super.key,
    required this.challenge,
    this.onTap,
    this.canDismiss = true,
  });

  @override
  State<VotingBanner> createState() => _VotingBannerState();
}

class _VotingBannerState extends State<VotingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Repetir animação de brilho
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _animationController.reverse();
        });
      } else if (status == AnimationStatus.dismissed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _animationController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _slideAnimation.value * MediaQuery.of(context).size.width,
            0,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(_glowAnimation.value * 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Ícone animado
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.how_to_vote,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Conteúdo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🗳️ Votação Ativa!',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.challenge.title,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _buildTimeRemaining(context),
                          ],
                        ),
                      ),

                      // Botão de dispensar
                      if (widget.canDismiss)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isDismissed = true;
                            });
                          },
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeRemaining(BuildContext context) {
    final timeRemaining = widget.challenge.timeUntilVotingEnds;

    if (timeRemaining == null) {
      return const SizedBox.shrink();
    }

    final isUrgent = timeRemaining.inHours < 2;

    return Row(
      children: [
        Icon(
          isUrgent ? Icons.timer : Icons.access_time,
          color: Colors.white.withOpacity(0.8),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDuration(timeRemaining),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isUrgent) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300, width: 1),
            ),
            child: Text(
              'URGENTE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h restantes';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m restantes';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m restantes';
    } else {
      return '${duration.inSeconds}s restantes';
    }
  }
}

// ========== VOTING STATISTICS WIDGET ==========

/// Widget de estatísticas de votação em tempo real
class VotingStatisticsWidget extends ConsumerWidget {
  final String challengeId;
  final bool isCompact;

  const VotingStatisticsWidget({
    super.key,
    required this.challengeId,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(votingRankingProvider(challengeId));

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
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: isCompact ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas da Votação',
                  style:
                      (isCompact
                              ? Theme.of(context).textTheme.titleSmall
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildRefreshButton(context, ref),
              ],
            ),

            const SizedBox(height: 16),

            // Estatísticas
            rankingAsync.when(
              data: (rankings) => _buildStatistics(context, rankings),
              loading: () => _buildLoadingStats(context),
              error: (error, stack) => _buildErrorStats(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, List<VotingStats> rankings) {
    if (rankings.isEmpty) {
      return _buildEmptyStats(context);
    }

    final totalVotes = rankings.fold<int>(
      0,
      (sum, stats) => sum + stats.totalVotes,
    );
    final totalSubmissions = rankings.length;
    final leadingSubmission = rankings.first;
    final avgVotes = totalSubmissions > 0
        ? (totalVotes / totalSubmissions)
        : 0.0;

    return Column(
      children: [
        // Estatísticas principais
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                totalSubmissions.toString(),
                'Submissões',
                Icons.file_present,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                totalVotes.toString(),
                'Votos',
                Icons.how_to_vote,
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                avgVotes.toStringAsFixed(1),
                'Média/Sub',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                leadingSubmission.score.toStringAsFixed(1),
                'Melhor Score',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),

        if (!isCompact) ...[
          const SizedBox(height: 16),

          // Top 3 rápido
          Text(
            'Top 3 Atual',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ...rankings
              .take(3)
              .map((stats) => _buildQuickRankItem(context, stats)),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRankItem(BuildContext context, VotingStats stats) {
    final medal = stats.ranking == 1
        ? '🥇'
        : stats.ranking == 2
        ? '🥈'
        : '🥉';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Submissão ${stats.submissionId.substring(0, 8)}...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            '${stats.totalVotes} votos',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () {
        ref.refresh(votingRankingProvider(challengeId));
        AppLogger.debug('🔄 Atualizando estatísticas de votação');
      },
      icon: Icon(
        Icons.refresh,
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildLoadingStats(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSkeletonCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSkeletonCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildEmptyStats(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Aguardando primeiros votos...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStats(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Erro ao carregar estatísticas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== VOTING PHASE INDICATOR ==========

/// Indicador da fase atual do desafio
class VotingPhaseIndicator extends StatelessWidget {
  final Challenge challenge;
  final bool isVertical;

  const VotingPhaseIndicator({
    super.key,
    required this.challenge,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final phases = _getPhases();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fases do Desafio',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (isVertical)
            Column(
              children: phases
                  .map((phase) => _buildPhaseItem(context, phase))
                  .toList(),
            )
          else
            Row(
              children: phases
                  .map(
                    (phase) => Expanded(child: _buildPhaseItem(context, phase)),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  List<_PhaseInfo> _getPhases() {
    final now = DateTime.now();

    return [
      _PhaseInfo(
        'Submissões',
        Icons.upload,
        challenge.startsAt,
        challenge.effectiveSubmissionEnd,
        now.isBefore(challenge.effectiveSubmissionEnd) &&
            now.isAfter(challenge.startsAt),
        challenge.isSubmissionPeriod,
      ),
      if (challenge.hasVoting)
        _PhaseInfo(
          'Votação',
          Icons.how_to_vote,
          challenge.votingConfig?.votingStartsAt ??
              challenge.effectiveSubmissionEnd,
          challenge.votingConfig?.votingEndsAt ?? challenge.endsAt,
          challenge.isInVotingPeriod,
          challenge.status == ChallengeStatus.voting,
        ),
      _PhaseInfo(
        'Resultados',
        Icons.emoji_events,
        challenge.endsAt,
        null,
        challenge.status == ChallengeStatus.completed,
        false,
      ),
    ];
  }

  Widget _buildPhaseItem(BuildContext context, _PhaseInfo phase) {
    final isActive = phase.isActive;
    final isCompleted = phase.isCompleted;

    Color color;
    if (isCompleted) {
      color = Colors.green;
    } else if (isActive) {
      color = Theme.of(context).colorScheme.primary;
    } else {
      color = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : phase.icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (phase.endTime != null)
                  Text(
                    _formatPhaseTime(phase.endTime!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          if (isActive)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  String _formatPhaseTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (difference.isNegative) {
      return 'Finalizada';
    }

    if (difference.inDays > 0) {
      return 'em ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'em ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'em ${difference.inMinutes}m';
    } else {
      return 'agora';
    }
  }
}

class _PhaseInfo {
  final String name;
  final IconData icon;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final bool isCompleted;

  const _PhaseInfo(
    this.name,
    this.icon,
    this.startTime,
    this.endTime,
    this.isActive,
    this.isCompleted,
  );
}
