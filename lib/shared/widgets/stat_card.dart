// lib/shared/widgets/stat_card.dart
import 'package:flutter/material.dart';

/// Widget para exibir estatísticas do usuário (XP, Coins, Gems)
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool isAnimated;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.isAnimated = false,
  });

  /// Construtor para XP
  const StatCard.xp({
    super.key,
    required String value,
    this.onTap,
    this.isAnimated = false,
  }) : value = value,
       icon = Icons.auto_awesome,
       label = 'XP',
       iconColor = const Color(0xFF9C27B0), // Purple
       backgroundColor = null;

  /// Construtor para Coins
  const StatCard.coins({
    super.key,
    required String value,
    this.onTap,
    this.isAnimated = false,
  }) : value = value,
       icon = Icons.monetization_on,
       label = 'Coins',
       iconColor = const Color(0xFFFF9800), // Orange
       backgroundColor = null;

  /// Construtor para Gems
  const StatCard.gems({
    super.key,
    required String value,
    this.onTap,
    this.isAnimated = false,
  }) : value = value,
       icon = Icons.diamond,
       label = 'Gems',
       iconColor = const Color(0xFF00BCD4), // Cyan
       backgroundColor = null;

  /// Construtor para Level
  const StatCard.level({
    super.key,
    required String value,
    this.onTap,
    this.isAnimated = false,
  }) : value = value,
       icon = Icons.military_tech,
       label = 'Level',
       iconColor = const Color(0xFF4CAF50), // Green
       backgroundColor = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveIconColor = iconColor ?? colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;

    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: effectiveIconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 20),
          ),

          const SizedBox(height: 8),

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

/// Widget para exibir múltiplas estatísticas em uma linha
class StatsRow extends StatelessWidget {
  final int xp;
  final int coins;
  final int gems;
  final int level;
  final bool isAnimated;
  final VoidCallback? onXpTap;
  final VoidCallback? onCoinsTap;
  final VoidCallback? onGemsTap;
  final VoidCallback? onLevelTap;

  const StatsRow({
    super.key,
    required this.xp,
    required this.coins,
    required this.gems,
    required this.level,
    this.isAnimated = false,
    this.onXpTap,
    this.onCoinsTap,
    this.onGemsTap,
    this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard.level(
            value: level.toString(),
            onTap: onLevelTap,
            isAnimated: isAnimated,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard.xp(
            value: _formatNumber(xp),
            onTap: onXpTap,
            isAnimated: isAnimated,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard.coins(
            value: _formatNumber(coins),
            onTap: onCoinsTap,
            isAnimated: isAnimated,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard.gems(
            value: _formatNumber(gems),
            onTap: onGemsTap,
            isAnimated: isAnimated,
          ),
        ),
      ],
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

/// Widget compacto para estatísticas em uma linha horizontal
class CompactStatsBar extends StatelessWidget {
  final int xp;
  final int coins;
  final int gems;
  final int level;

  const CompactStatsBar({
    super.key,
    required this.xp,
    required this.coins,
    required this.gems,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactStat(
            icon: Icons.military_tech,
            value: level.toString(),
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 12),
          _CompactStat(
            icon: Icons.auto_awesome,
            value: _formatNumber(xp),
            color: const Color(0xFF9C27B0),
          ),
          const SizedBox(width: 12),
          _CompactStat(
            icon: Icons.monetization_on,
            value: _formatNumber(coins),
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(width: 12),
          _CompactStat(
            icon: Icons.diamond,
            value: _formatNumber(gems),
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

class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _CompactStat({
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
