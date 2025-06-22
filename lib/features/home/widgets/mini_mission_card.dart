// lib/features/home/widgets/mini_mission_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/features/missions/models/mission.dart';
import 'package:unlock/features/missions/models/user_mission_progress.dart';

/// Versão compacta do MissionCard otimizada para a tela home
/// Mostra apenas informações essenciais com design limpo
class MiniMissionCard extends ConsumerStatefulWidget {
  final Mission mission;
  final UserMissionProgress? progress;
  final VoidCallback? onTap;

  const MiniMissionCard({
    super.key,
    required this.mission,
    this.progress,
    this.onTap,
  });

  @override
  ConsumerState<MiniMissionCard> createState() => _MiniMissionCardState();
}

class _MiniMissionCardState extends ConsumerState<MiniMissionCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = widget.progress?.isCompleted ?? false;
    final isClaimed = widget.progress?.isClaimed ?? false;
    final currentProgress = widget.progress?.currentProgress ?? 0;
    final targetCount = widget.mission.criterion.targetCount;

    final progressValue = targetCount == 0
        ? 1.0
        : (currentProgress / targetCount).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              _hoverController.forward();
              HapticFeedback.lightImpact();
            },
            onTapUp: (_) {
              _hoverController.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () => _hoverController.reverse(),
            child: Card(
              elevation: _elevationAnimation.value,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.cardBorderRadius,
                ),
              ),
              margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppConstants.cardBorderRadius,
                  ),
                  border: isCompleted && !isClaimed
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    // Ícone da missão
                    _buildMissionIcon(theme, isCompleted, isClaimed),

                    const SizedBox(width: AppConstants.spacingLarge),

                    // Conteúdo principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Text(
                            widget.mission.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isClaimed
                                  ? theme.colorScheme.onSurface.withOpacity(0.6)
                                  : theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: AppConstants.spacingSmall),

                          // Progresso
                          Row(
                            children: [
                              Expanded(
                                child: _buildProgressBar(
                                  theme,
                                  progressValue,
                                  isCompleted,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingSmall),
                              Text(
                                '$currentProgress/$targetCount',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppConstants.spacingMedium),

                    // Recompensa resumida e status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildRewardSummary(theme),
                        const SizedBox(height: AppConstants.spacingSmall),
                        _buildStatusIndicator(theme, isCompleted, isClaimed),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissionIcon(ThemeData theme, bool isCompleted, bool isClaimed) {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    if (isClaimed) {
      iconData = Icons.star;
      iconColor = Colors.amber.shade700;
      backgroundColor = Colors.amber.shade100;
    } else if (isCompleted) {
      iconData = Icons.check_circle;
      iconColor = theme.colorScheme.primary;
      backgroundColor = theme.colorScheme.primaryContainer;
    } else {
      iconData = Icons.flag_outlined;
      iconColor = theme.colorScheme.onSurfaceVariant;
      backgroundColor = theme.colorScheme.surfaceVariant;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildProgressBar(
    ThemeData theme,
    double progressValue,
    bool isCompleted,
  ) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: theme.colorScheme.surfaceVariant,
      ),
      child: LinearProgressIndicator(
        value: progressValue,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          isCompleted ? theme.colorScheme.primary : theme.colorScheme.secondary,
        ),
        minHeight: 4,
      ),
    );
  }

  Widget _buildRewardSummary(ThemeData theme) {
    final reward = widget.mission.reward;
    final hasMultipleRewards =
        [
          reward.xp > 0,
          reward.coins > 0,
          reward.gems > 0,
        ].where((has) => has).length >
        1;

    // Se tem múltiplas recompensas, mostrar "+"
    if (hasMultipleRewards) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              size: 12,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 2),
            Text(
              '+',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar a maior recompensa
    String rewardText = '';
    Color rewardColor = theme.colorScheme.primary;
    IconData rewardIcon = Icons.emoji_events;

    if (reward.xp > 0) {
      rewardText = '${reward.xp}';
      rewardColor = const Color(0xFF9C27B0);
      rewardIcon = Icons.trending_up;
    } else if (reward.coins > 0) {
      rewardText = '${reward.coins}';
      rewardColor = const Color(0xFFFFD700);
      rewardIcon = Icons.monetization_on;
    } else if (reward.gems > 0) {
      rewardText = '${reward.gems}';
      rewardColor = const Color(0xFF2196F3);
      rewardIcon = Icons.diamond;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: rewardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(rewardIcon, size: 12, color: rewardColor),
          if (rewardText.isNotEmpty) ...[
            const SizedBox(width: 2),
            Text(
              rewardText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: rewardColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(
    ThemeData theme,
    bool isCompleted,
    bool isClaimed,
  ) {
    if (isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Concluída',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.amber.shade800,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Pronta!',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Mostrar percentual se em progresso
    final currentProgress = widget.progress?.currentProgress ?? 0;
    final targetCount = widget.mission.criterion.targetCount;
    final percentage = targetCount == 0
        ? 100
        : ((currentProgress / targetCount) * 100).round();

    return Text(
      '$percentage%',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
