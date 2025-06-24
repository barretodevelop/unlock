// lib/features/rankings/widgets/user_rank_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/features/rankings/providers/ranking_provider.dart';
import 'package:unlock/models/ranking_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

/// Card mostrando a posição atual do usuário no ranking
class UserRankCard extends ConsumerStatefulWidget {
  final UserModel user;
  final RankingCategory category;
  final RankingPeriod period;
  final bool showTrend;
  final bool isCompact;

  const UserRankCard({
    super.key,
    required this.user,
    required this.category,
    required this.period,
    this.showTrend = true,
    this.isCompact = false,
  });

  @override
  ConsumerState<UserRankCard> createState() => _UserRankCardState();
}

class _UserRankCardState extends ConsumerState<UserRankCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Iniciar animação
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = RankingQuery(
      category: widget.category,
      scope: RankingScopeType.global,
      period: widget.period,
    );

    final positionAsync = ref.watch(userPositionProvider(query));

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.isCompact
                ? _buildCompactCard(context, positionAsync)
                : _buildFullCard(context, positionAsync),
          ),
        );
      },
    );
  }

  /// Construir card completo
  Widget _buildFullCard(BuildContext context, AsyncValue<int?> positionAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.category.color.withOpacity(0.1),
            widget.category.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.category.color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.category.color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header do card
            _buildCardHeader(context),

            const SizedBox(height: 16),

            // Conteúdo principal
            Row(
              children: [
                // Avatar e informações do usuário
                Expanded(flex: 2, child: _buildUserSection(context)),

                const SizedBox(width: 20),

                // Posição e estatísticas
                Expanded(
                  flex: 1,
                  child: _buildStatsSection(context, positionAsync),
                ),
              ],
            ),

            // Seção de tendência (se habilitada)
            if (widget.showTrend) ...[
              const SizedBox(height: 16),
              _buildTrendSection(context),
            ],
          ],
        ),
      ),
    );
  }

  /// Construir card compacto
  Widget _buildCompactCard(
    BuildContext context,
    AsyncValue<int?> positionAsync,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.category.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.category.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          AvatarCircle(
            imageUrl: widget.user.avatar.startsWith('http')
                ? widget.user.avatar
                : null,
            fallbackText: widget.user.avatar.startsWith('http')
                ? null
                : widget.user.avatar,
            radius: 20,
          ),

          const SizedBox(width: 12),

          // Informações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sua Posição',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      widget.category.icon,
                      size: 14,
                      color: widget.category.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getUserValue(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.category.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Posição
          _buildPositionBadge(context, positionAsync),
        ],
      ),
    );
  }

  /// Construir header do card
  Widget _buildCardHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.category.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(widget.category.icon, color: Colors.white, size: 24),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sua Posição',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.category.label} • ${widget.period.label}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.category.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Badge "VOCÊ"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.category.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'VOCÊ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Construir seção do usuário
  Widget _buildUserSection(BuildContext context) {
    return Row(
      children: [
        // Avatar grande
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.category.color, width: 3),
            boxShadow: [
              BoxShadow(
                color: widget.category.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AvatarCircle(
            imageUrl: widget.user.avatar.startsWith('http')
                ? widget.user.avatar
                : null,
            fallbackText: widget.user.avatar.startsWith('http')
                ? null
                : widget.user.avatar,
            radius: 32,
          ),
        ),

        const SizedBox(width: 16),

        // Informações do usuário
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '@${widget.user.username}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              _buildValueRow(context),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir row de valor
  Widget _buildValueRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.category.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.category.icon, size: 18, color: widget.category.color),
          const SizedBox(width: 8),
          Text(
            _getUserValue(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.category.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir seção de estatísticas
  Widget _buildStatsSection(
    BuildContext context,
    AsyncValue<int?> positionAsync,
  ) {
    return Column(
      children: [
        // Posição
        positionAsync.when(
          data: (position) => _buildPositionDisplay(context, position),
          loading: () => _buildLoadingPosition(context),
          error: (_, __) => _buildErrorPosition(context),
        ),

        const SizedBox(height: 16),

        // Estatísticas extras
        _buildExtraStats(context),
      ],
    );
  }

  /// Construir display de posição
  Widget _buildPositionDisplay(BuildContext context, int? position) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.category.color,
            widget.category.color.withOpacity(0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.category.color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            position != null ? '#$position' : '--',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'posição',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir posição loading
  Widget _buildLoadingPosition(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: widget.category.color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      ),
    );
  }

  /// Construir posição de erro
  Widget _buildErrorPosition(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        size: 32,
      ),
    );
  }

  /// Construir badge de posição compacto
  Widget _buildPositionBadge(
    BuildContext context,
    AsyncValue<int?> positionAsync,
  ) {
    return positionAsync.when(
      data: (position) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.category.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          position != null ? '#$position' : '--',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        size: 20,
      ),
    );
  }

  /// Construir estatísticas extras
  Widget _buildExtraStats(BuildContext context) {
    return Column(
      children: [
        _buildStatItem(
          context,
          'Nível',
          '${widget.user.level}',
          Icons.trending_up,
        ),
        const SizedBox(height: 8),
        _buildStatItem(
          context,
          'Streak',
          '${widget.user.loginStreak ?? 0}',
          Icons.local_fire_department,
        ),
      ],
    );
  }

  /// Construir item de estatística
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: widget.category.color),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.category.color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// Construir seção de tendência
  Widget _buildTrendSection(BuildContext context) {
    // Mock de tendência baseada no período
    final trend = _getMockTrend();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(trend.icon, size: 16, color: trend.color),
          const SizedBox(width: 8),
          Text(
            trend.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: trend.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'nos últimos 7 dias',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ========== UTILS ==========

  /// Obter valor do usuário para a categoria
  String _getUserValue() {
    final value = widget.category.getValueFromUser({
      'xp': widget.user.xp,
      'coins': widget.user.coins,
      'gems': widget.user.gems,
      'level': widget.user.level,
      'loginStreak': widget.user.loginStreak,
      'stats': {}, // TODO: Adicionar stats do user model
    });

    return widget.category.formatValue(value);
  }

  /// Obter tendência mock
  RankingTrend _getMockTrend() {
    // Mock simples baseado no período
    switch (widget.period) {
      case RankingPeriod.today:
        return RankingTrend.up;
      case RankingPeriod.thisWeek:
        return RankingTrend.stable;
      case RankingPeriod.thisMonth:
        return RankingTrend.down;
      case RankingPeriod.allTime:
        return RankingTrend.stable;
    }
  }
}

/// Card de ranking simplificado para múltiplas categorias
class MultiCategoryUserRankCard extends ConsumerWidget {
  final UserModel user;
  final List<RankingCategory> categories;

  const MultiCategoryUserRankCard({
    super.key,
    required this.user,
    required this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              AvatarCircle(
                imageUrl: user.avatar.startsWith('http') ? user.avatar : null,
                fallbackText: user.avatar.startsWith('http')
                    ? null
                    : user.avatar,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suas Posições',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lista de categorias
          ...categories.map((category) {
            final query = RankingQuery(
              category: category,
              scope: RankingScopeType.global,
              period: RankingPeriod.allTime,
            );

            final positionAsync = ref.watch(userPositionProvider(query));

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CategoryRankItem(
                category: category,
                user: user,
                positionAsync: positionAsync,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// Item de categoria no card multi-categoria
class _CategoryRankItem extends StatelessWidget {
  final RankingCategory category;
  final UserModel user;
  final AsyncValue<int?> positionAsync;

  const _CategoryRankItem({
    required this.category,
    required this.user,
    required this.positionAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ícone da categoria
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(category.icon, size: 16, color: category.color),
        ),

        const SizedBox(width: 12),

        // Nome e valor
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                _getUserValue(category),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: category.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Posição
        positionAsync.when(
          data: (position) => Text(
            position != null ? '#$position' : '--',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: category.color,
            ),
          ),
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 1),
          ),
          error: (_, __) => Icon(
            Icons.error_outline,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  String _getUserValue(RankingCategory category) {
    final value = category.getValueFromUser({
      'xp': user.xp,
      'coins': user.coins,
      'gems': user.gems,
      'level': user.level,
      'loginStreak': user.loginStreak,
      'stats': {},
    });

    return category.formatValue(value);
  }
}
