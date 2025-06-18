// lib/features/home/widgets/user_info_card.dart
// Card com informações do usuário na home - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/home/providers/home_provider.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/core/utils/level_calculator.dart';

/// Card principal com informações do usuário na home
class UserInfoCard extends ConsumerWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final userLevelInfo = ref.watch(userLevelInfoProvider);

    if (!authState.isAuthenticated || authState.user == null) {
      return const SizedBox.shrink();
    }

    final user = authState.user!;
    final userStats = homeState.userStats;

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
              theme.colorScheme.primaryContainer.withOpacity(0.8),
              theme.colorScheme.secondaryContainer.withOpacity(0.6),
              theme.colorScheme.tertiaryContainer.withOpacity(0.4),
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
              // Header com saudação e avatar
              _buildHeader(context, theme, user, userStats),
              
              const SizedBox(height: 20),
              
              // Seção de progresso de nível
              _buildLevelSection(context, theme, userLevelInfo),
              
              const SizedBox(height: 16),
              
              // Estatísticas rápidas
              _buildQuickStats(context, theme, user, userStats),
            ],
          ),
        ),
      ),
    );
  }

  /// Construir header do card
  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    user,
    Map<String, dynamic> userStats,
  ) {
    final title = userStats['title'] ?? 'Novato';
    final level = userStats['level'] ?? 1;
    
    return Row(
      children: [
        // Avatar grande
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: user.avatar?.isNotEmpty == true
                ? (user.avatar!.startsWith('http')
                    ? Image.network(
                        user.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(theme),
                      )
                    : _buildEmojiAvatar(user.avatar!, theme))
                : _buildAvatarFallback(theme),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Informações do usuário
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saudação personalizada
              Text(
                _getGreeting(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Nome do usuário
              Text(
                user.codinome?.isNotEmpty == true 
                    ? user.codinome! 
                    : user.displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 6),
              
              // Título e nível
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$title • Nv $level',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir seção de progresso de nível
  Widget _buildLevelSection(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> userLevelInfo,
  ) {
    final level = userLevelInfo['level'] ?? 1;
    final progress = userLevelInfo['progress'] ?? 0.0;
    final xpToNext = userLevelInfo['xpToNext'] ?? 0;
    final canLevelUp = userLevelInfo['canLevelUp'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da seção
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: AppTheme.xpColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Progresso no Nível',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (canLevelUp)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PODE EVOLUIR!',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Barra de progresso
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nível $level',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    xpToNext > 0 
                        ? 'Faltam ${LevelCalculator.formatXP(xpToNext)} XP'
                        : 'Nível máximo!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.xpColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.xpColor,
                            AppTheme.xpColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.xpColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.xpColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (xpToNext > 0)
                    Text(
                      'Nível ${level + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir estatísticas rápidas
  Widget _buildQuickStats(
    BuildContext context,
    ThemeData theme,
    user,
    Map<String, dynamic> userStats,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            theme,
            '🎯',
            'Missões Hoje',
            '0/3', // Será conectado com missions provider
            AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: _buildStatItem(
            context,
            theme,
            '🔥',
            'Sequência',
            '1 dia', // Será conectado com streak do usuário
            AppTheme.warningColor,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: _buildStatItem(
            context,
            theme,
            '👥',
            'Conexões',
            '0', // Será conectado com connections
            AppTheme.secondaryColor,
          ),
        ),
      ],
    );
  }

  /// Construir item de estatística
  Widget _buildStatItem(
    BuildContext context,
    ThemeData theme,
    String icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          
          const SizedBox(height: 6),
          
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 2),
          
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Avatar emoji
  Widget _buildEmojiAvatar(String emoji, ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 30),
        ),
      ),
    );
  }

  /// Avatar fallback
  Widget _buildAvatarFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        color: theme.colorScheme.onPrimaryContainer,
        size: 30,
      ),
    );
  }

  /// Obter saudação baseada no horário
  String _getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 6) {
      return 'Boa madrugada! 🌙';
    } else if (hour < 12) {
      return 'Bom dia! ☀️';
    } else if (hour < 18) {
      return 'Boa tarde! 🌤️';
    } else {
      return 'Boa noite! 🌆';
    }
  }
}