// lib/features/profile/widgets/profile_stats.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/user_model.dart';

/// Widget para exibir estatísticas detalhadas do perfil
class ProfileStats extends StatelessWidget {
  final UserModel user;
  final bool isAnimated;
  final VoidCallback? onXpTap;
  final VoidCallback? onCoinsTap;
  final VoidCallback? onGemsTap;
  final VoidCallback? onLevelTap;

  const ProfileStats({
    super.key,
    required this.user,
    this.isAnimated = false,
    this.onXpTap,
    this.onCoinsTap,
    this.onGemsTap,
    this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          Text(
            'Estatísticas',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // Grid de estatísticas
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.military_tech,
                  label: 'Level',
                  value: user.level.toString(),
                  color: const Color(0xFF4CAF50),
                  onTap: onLevelTap,
                  isAnimated: isAnimated,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.auto_awesome,
                  label: 'XP',
                  value: _formatNumber(user.xp),
                  color: const Color(0xFF9C27B0),
                  onTap: onXpTap,
                  isAnimated: isAnimated,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.monetization_on,
                  label: 'Coins',
                  value: _formatNumber(user.coins),
                  color: const Color(0xFFFF9800),
                  onTap: onCoinsTap,
                  isAnimated: isAnimated,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.diamond,
                  label: 'Gems',
                  value: _formatNumber(user.gems),
                  color: const Color(0xFF00BCD4),
                  onTap: onGemsTap,
                  isAnimated: isAnimated,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Card individual de estatística
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final bool isAnimated;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Ícone
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(height: 12),

          // Valor
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 4),

          // Label
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    // Animação se solicitada
    if (isAnimated) {
      cardContent = TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: cardContent,
      );
    }

    // Tornar clicável se onTap fornecido
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Widget de progresso de nível
class LevelProgressWidget extends StatelessWidget {
  final UserModel user;
  final double progressToNextLevel;
  final int xpNeededForNextLevel;

  const LevelProgressWidget({
    super.key,
    required this.user,
    required this.progressToNextLevel,
    required this.xpNeededForNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso para Level ${user.level + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progressToNextLevel * 100).toInt()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Barra de progresso
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                height: 8,
                width: MediaQuery.of(context).size.width * progressToNextLevel,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Informação de XP necessário
          Text(
            'Faltam $xpNeededForNextLevel XP para o próximo level',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estatísticas compactas para usar em outros locais
class CompactStats extends StatelessWidget {
  final UserModel user;
  final bool showLevel;

  const CompactStats({super.key, required this.user, this.showLevel = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLevel) ...[
            _CompactStatItem(
              icon: Icons.military_tech,
              value: user.level.toString(),
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 12),
          ],
          _CompactStatItem(
            icon: Icons.auto_awesome,
            value: _formatNumber(user.xp),
            color: const Color(0xFF9C27B0),
          ),
          const SizedBox(width: 12),
          _CompactStatItem(
            icon: Icons.monetization_on,
            value: _formatNumber(user.coins),
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(width: 12),
          _CompactStatItem(
            icon: Icons.diamond,
            value: _formatNumber(user.gems),
            color: const Color(0xFF00BCD4),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _CompactStatItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Widget para mostrar estatísticas em lista vertical
class VerticalStats extends StatelessWidget {
  final UserModel user;
  final bool showDividers;

  const VerticalStats({
    super.key,
    required this.user,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _VerticalStatItem(
            icon: Icons.military_tech,
            label: 'Level',
            value: user.level.toString(),
            color: const Color(0xFF4CAF50),
          ),
          if (showDividers) const Divider(height: 1),
          _VerticalStatItem(
            icon: Icons.auto_awesome,
            label: 'Experience',
            value: '${_formatNumber(user.xp)} XP',
            color: const Color(0xFF9C27B0),
          ),
          if (showDividers) const Divider(height: 1),
          _VerticalStatItem(
            icon: Icons.monetization_on,
            label: 'Coins',
            value: _formatNumber(user.coins),
            color: const Color(0xFFFF9800),
          ),
          if (showDividers) const Divider(height: 1),
          _VerticalStatItem(
            icon: Icons.diamond,
            label: 'Gems',
            value: _formatNumber(user.gems),
            color: const Color(0xFF00BCD4),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _VerticalStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _VerticalStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
