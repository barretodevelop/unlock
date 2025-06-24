// lib/features/home/widgets/streak_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_colors.dart';
import 'package:unlock/providers/streak_provider.dart';
import 'package:unlock/shared/widgets/currency_display.dart';

/// Widget indicador de streak de login na home screen
class StreakIndicator extends ConsumerWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const StreakIndicator({super.key, this.showDetails = false, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakState = ref.watch(streakProvider);
    final nextMilestone = ref.watch(nextStreakMilestoneProvider);
    final theme = Theme.of(context);

    if (streakState.isLoading) {
      return _LoadingIndicator();
    }

    if (streakState.error != null) {
      return _ErrorIndicator(
        error: streakState.error!,
        onRetry: () => ref.read(streakProvider.notifier).refresh(),
      );
    }

    return GestureDetector(
      onTap: onTap ?? () => _showStreakDetails(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _getStreakGradient(streakState.currentStreak),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone de fogo e streak atual
            Row(
              children: [
                Text(
                      _getStreakEmoji(streakState.currentStreak),
                      style: const TextStyle(fontSize: 24),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                      duration: 1000.ms,
                    ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sequência de Login',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${streakState.currentStreak} ${streakState.currentStreak == 1 ? 'dia' : 'dias'}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status de hoje
                _TodayStatusIndicator(
                  hasLoggedToday: streakState.hasLoggedInToday,
                  hasClaimedReward: streakState.hasClaimedTodaysReward,
                ),
              ],
            ),

            if (showDetails || streakState.currentStreak > 0) ...[
              const SizedBox(height: 16),

              // Progresso para próximo milestone
              if (nextMilestone != null)
                _MilestoneProgress(
                  current: streakState.currentStreak,
                  nextMilestone: nextMilestone,
                ),

              // Longest streak
              if (streakState.longestStreak > streakState.currentStreak)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Recorde: ${streakState.longestStreak} dias 🏆',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  /// Retorna o gradiente baseado no streak atual
  LinearGradient _getStreakGradient(int streak) {
    if (streak >= 30) {
      return const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Dourado
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (streak >= 14) {
      return const LinearGradient(
        colors: [Color(0xFF8E44AD), Color(0xFF9B59B6)], // Roxo
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (streak >= 7) {
      return const LinearGradient(
        colors: [Color(0xFF3498DB), Color(0xFF2980B9)], // Azul
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (streak >= 3) {
      return const LinearGradient(
        colors: [Color(0xFF27AE60), Color(0xFF2ECC71)], // Verde
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.8),
          AppColors.secondary.withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  /// Retorna emoji baseado no streak
  String _getStreakEmoji(int streak) {
    if (streak >= 100) return '🌟';
    if (streak >= 60) return '🏆';
    if (streak >= 30) return '👑';
    if (streak >= 14) return '💎';
    if (streak >= 7) return '⭐';
    if (streak >= 3) return '🔥';
    if (streak >= 1) return '⚡';
    return '💤';
  }

  /// Mostra detalhes do streak em um bottom sheet
  void _showStreakDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StreakDetailsBottomSheet(),
    );
  }
}

/// Indicador do status de hoje
class _TodayStatusIndicator extends StatelessWidget {
  final bool hasLoggedToday;
  final bool hasClaimedReward;

  const _TodayStatusIndicator({
    required this.hasLoggedToday,
    required this.hasClaimedReward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasLoggedToday ? Icons.check_circle : Icons.schedule,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            hasLoggedToday ? 'Hoje ✓' : 'Hoje',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de progresso para próximo milestone
class _MilestoneProgress extends StatelessWidget {
  final int current;
  final StreakMilestone nextMilestone;

  const _MilestoneProgress({
    required this.current,
    required this.nextMilestone,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / nextMilestone.days;
    final remaining = nextMilestone.days - current;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Próximo: ${nextMilestone.emoji} ${nextMilestone.title}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$remaining dias',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// Widget de loading
class _LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Carregando streak...',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de erro
class _ErrorIndicator extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorIndicator({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Erro no streak (toque para tentar novamente)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet com detalhes completos do streak
class _StreakDetailsBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakState = ref.watch(streakProvider);
    final nextMilestone = ref.watch(nextStreakMilestoneProvider);
    final currentMilestone = StreakMilestone.getCurrentMilestone(
      streakState.currentStreak,
    );
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Sequência de Login',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Current streak display
          _CurrentStreakDisplay(
            streak: streakState.currentStreak,
            longestStreak: streakState.longestStreak,
            hasLoggedToday: streakState.hasLoggedInToday,
          ),
          const SizedBox(height: 24),

          // Current milestone
          if (currentMilestone != null) ...[
            _MilestoneCard(
              milestone: currentMilestone,
              isUnlocked: true,
              title: 'Conquista Atual',
            ),
            const SizedBox(height: 16),
          ],

          // Next milestone
          if (nextMilestone != null) ...[
            _MilestoneCard(
              milestone: nextMilestone,
              isUnlocked: false,
              title: 'Próxima Conquista',
              progress: streakState.currentStreak / nextMilestone.days,
            ),
            const SizedBox(height: 24),
          ],

          // All milestones
          Text(
            'Todas as Conquistas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _MilestonesList(currentStreak: streakState.currentStreak),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Display do streak atual
class _CurrentStreakDisplay extends StatelessWidget {
  final int streak;
  final int longestStreak;
  final bool hasLoggedToday;

  const _CurrentStreakDisplay({
    required this.streak,
    required this.longestStreak,
    required this.hasLoggedToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Streak counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sequência Atual',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '$streak',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  streak == 1 ? 'dia' : 'dias',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 60,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(width: 20),

          // Record
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recorde',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  '$longestStreak',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      longestStreak == 1 ? 'dia' : 'dias',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (longestStreak > streak) ...[
                      const SizedBox(width: 4),
                      const Text('🏆', style: TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card individual de milestone
class _MilestoneCard extends StatelessWidget {
  final StreakMilestone milestone;
  final bool isUnlocked;
  final String title;
  final double? progress;

  const _MilestoneCard({
    required this.milestone,
    required this.isUnlocked,
    required this.title,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.success.withOpacity(0.1)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? AppColors.success.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(milestone.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isUnlocked
                            ? AppColors.success
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      milestone.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? AppColors.success
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      milestone.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Reward
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${milestone.reward}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar se não está desbloqueado
          if (!isUnlocked && progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress! * 100).toInt()}% completo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lista de todos os milestones
class _MilestonesList extends StatelessWidget {
  final int currentStreak;

  const _MilestonesList({required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: StreakMilestone.milestones.map((milestone) {
        final isUnlocked = currentStreak >= milestone.days;
        final progress = currentStreak < milestone.days
            ? currentStreak / milestone.days
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _MilestoneListItem(
            milestone: milestone,
            isUnlocked: isUnlocked,
            progress: progress,
          ),
        );
      }).toList(),
    );
  }
}

/// Item individual na lista de milestones
class _MilestoneListItem extends StatelessWidget {
  final StreakMilestone milestone;
  final bool isUnlocked;
  final double? progress;

  const _MilestoneListItem({
    required this.milestone,
    required this.isUnlocked,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.success.withOpacity(0.05)
            : theme.colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            milestone.emoji,
            // style: TextStyle(fontSize: 20, opacity: isUnlocked ? 1.0 : 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${milestone.title} • ${milestone.days} dias',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isUnlocked
                        ? AppColors.success
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (progress != null)
                  Text(
                    '${(progress! * 100).toInt()}% completo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          // Reward and status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '💰${milestone.reward}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isUnlocked ? Icons.check_circle : Icons.lock_outline,
                color: isUnlocked
                    ? AppColors.success
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
