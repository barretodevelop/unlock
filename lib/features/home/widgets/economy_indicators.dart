// lib/features/home/widgets/economy_indicators.dart
// Indicadores de economia (XP, Coins, Gems) - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/home/providers/home_provider.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/core/utils/level_calculator.dart';

/// Widget para exibir indicadores de economia do usuário
class EconomyIndicators extends ConsumerWidget {
  final bool showDetailed;
  final bool isCompact;
  final VoidCallback? onTap;

  const EconomyIndicators({
    super.key,
    this.showDetailed = false,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final homeState = ref.watch(homeProvider);
    final userEconomy = ref.watch(userEconomyProvider);
    final userLevelInfo = ref.watch(userLevelInfoProvider);
    final hasPendingRewards = ref.watch(hasPendingRewardsProvider);

    if (homeState.user == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.secondaryContainer.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: showDetailed
            ? _buildDetailedView(context, theme, userEconomy, userLevelInfo, hasPendingRewards)
            : _buildCompactView(context, theme, userEconomy, hasPendingRewards),
      ),
    );
  }

  /// Construir visão detalhada
  Widget _buildDetailedView(
    BuildContext context,
    ThemeData theme,
    Map<String, int> userEconomy,
    Map<String, dynamic> userLevelInfo,
    bool hasPendingRewards,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com título e badge de recompensas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sua Economia',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (hasPendingRewards)
              _buildRewardsBadge(context, theme),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Indicadores de XP e Nível
        _buildXPSection(context, theme, userLevelInfo),
        
        const SizedBox(height: 16),
        
        // Indicadores de Moedas
        Row(
          children: [
            Expanded(
              child: _buildEconomyCard(
                context,
                theme,
                '🪙',
                'Coins',
                userEconomy['coins'] ?? 0,
                AppTheme.coinsColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEconomyCard(
                context,
                theme,
                '💎',
                'Gems',
                userEconomy['gems'] ?? 0,
                AppTheme.gemsColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construir visão compacta
  Widget _buildCompactView(
    BuildContext context,
    ThemeData theme,
    Map<String, int> userEconomy,
    bool hasPendingRewards,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCompactIndicator(
          context,
          theme,
          '⚡',
          userEconomy['xp'] ?? 0,
          AppTheme.xpColor,
        ),
        _buildCompactIndicator(
          context,
          theme,
          '🪙',
          userEconomy['coins'] ?? 0,
          AppTheme.coinsColor,
        ),
        _buildCompactIndicator(
          context,
          theme,
          '💎',
          userEconomy['gems'] ?? 0,
          AppTheme.gemsColor,
        ),
        if (hasPendingRewards)
          _buildRewardsBadge(context, theme),
      ],
    );
  }

  /// Construir seção de XP e nível
  Widget _buildXPSection(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> userLevelInfo,
  ) {
    final level = userLevelInfo['level'] ?? 1;
    final xp = userLevelInfo['xp'] ?? 0;
    final progress = userLevelInfo['progress'] ?? 0.0;
    final xpToNext = userLevelInfo['xpToNext'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.xpColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.xpColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nível e XP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.xpColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Nível $level',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '⚡',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    LevelCalculator.formatXP(xp),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.xpColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (xpToNext > 0)
                Text(
                  '+${LevelCalculator.formatXP(xpToNext)} para próximo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Barra de progresso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progresso no Nível',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.xpColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.xpColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir card de economia
  Widget _buildEconomyCard(
    BuildContext context,
    ThemeData theme,
    String icon,
    String label,
    int value,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatNumber(value),
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir indicador compacto
  Widget _buildCompactIndicator(
    BuildContext context,
    ThemeData theme,
    String icon,
    int value,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          _formatNumber(value),
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Construir badge de recompensas pendentes
  Widget _buildRewardsBadge(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.errorColor,
            AppTheme.errorColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Recompensas',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Formatar números grandes
  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) {
      final k = number / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    final m = number / 1000000;
    return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
  }
}

/// Widget animado para ganho de XP/Coins/Gems
class EconomyGainAnimation extends StatefulWidget {
  final String icon;
  final int amount;
  final Color color;
  final VoidCallback? onComplete;

  const EconomyGainAnimation({
    super.key,
    required this.icon,
    required this.amount,
    required this.color,
    this.onComplete,
  });

  @override
  State<EconomyGainAnimation> createState() => _EconomyGainAnimationState();
}

class _EconomyGainAnimationState extends State<EconomyGainAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -50.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${widget.amount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
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
}