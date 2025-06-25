// lib/features/rankings/widgets/ranking_list.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/ranking_model.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

/// Lista de rankings para posições após o top 3
class RankingList extends StatelessWidget {
  final List<RankingEntry> rankings;
  final RankingCategory category;
  final int startIndex;
  final bool showAnimations;
  final String? currentUserId;

  const RankingList({
    super.key,
    required this.rankings,
    required this.category,
    this.startIndex = 1,
    this.showAnimations = true,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) return _buildEmptyState(context);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final entry = rankings[index];
        final isCurrentUser =
            currentUserId != null && entry.userId == currentUserId;

        return RankingListItem(
          entry: entry,
          category: category,
          animationIndex: showAnimations ? index : -1,
          isCurrentUser: isCurrentUser,
          onTap: () => _onEntryTapped(context, entry),
        );
      }, childCount: rankings.length),
    );
  }

  /// Construir estado vazio
  Widget _buildEmptyState(context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum ranking encontrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seja o primeiro a aparecer neste ranking!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Handler para toque no item
  void _onEntryTapped(BuildContext context, RankingEntry entry) {
    AppLogger.debug('🏅 Ranking entry tapped: ${entry.userId}');

    // Navegar para perfil do usuário
    context.push('/profile/${entry.userId}');
  }
}

/// Item individual da lista de ranking
class RankingListItem extends StatefulWidget {
  final RankingEntry entry;
  final RankingCategory category;
  final int animationIndex;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const RankingListItem({
    super.key,
    required this.entry,
    required this.category,
    this.animationIndex = -1,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  State<RankingListItem> createState() => _RankingListItemState();
}

class _RankingListItemState extends State<RankingListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.animationIndex * 50)),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Animar entrada com delay baseado no index
    if (widget.animationIndex >= 0) {
      Future.delayed(Duration(milliseconds: widget.animationIndex * 50), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0; // Sem animação
    }
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
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildListItem(context),
          ),
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isCurrentUser
            ? widget.category.color.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isCurrentUser
              ? widget.category.color.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: widget.isCurrentUser ? 2 : 1,
        ),
        boxShadow: widget.isCurrentUser
            ? [
                BoxShadow(
                  color: widget.category.color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Posição
                _buildPositionBadge(context),

                const SizedBox(width: 16),

                // Avatar
                AvatarCircle(
                  imageUrl: widget.entry.avatar.startsWith('http')
                      ? widget.entry.avatar
                      : null,
                  // fallbackText: widget.entry.avatar.startsWith('http')
                  //     ? null
                  //     : widget.entry.avatar,
                  // radius: 24,
                ),

                const SizedBox(width: 16),

                // Informações do usuário
                Expanded(child: _buildUserInfo(context)),

                const SizedBox(width: 16),

                // Valor e tendência
                _buildValueSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construir badge de posição
  Widget _buildPositionBadge(BuildContext context) {
    final position = widget.entry.position;
    final color = _getPositionColor(position);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Center(
        child: Text(
          '$position',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Construir informações do usuário
  Widget _buildUserInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.entry.displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.isCurrentUser ? widget.category.color : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Badge "Você" para usuário atual
            if (widget.isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.category.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'VOCÊ',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 2),

        Text(
          '@${widget.entry.username}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),

        // Informações extras (se disponível)
        if (widget.entry.metadata.isNotEmpty) _buildMetadataInfo(context),
      ],
    );
  }

  /// Construir informações de metadata
  Widget _buildMetadataInfo(BuildContext context) {
    final level = widget.entry.metadata['level'] as int?;
    if (level == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.star_outline,
            size: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 4),
          Text(
            'Nível $level',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Construir seção de valor
  Widget _buildValueSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Valor principal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.category.icon,
                size: 16,
                color: widget.category.color,
              ),
              const SizedBox(width: 6),
              Text(
                widget.category.formatValue(widget.entry.value),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: widget.category.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Indicador de tendência (placeholder)
        _buildTrendIndicator(context),
      ],
    );
  }

  /// Construir indicador de tendência
  Widget _buildTrendIndicator(BuildContext context) {
    // Mock: gerar tendência baseada na posição
    final trend = _getMockTrend();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(trend.icon, size: 12, color: trend.color),
        const SizedBox(width: 2),
        Text(
          trend.label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: trend.color, fontSize: 10),
        ),
      ],
    );
  }

  /// Obter cor baseada na posição
  Color _getPositionColor(int position) {
    if (position <= 3) {
      return Colors.amber; // Top 3
    } else if (position <= 10) {
      return Theme.of(context).colorScheme.primary; // Top 10
    } else if (position <= 25) {
      return Colors.orange; // Top 25
    } else if (position <= 50) {
      return Colors.blue; // Top 50
    } else {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }
  }

  /// Obter tendência mock
  RankingTrend _getMockTrend() {
    // Mock simples baseado na posição
    final position = widget.entry.position;

    if (position <= 10) {
      return RankingTrend.up;
    } else if (position <= 50) {
      return RankingTrend.stable;
    } else {
      return RankingTrend.down;
    }
  }
}

/// Lista compacta de rankings (para espaços menores)
class CompactRankingList extends StatelessWidget {
  final List<RankingEntry> rankings;
  final RankingCategory category;
  final int maxItems;

  const CompactRankingList({
    super.key,
    required this.rankings,
    required this.category,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final limitedRankings = rankings.take(maxItems).toList();

    return Column(
      children: limitedRankings.map((entry) {
        return CompactRankingItem(entry: entry, category: category);
      }).toList(),
    );
  }
}

/// Item compacto de ranking
class CompactRankingItem extends StatelessWidget {
  final RankingEntry entry;
  final RankingCategory category;

  const CompactRankingItem({
    super.key,
    required this.entry,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Posição
          SizedBox(
            width: 20,
            child: Text(
              '${entry.position}',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar pequeno
          AvatarCircle(
            imageUrl: entry.avatar.startsWith('http') ? entry.avatar : null,
            // fallbackText: entry.avatar.startsWith('http') ? null : entry.avatar,
            // radius: 16,
          ),

          const SizedBox(width: 12),

          // Nome
          Expanded(
            child: Text(
              entry.displayName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Valor
          Text(
            category.formatValue(entry.value),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: category.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
