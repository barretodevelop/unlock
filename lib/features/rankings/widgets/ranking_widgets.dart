// lib/features/rankings/widgets/ranking_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/rankings/providers/ranking_provider.dart';
import 'package:unlock/models/ranking_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

// ========== PODIUM WIDGET ==========

/// Widget de pódium para exibir top 3
class RankingPodium extends StatefulWidget {
  final List<RankingEntry> topThree;
  final RankingCategory category;

  const RankingPodium({
    super.key,
    required this.topThree,
    required this.category,
  });

  @override
  State<RankingPodium> createState() => _RankingPodiumState();
}

class _RankingPodiumState extends State<RankingPodium>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    // Criar animações para cada posição
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 600 + (index * 200)),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();

    // Iniciar animações em sequência
    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      if (i < widget.topThree.length) {
        await Future.delayed(Duration(milliseconds: i * 150));
        _controllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topThree.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Título do podium
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.category.icon,
                color: widget.category.color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Top 3 - ${widget.category.label}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Podium em si
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2º lugar
              if (widget.topThree.length > 1)
                _buildPodiumPosition(1, 120, Colors.grey.shade400),

              const SizedBox(width: 8),

              // 1º lugar
              if (widget.topThree.isNotEmpty)
                _buildPodiumPosition(0, 140, Colors.amber),

              const SizedBox(width: 8),

              // 3º lugar
              if (widget.topThree.length > 2)
                _buildPodiumPosition(2, 100, Colors.brown.shade400),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir posição individual do podium
  Widget _buildPodiumPosition(int index, double height, Color color) {
    final entry = widget.topThree[index];
    final position = entry.position;

    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _animations[index].value,
          child: Column(
            children: [
              // Avatar com badge de posição
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarCircle(
                    imageUrl: entry.avatar.startsWith('http')
                        ? entry.avatar
                        : null,
                    // fallbackText: entry.avatar.startsWith('http')
                    //     ? null
                    //     : entry.avatar,
                    // radius: position == 1 ? 40 : 32,
                  ),

                  // Badge de posição
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$position',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Nome
              SizedBox(
                width: 80,
                child: Text(
                  entry.displayName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 4),

              // Valor
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.category.formatValue(entry.value),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.category.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Base do podium
              Container(
                width: 80,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withOpacity(0.8), color],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    position == 1
                        ? Icons.emoji_events
                        : Icons.workspace_premium,
                    color: Colors.white,
                    size: position == 1 ? 32 : 24,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ========== RANKING LIST ==========

/// Lista de rankings para posições após o top 3
class RankingList extends StatelessWidget {
  final List<RankingEntry> rankings;
  final RankingCategory category;
  final int startIndex;

  const RankingList({
    super.key,
    required this.rankings,
    required this.category,
    this.startIndex = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final entry = rankings[index];
        return _RankingListItem(entry: entry, category: category, index: index);
      }, childCount: rankings.length),
    );
  }
}

/// Item individual da lista de ranking
class _RankingListItem extends StatefulWidget {
  final RankingEntry entry;
  final RankingCategory category;
  final int index;

  const _RankingListItem({
    required this.entry,
    required this.category,
    required this.index,
  });

  @override
  State<_RankingListItem> createState() => _RankingListItemState();
}

class _RankingListItemState extends State<_RankingListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Animar entrada com delay baseado no index
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
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
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - _animation.value), 0),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),

                // Posição
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getPositionColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.entry.position}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _getPositionColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Avatar e nome
                title: Row(
                  children: [
                    AvatarCircle(
                      imageUrl: widget.entry.avatar.startsWith('http')
                          ? widget.entry.avatar
                          : null,
                      // fallbackText: widget.entry.avatar.startsWith('http')
                      //     ? null
                      //     : widget.entry.avatar,
                      // radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.entry.displayName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@${widget.entry.username}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Valor e categoria
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.category.icon,
                            size: 14,
                            color: widget.category.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.category.formatValue(widget.entry.value),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: widget.category.color,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                onTap: () => _onEntryTapped(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Obter cor baseada na posição
  Color _getPositionColor() {
    final position = widget.entry.position;

    if (position <= 10) {
      return Theme.of(context).colorScheme.primary;
    } else if (position <= 25) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }
  }

  /// Handler para toque no item
  void _onEntryTapped() {
    AppLogger.debug('🏅 Ranking entry tapped: ${widget.entry.userId}');

    // TODO: Navegar para perfil do usuário ou mostrar detalhes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Perfil de ${widget.entry.displayName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// ========== CATEGORY SELECTOR ==========

/// Seletor de categoria de ranking
class RankingCategorySelector extends StatelessWidget {
  final RankingCategory selectedCategory;
  final Function(RankingCategory) onCategoryChanged;

  const RankingCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: RankingCategory.values.length,
        itemBuilder: (context, index) {
          final category = RankingCategory.values[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CategoryChip(
              category: category,
              isSelected: isSelected,
              onTap: () => onCategoryChanged(category),
            ),
          );
        },
      ),
    );
  }
}

/// Chip individual de categoria
class _CategoryChip extends StatefulWidget {
  final RankingCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: AppConstants.animationDuration,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.category.color
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                      ? widget.category.color
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.category.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.category.icon,
                    size: 18,
                    color: widget.isSelected
                        ? Colors.white
                        : widget.category.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.category.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: widget.isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ========== USER RANK CARD ==========

/// Card mostrando a posição atual do usuário
class UserRankCard extends ConsumerWidget {
  final UserModel user;
  final RankingCategory category;
  final RankingPeriod period;

  const UserRankCard({
    super.key,
    required this.user,
    required this.category,
    required this.period,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = RankingQuery(
      category: category,
      scope: RankingScopeType.global,
      period: period,
    );

    final positionAsync = ref.watch(userPositionProvider(query));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            category.color.withOpacity(0.1),
            category.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: category.color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          // Avatar do usuário
          AvatarCircle(
            imageUrl: user.avatar.startsWith('http') ? user.avatar : null,
            // fallbackText: user.avatar.startsWith('http') ? null : user.avatar,
            // radius: 24,
          ),

          const SizedBox(width: 12),

          // Informações do usuário
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(category.icon, size: 16, color: category.color),
                    const SizedBox(width: 4),
                    Text(
                      category.formatValue(
                        category.getValueFromUser({
                          'xp': user.xp,
                          'coins': user.coins,
                          'gems': user.gems,
                          'level': user.level,
                          'loginStreak': user.loginStreak,
                          'stats': {}, // TODO: Add user stats
                        }),
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: category.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Posição
          positionAsync.when(
            data: (position) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                position != null ? '#$position' : '--',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            ),
          ),
        ],
      ),
    );
  }
}
