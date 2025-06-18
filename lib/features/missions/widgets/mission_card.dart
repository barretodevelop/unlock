// lib/features/missions/widgets/mission_card.dart
// Card individual para exibir missões - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/core/theme/app_theme.dart';

/// Card para exibir uma missão individual
class MissionCard extends ConsumerWidget {
  final MissionModel mission;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool isCompact;

  const MissionCard({
    super.key,
    required this.mission,
    this.onTap,
    this.showProgress = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final missionsState = ref.watch(missionsProvider);
    final progress = missionsState.getMissionProgress(mission.id);
    final isCompleted = progress >= 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isCompleted ? 2 : 4,
        shadowColor: theme.colorScheme.shadow.withOpacity(isCompleted ? 0.1 : 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _buildCardGradient(theme, isCompleted),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.successColor.withOpacity(0.3)
                  : Color(mission.difficultyColor).withOpacity(0.2),
              width: isCompleted ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: isCompact
                ? _buildCompactContent(context, theme, progress, isCompleted)
                : _buildFullContent(context, theme, progress, isCompleted),
          ),
        ),
      ),
    );
  }

  /// Construir gradiente do card
  LinearGradient _buildCardGradient(ThemeData theme, bool isCompleted) {
    if (isCompleted) {
      return LinearGradient(
        colors: [
          AppTheme.successColor.withOpacity(0.1),
          AppTheme.successColor.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return LinearGradient(
      colors: [
        theme.colorScheme.surface,
        Color(mission.difficultyColor).withOpacity(0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Construir conteúdo compacto
  Widget _buildCompactContent(
    BuildContext context,
    ThemeData theme,
    double progress,
    bool isCompleted,
  ) {
    return Row(
      children: [
        // Ícone da categoria
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(mission.difficultyColor).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            mission.categoryIcon,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Conteúdo principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                mission.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? AppTheme.successColor
                      : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Tipo e dificuldade
              Row(
                children: [
                  _buildChip(theme, mission.type.displayName, Color(mission.difficultyColor)),
                  const SizedBox(width: 8),
                  _buildChip(theme, mission.difficultyText, theme.colorScheme.outline),
                ],
              ),
            ],
          ),
        ),
        
        // Status/Progresso
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isCompleted)
              Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 24,
              )
            else ...[
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Color(mission.difficultyColor),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              _buildRewardChips(theme),
            ],
          ],
        ),
      ],
    );
  }

  /// Construir conteúdo completo
  Widget _buildFullContent(
    BuildContext context,
    ThemeData theme,
    double progress,
    bool isCompleted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header do card
        _buildHeader(context, theme, isCompleted),
        
        const SizedBox(height: 12),
        
        // Descrição
        Text(
          mission.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 16),
        
        // Footer com progresso e recompensas
        _buildFooter(context, theme, progress, isCompleted),
      ],
    );
  }

  /// Construir header do card
  Widget _buildHeader(BuildContext context, ThemeData theme, bool isCompleted) {
    return Row(
      children: [
        // Ícone da categoria
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(mission.difficultyColor).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            mission.categoryIcon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Título e badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mission.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCompleted
                      ? AppTheme.successColor
                      : theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 6),
              
              // Badges de tipo, dificuldade e tempo
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChip(theme, mission.type.displayName, Color(mission.difficultyColor)),
                  _buildChip(theme, mission.difficultyText, theme.colorScheme.outline),
                  if (mission.hoursRemaining > 0)
                    _buildChip(
                      theme,
                      '${mission.hoursRemaining}h restantes',
                      AppTheme.warningColor,
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Status icon
        if (isCompleted)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: AppTheme.successColor,
              size: 20,
            ),
          )
        else if (mission.isExpired)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: AppTheme.errorColor,
              size: 20,
            ),
          ),
      ],
    );
  }

  /// Construir footer do card
  Widget _buildFooter(
    BuildContext context,
    ThemeData theme,
    double progress,
    bool isCompleted,
  ) {
    return Column(
      children: [
        // Barra de progresso
        if (showProgress && !isCompleted) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Color(mission.difficultyColor),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(Color(mission.difficultyColor)),
            minHeight: 6,
          ),
          
          const SizedBox(height: 12),
        ],
        
        // Recompensas e ações
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Recompensas
            Expanded(
              child: _buildRewardsList(theme),
            ),
            
            // Botão de ação
            if (!isCompleted && !mission.isExpired)
              _buildActionButton(context, theme),
          ],
        ),
      ],
    );
  }

  /// Construir chip informativo
  Widget _buildChip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Construir chips de recompensa (versão compacta)
  Widget _buildRewardChips(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mission.xpReward > 0) ...[
          Text('⚡', style: const TextStyle(fontSize: 10)),
          Text(
            '${mission.xpReward}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.xpColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (mission.coinsReward > 0) ...[
          if (mission.xpReward > 0) const SizedBox(width: 4),
          Text('🪙', style: const TextStyle(fontSize: 10)),
          Text(
            '${mission.coinsReward}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.coinsColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  /// Construir lista de recompensas
  Widget _buildRewardsList(ThemeData theme) {
    final rewards = <Widget>[];

    if (mission.xpReward > 0) {
      rewards.add(_buildRewardItem(
        theme,
        '⚡',
        '${mission.xpReward} XP',
        AppTheme.xpColor,
      ));
    }

    if (mission.coinsReward > 0) {
      rewards.add(_buildRewardItem(
        theme,
        '🪙',
        '${mission.coinsReward} Coins',
        AppTheme.coinsColor,
      ));
    }

    if (mission.gemsReward > 0) {
      rewards.add(_buildRewardItem(
        theme,
        '💎',
        '${mission.gemsReward} Gems',
        AppTheme.gemsColor,
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: rewards,
    );
  }

  /// Construir item de recompensa
  Widget _buildRewardItem(
    ThemeData theme,
    String icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir botão de ação
  Widget _buildActionButton(BuildContext context, ThemeData theme) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(mission.difficultyColor),
        side: BorderSide(
          color: Color(mission.difficultyColor).withOpacity(0.5),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        'Ver Detalhes',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Card de missão para loading/skeleton
class MissionCardSkeleton extends StatelessWidget {
  final bool isCompact;

  const MissionCardSkeleton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
        ),
        child: isCompact
            ? _buildCompactSkeleton(theme)
            : _buildFullSkeleton(theme),
      ),
    );
  }

  Widget _buildCompactSkeleton(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildFullSkeleton(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 18,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 14,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 14,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 200,
          height: 14,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}