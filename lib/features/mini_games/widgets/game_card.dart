// lib/features/mini_games/widgets/game_card.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/mini_game_model.dart';

/// Card de jogo com informações e personal best
class GameCard extends StatefulWidget {
  final GameType gameType;
  final GameResult? personalBest;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.gameType,
    this.personalBest,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.gameType.themeColor.withOpacity(
                      0.2 + (_glowAnimation.value * 0.3),
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildCard(),
            ),
          ),
        );
      },
    );
  }

  /// Construir o card principal
  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.gameType.themeColor.withOpacity(0.1),
            widget.gameType.themeColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.gameType.themeColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Conteúdo superior (ícone, título, descrição)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildDescription(),
              ],
            ),
            // Conteúdo inferior (recorde, botão)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPersonalBest(),
                const SizedBox(height: 8), // Espaçamento ligeiramente reduzido
                _buildPlayButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Header do card com ícone e nome
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.gameType.themeColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.gameType.themeColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.gameType.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.gameType.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.gameType.themeColor,
                ),
              ),
              if (widget.personalBest != null) _buildRankBadge(),
            ],
          ),
        ),
      ],
    );
  }

  /// Badge do rank atual
  Widget _buildRankBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.personalBest!.rankColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.personalBest!.rankColor.withOpacity(0.5),
        ),
      ),
      child: Text(
        'Rank ${widget.personalBest!.rank}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: widget.personalBest!.rankColor,
        ),
      ),
    );
  }

  /// Descrição do jogo
  Widget _buildDescription() {
    return Text(
      widget.gameType.description,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Personal best ou chamada para primeira jogada
  Widget _buildPersonalBest() {
    if (widget.personalBest == null) {
      return _buildFirstTimePlay();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.gameType.themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.gameType.themeColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 16,
                color: widget.personalBest!.rankColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Personal Best',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.personalBest!.rankColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.personalBest!.finalScore} pts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.gameType.themeColor,
            ),
          ),
          Text(
            _formatDuration(widget.personalBest!.duration),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para primeira jogada
  Widget _buildFirstTimePlay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.gameType.themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.gameType.themeColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 20,
            color: widget.gameType.themeColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Primeira vez? Vamos jogar!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.gameType.themeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Botão de jogar
  Widget _buildPlayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.gameType.themeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: const Icon(Icons.play_arrow, size: 18),
        label: const Text(
          'Jogar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Formatar duração
  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
