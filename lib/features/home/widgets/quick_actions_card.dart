// lib/features/home/widgets/quick_actions_card.dart
// Card com ações rápidas na home - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/features/home/providers/home_provider.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';

/// Card com ações rápidas que o usuário pode executar
class QuickActionsCard extends ConsumerWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quickActions = ref.watch(quickActionsProvider);
    final hasPendingRewards = ref.watch(hasPendingRewardsProvider);

    if (quickActions.isEmpty) {
      return const SizedBox.shrink();
    }

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
              AppTheme.secondaryColor.withOpacity(0.1),
              AppTheme.accentColor.withOpacity(0.05),
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
              _buildHeader(context, theme),
              
              const SizedBox(height: 16),
              
              // Grid de ações
              _buildActionsGrid(context, theme, ref, quickActions, hasPendingRewards),
            ],
          ),
        ),
      ),
    );
  }

  /// Construir header do card
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.flash_on,
            color: AppTheme.secondaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações Rápidas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'O que você gostaria de fazer?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construir grid de ações
  Widget _buildActionsGrid(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    Map<String, dynamic> quickActions,
    bool hasPendingRewards,
  ) {
    final actions = quickActions.entries.toList();
    
    // Organizar ações em grid responsivo
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 300 ? 2 : 1;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final actionEntry = actions[index];
            final actionId = actionEntry.key;
            final actionData = actionEntry.value as Map<String, dynamic>;
            
            return _buildActionItem(
              context,
              theme,
              ref,
              actionId,
              actionData,
              hasPendingRewards && actionId == 'claim_rewards',
            );
          },
        );
      },
    );
  }

  /// Construir item de ação individual
  Widget _buildActionItem(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    String actionId,
    Map<String, dynamic> actionData,
    bool hasSpecialEffect,
  ) {
    final title = actionData['title'] as String? ?? 'Ação';
    final description = actionData['description'] as String? ?? '';
    final icon = actionData['icon'] as String? ?? '⚡';
    final enabled = actionData['enabled'] as bool? ?? true;
    final badge = actionData['badge'] as int?;
    final route = actionData['route'] as String?;

    return GestureDetector(
      onTap: enabled ? () => _onActionTap(context, ref, actionId, route) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled
              ? theme.colorScheme.surface.withOpacity(0.8)
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSpecialEffect
                ? AppTheme.errorColor.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.2),
            width: hasSpecialEffect ? 2 : 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: hasSpecialEffect
                        ? AppTheme.errorColor.withOpacity(0.2)
                        : theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: hasSpecialEffect ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Conteúdo principal
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone e título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getActionColor(actionId).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: enabled
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: enabled
                                    ? theme.colorScheme.onSurface.withOpacity(0.7)
                                    : theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Badge de notificação
            if (badge != null && badge > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  // min: 20,
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.errorColor.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badge > 99 ? '99+' : badge.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Efeito de pulso para ações especiais
            if (hasSpecialEffect)
              Positioned.fill(
                child: _buildPulseEffect(theme),
              ),
            
            // Overlay de desabilitado
            if (!enabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline,
                      size: 24,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construir efeito de pulso
  Widget _buildPulseEffect(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.errorColor.withOpacity(0.3 * (1 - value)),
              width: 2 + (value * 4),
            ),
          ),
        );
      },
      onEnd: () {
        // Reiniciar animação
        Future.delayed(const Duration(milliseconds: 500), () {
          // Trigger rebuild para reiniciar animação
        });
      },
    );
  }

  /// Obter cor da ação baseada no ID
  Color _getActionColor(String actionId) {
    switch (actionId) {
      case 'find_connections':
        return AppTheme.primaryColor;
      case 'complete_profile':
        return AppTheme.warningColor;
      case 'claim_rewards':
        return AppTheme.errorColor;
      case 'visit_shop':
        return AppTheme.successColor;
      case 'daily_mission':
        return AppTheme.infoColor;
      default:
        return AppTheme.secondaryColor;
    }
  }

  /// Ação ao tocar em uma ação rápida
  void _onActionTap(
    BuildContext context,
    WidgetRef ref,
    String actionId,
    String? route,
  ) {
    // Feedback haptic
    // HapticFeedback.lightImpact();

    // Executar ação baseada no ID
    switch (actionId) {
      case 'claim_rewards':
        _claimAllRewards(context, ref);
        break;
      case 'refresh_missions':
        _refreshMissions(context, ref);
        break;
      case 'find_connections':
      case 'complete_profile':
      case 'visit_shop':
        _navigateToRoute(context, route);
        break;
      default:
        _showActionNotImplemented(context, actionId);
    }
  }

  /// Coletar todas as recompensas
  void _claimAllRewards(BuildContext context, WidgetRef ref) {
    ref.read(homeProvider.notifier).executeQuickAction('claim_rewards');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text('Coletando todas as recompensas...'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Atualizar missões
  void _refreshMissions(BuildContext context, WidgetRef ref) {
    ref.read(homeProvider.notifier).executeQuickAction('refresh_missions');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Atualizando missões...'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Navegar para rota
  void _navigateToRoute(BuildContext context, String? route) {
    if (route != null) {
      // Navigator.pushNamed(context, route);
      
      // Por ora, mostrar placeholder
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navegação para $route será implementada'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Mostrar ação não implementada
  void _showActionNotImplemented(BuildContext context, String actionId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ação "$actionId" será implementada em breve'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Widget para ações rápidas em formato horizontal
class QuickActionsRow extends ConsumerWidget {
  final int maxActions;

  const QuickActionsRow({
    super.key,
    this.maxActions = 4,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quickActions = ref.watch(quickActionsProvider);

    if (quickActions.isEmpty) {
      return const SizedBox.shrink();
    }

    final actions = quickActions.entries.take(maxActions).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: actions.asMap().entries.map((entry) {
          final index = entry.key;
          final actionEntry = entry.value;
          final actionId = actionEntry.key;
          final actionData = actionEntry.value as Map<String, dynamic>;

          return Container(
            margin: EdgeInsets.only(right: index < actions.length - 1 ? 12 : 0),
            child: _buildHorizontalActionItem(
              context,
              theme,
              ref,
              actionId,
              actionData,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Construir item de ação horizontal
  Widget _buildHorizontalActionItem(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    String actionId,
    Map<String, dynamic> actionData,
  ) {
    final title = actionData['title'] as String? ?? 'Ação';
    final icon = actionData['icon'] as String? ?? '⚡';
    final enabled = actionData['enabled'] as bool? ?? true;
    final badge = actionData['badge'] as int?;

    return GestureDetector(
      onTap: enabled ? () => _onActionTap(context, ref, actionId) : null,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
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
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getActionColor(actionId).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (badge != null && badge > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge > 9 ? '9+' : badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Obter cor da ação
  Color _getActionColor(String actionId) {
    switch (actionId) {
      case 'find_connections':
        return AppTheme.primaryColor;
      case 'complete_profile':
        return AppTheme.warningColor;
      case 'claim_rewards':
        return AppTheme.errorColor;
      case 'visit_shop':
        return AppTheme.successColor;
      default:
        return AppTheme.secondaryColor;
    }
  }

  /// Ação ao tocar (versão simplificada)
  void _onActionTap(BuildContext context, WidgetRef ref, String actionId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ação "$actionId" executada'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}