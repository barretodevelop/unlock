// lib/features/home/widgets/missions_preview_card.dart
// Card de preview das missões na home - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/features/home/providers/home_provider.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';

/// Card de preview das missões na tela home
class MissionsPreviewCard extends ConsumerWidget {
  const MissionsPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final missionsState = ref.watch(missionsProvider);
    final featuredMissions = ref.watch(featuredMissionsProvider);
    final activeMissions = ref.watch(activeMissionsProvider);

    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do card
              _buildHeader(context, theme, activeMissions.length),
              
              const SizedBox(height: 16),
              
              // Lista de missões em destaque
              if (missionsState.isLoading)
                _buildLoadingState(context, theme)
              else if (activeMissions.isEmpty)
                _buildEmptyState(context, theme)
              else
                _buildMissionsList(context, theme, ref, featuredMissions, missionsState),
              
              const SizedBox(height: 16),
              
              // Botão para ver todas as missões
              _buildViewAllButton(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  /// Construir header do card
  Widget _buildHeader(BuildContext context, ThemeData theme, int activeMissionsCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suas Missões',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '$activeMissionsCount ativas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (activeMissionsCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Em Progresso',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// Construir estado de carregamento
  Widget _buildLoadingState(BuildContext context, ThemeData theme) {
    return Column(
      children: List.generate(3, (index) => 
        Container(
          margin: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
          child: _buildMissionSkeleton(theme),
        ),
      ),
    );
  }

  /// Construir skeleton de missão
  Widget _buildMissionSkeleton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
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
            width: 200,
            height: 12,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 100,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Construir estado vazio
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma missão disponível',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Novas missões serão geradas em breve!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construir lista de missões
  Widget _buildMissionsList(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    List<String> featuredMissionIds,
    MissionsState missionsState,
  ) {
    // Obter as missões em destaque ou as primeiras 3 ativas
    final missionsToShow = featuredMissionIds.isNotEmpty
        ? featuredMissionIds
            .map((id) => missionsState.allMissions.firstWhere(
                (m) => m.id == id,
                orElse: () => missionsState.allMissions.first,
              ))
            .take(3)
            .toList()
        : missionsState.activeMissions.take(3).toList();

    return Column(
      children: missionsToShow.asMap().entries.map((entry) {
        final index = entry.key;
        final mission = entry.value;
        final progress = missionsState.getMissionProgress(mission.id);
        
        return Container(
          margin: EdgeInsets.only(bottom: index < missionsToShow.length - 1 ? 12 : 0),
          child: _buildMissionItem(context, theme, ref, mission, progress),
        );
      }).toList(),
    );
  }

  /// Construir item de missão
  Widget _buildMissionItem(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    MissionModel mission,
    double progress,
  ) {
    final isCompleted = progress >= 1.0;
    final progressPercentage = (progress * 100).round();

    return GestureDetector(
      onTap: () => _onMissionTap(context, mission),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppTheme.successColor.withOpacity(0.1)
              : theme.colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? AppTheme.successColor.withOpacity(0.3)
                : theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header da missão
            Row(
              children: [
                // Ícone da categoria
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(mission.difficultyColor).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mission.categoryIcon,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Título e tipo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            mission.type.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Color(mission.difficultyColor),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(' • '),
                          Text(
                            mission.difficultyText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status/Recompensas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isCompleted)
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                        size: 20,
                      )
                    else
                      Text(
                        '$progressPercentage%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Color(mission.difficultyColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (mission.xpReward > 0) ...[
                          Text(
                            '⚡',
                            style: const TextStyle(fontSize: 10),
                          ),
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
                          Text(
                            '🪙',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            '${mission.coinsReward}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.coinsColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Barra de progresso
            if (!isCompleted) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(Color(mission.difficultyColor)),
                minHeight: 4,
              ),
              const SizedBox(height: 8),
              Text(
                mission.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.celebration,
                      size: 16,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Missão Completada!',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construir botão para ver todas as missões
  Widget _buildViewAllButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _onViewAllMissions(context),
        icon: Icon(
          Icons.arrow_forward,
          size: 18,
          color: AppTheme.primaryColor,
        ),
        label: Text(
          'Ver Todas as Missões',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          side: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Ação ao tocar em uma missão
  void _onMissionTap(BuildContext context, MissionModel mission) {
    // Navegar para detalhes da missão
    // Navigator.pushNamed(context, '/mission/detail', arguments: mission);
    
    // Por ora, mostrar informações em bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Título da missão
            Text(
              mission.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            
            // Descrição
            Text(
              mission.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Informações da missão
            Row(
              children: [
                Chip(
                  label: Text(mission.type.displayName),
                  backgroundColor: Color(mission.difficultyColor).withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(mission.difficultyText),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botão fechar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ação para ver todas as missões
  void _onViewAllMissions(BuildContext context) {
    // Navegar para tela de missões
    // Navigator.pushNamed(context, '/missions');
    
    // Por ora, placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegação para tela de missões será implementada'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}