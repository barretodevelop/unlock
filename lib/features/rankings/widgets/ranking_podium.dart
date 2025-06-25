// lib/features/rankings/widgets/ranking_podium.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/ranking_model.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

/// Widget de pódium para exibir top 3 com animações
class RankingPodium extends StatefulWidget {
  final List<RankingEntry> topThree;
  final RankingCategory category;
  final bool showParticles;
  final String? currentUserId;

  const RankingPodium({
    super.key,
    required this.topThree,
    required this.category,
    this.showParticles = true,
    this.currentUserId,
  });

  @override
  State<RankingPodium> createState() => _RankingPodiumState();
}

class _RankingPodiumState extends State<RankingPodium>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();

    // Criar animações para cada posição do pódium
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 800 + (index * 200)),
        vsync: this,
      );
    });

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    }).toList();

    // Iniciar animações em sequência
    _startAnimations();
  }

  void _startAnimations() async {
    // Ordem de animação: 1º, 2º, 3º
    final animationOrder = [0, 1, 2]; // Índices na lista topThree

    for (int i = 0; i < animationOrder.length; i++) {
      final index = animationOrder[i];
      if (index < widget.topThree.length) {
        await Future.delayed(Duration(milliseconds: i * 200));
        if (mounted) _controllers[index].forward();
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
          // Título do pódium
          _buildPodiumTitle(context),

          const SizedBox(height: 32),

          // Pódium em si
          _buildPodiumStructure(context),

          const SizedBox(height: 24),

          // Informações adicionais
          _buildPodiumStats(context),
        ],
      ),
    );
  }

  /// Construir título do pódium
  Widget _buildPodiumTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.category.icon,
            color: widget.category.color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 3',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.category.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: widget.category.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construir estrutura do pódium
  Widget _buildPodiumStructure(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2º lugar (se existir)
        if (widget.topThree.length > 1)
          _buildPodiumPosition(
            entry: widget.topThree[1],
            position: 2,
            height: 120,
            color: _getSilverColor(),
            animationIndex: 1,
          ),

        const SizedBox(width: 12),

        // 1º lugar
        if (widget.topThree.isNotEmpty)
          _buildPodiumPosition(
            entry: widget.topThree[0],
            position: 1,
            height: 160,
            color: _getGoldColor(),
            animationIndex: 0,
            isWinner: true,
          ),

        const SizedBox(width: 12),

        // 3º lugar (se existir)
        if (widget.topThree.length > 2)
          _buildPodiumPosition(
            entry: widget.topThree[2],
            position: 3,
            height: 100,
            color: _getBronzeColor(),
            animationIndex: 2,
          ),
      ],
    );
  }

  /// Construir posição individual do pódium
  Widget _buildPodiumPosition({
    required RankingEntry entry,
    required int position,
    required double height,
    required Color color,
    required int animationIndex,
    bool isWinner = false,
  }) {
    final isCurrentUser = widget.currentUserId == entry.userId;

    return AnimatedBuilder(
      animation: _controllers[animationIndex],
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimations[animationIndex].value,
          child: SlideTransition(
            position: _slideAnimations[animationIndex],
            child: FadeTransition(
              opacity: _fadeAnimations[animationIndex],
              child: GestureDetector(
                onTap: () => _onPodiumTapped(entry),
                child: Column(
                  children: [
                    // Avatar com efeitos especiais
                    _buildPodiumAvatar(
                      entry: entry,
                      position: position,
                      color: color,
                      isWinner: isWinner,
                      isCurrentUser: isCurrentUser,
                    ),

                    const SizedBox(height: 12),

                    // Nome
                    SizedBox(
                      width: isWinner ? 100 : 80,
                      child: Text(
                        entry.displayName,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isWinner ? 14 : 12,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Valor
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.category.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.category.formatValue(entry.value),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: widget.category.color,
                          fontWeight: FontWeight.bold,
                          fontSize: isWinner ? 12 : 10,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Base do pódium
                    _buildPodiumBase(
                      height: height,
                      color: color,
                      position: position,
                      isWinner: isWinner,
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

  /// Construir avatar do pódium
  Widget _buildPodiumAvatar({
    required RankingEntry entry,
    required int position,
    required Color color,
    required bool isWinner,
    required bool isCurrentUser,
  }) {
    final avatarRadius = isWinner ? 40.0 : 32.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Efeito de brilho para o vencedor
        if (isWinner)
          Container(
            width: avatarRadius * 2 + 16,
            height: avatarRadius * 2 + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.amber.withOpacity(0.3),
                  Colors.amber.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),

        // Avatar principal
        Container(
          margin: EdgeInsets.all(isWinner ? 8 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrentUser ? widget.category.color : Colors.white,
              width: isCurrentUser ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: isWinner ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AvatarCircle(
            imageUrl: entry.avatar.startsWith('http') ? entry.avatar : null,
            // fallbackText: entry.avatar.startsWith('http') ? null : entry.avatar,
            // radius: avatarRadius,
          ),
        ),

        // Badge de posição
        Positioned(
          top: isWinner ? -4 : -8,
          right: isWinner ? -4 : -8,
          child: Container(
            width: isWinner ? 36 : 32,
            height: isWinner ? 36 : 32,
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
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isWinner ? 16 : 14,
                ),
              ),
            ),
          ),
        ),

        // Coroa para o 1º lugar
        if (isWinner)
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            ),
          ),

        // Badge "VOCÊ" para usuário atual
        if (isCurrentUser)
          Positioned(
            bottom: -8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            ),
          ),
      ],
    );
  }

  /// Construir base do pódium
  Widget _buildPodiumBase({
    required double height,
    required Color color,
    required int position,
    required bool isWinner,
  }) {
    return Container(
      width: isWinner ? 100 : 80,
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
            blurRadius: isWinner ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPositionIcon(position),
            color: Colors.white,
            size: isWinner ? 40 : 32,
          ),
          const SizedBox(height: 8),
          Text(
            '${position}º',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isWinner ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir estatísticas do pódium
  Widget _buildPodiumStats(BuildContext context) {
    final totalValue = widget.topThree.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            'Total',
            widget.category.formatValue(totalValue),
            Icons.bar_chart,
          ),
          _buildStatItem(
            context,
            'Média',
            widget.category.formatValue(totalValue ~/ widget.topThree.length),
            Icons.trending_up,
          ),
          _buildStatItem(
            context,
            'Liderança',
            widget.topThree.isNotEmpty
                ? widget.category.formatValue(widget.topThree[0].value)
                : '0',
            Icons.emoji_events,
          ),
        ],
      ),
    );
  }

  /// Construir item de estatística
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: widget.category.color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.category.color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // ========== HANDLERS E UTILS ==========

  /// Handler para toque no pódium
  void _onPodiumTapped(RankingEntry entry) {
    AppLogger.debug('🏅 Podium entry tapped: ${entry.userId}');
    context.push('/profile/${entry.userId}');
  }

  /// Obter ícone da posição
  IconData _getPositionIcon(int position) {
    switch (position) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.workspace_premium;
      case 3:
        return Icons.military_tech;
      default:
        return Icons.star;
    }
  }

  /// Cores do pódium
  Color _getGoldColor() => Colors.amber;
  Color _getSilverColor() => Colors.grey.shade400;
  Color _getBronzeColor() => Colors.brown.shade400;
}

/// Pódium compacto para espaços menores
class CompactRankingPodium extends StatelessWidget {
  final List<RankingEntry> topThree;
  final RankingCategory category;

  const CompactRankingPodium({
    super.key,
    required this.topThree,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: topThree.asMap().entries.map((entry) {
          final index = entry.key;
          final rankingEntry = entry.value;

          return _CompactPodiumItem(
            entry: rankingEntry,
            position: index + 1,
            category: category,
          );
        }).toList(),
      ),
    );
  }
}

/// Item compacto do pódium
class _CompactPodiumItem extends StatelessWidget {
  final RankingEntry entry;
  final int position;
  final RankingCategory category;

  const _CompactPodiumItem({
    required this.entry,
    required this.position,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getPositionColor(position);

    return Column(
      children: [
        // Avatar com badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            AvatarCircle(
              imageUrl: entry.avatar.startsWith('http') ? entry.avatar : null,
              // fallbackText: entry.avatar.startsWith('http') ? null : entry.avatar,
              // radius: 24,
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
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
          width: 60,
          child: Text(
            entry.displayName,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 4),

        // Valor
        Text(
          category.formatValue(entry.value),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: category.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.grey;
    }
  }
}
