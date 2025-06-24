// lib/features/mini_games/widgets/game_result_dialog.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/mini_game_model.dart';

/// Dialog mostrando resultado do jogo
class GameResultDialog extends StatefulWidget {
  final GameResult result;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;

  const GameResultDialog({
    super.key,
    required this.result,
    required this.onPlayAgain,
    required this.onBackToMenu,
  });

  @override
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Controladores de animação
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animações principais
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Iniciar animações
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (mounted) {
      _mainController.forward();
      
      // Se for personal best, adicionar celebração
      if (widget.result.isPersonalBest) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _confettiController.forward();
          _pulseController.repeat(reverse: true);
        }
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, 100 * _slideAnimation.value),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildMainCard(),
                      if (widget.result.isPersonalBest) _buildConfetti(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Card principal do resultado
  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildScoreSection(),
          const SizedBox(height: 24),
          _buildStatsSection(),
          const SizedBox(height: 24),
          _buildAchievements(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Header com ícone e título
  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: widget.result.isPersonalBest ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: widget.result.isPersonalBest ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.result.type.themeColor,
                      widget.result.type.themeColor.withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.result.type.themeColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  widget.result.type.icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          widget.result.isPersonalBest ? 'NOVO RECORDE!' : 'Jogo Concluído!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.result.isPersonalBest 
                ? Colors.amber
                : widget.result.type.themeColor,
          ),
        ),
        if (widget.result.isPersonalBest) ...[
          const SizedBox(height: 4),
          Text(
            '🎉 Parabéns! 🎉',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  /// Seção de pontuação
  Widget _buildScoreSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.result.rankColor.withOpacity(0.1),
            widget.result.rankColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.result.rankColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.result.rankColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'RANK ${widget.result.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.result.finalScore}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.result.type.themeColor,
            ),
          ),
          Text(
            'pontos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          if (widget.result.score != widget.result.finalScore) ...[
            const SizedBox(height: 8),
            Text(
              'Score base: ${widget.result.score} × ${widget.result.difficulty.multiplier}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Seção de estatísticas
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatísticas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.timer,
                label: 'Tempo',
                value: _formatDuration(widget.result.duration),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.speed,
                label: 'Dificuldade',
                value: widget.result.difficulty.label,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._buildGameSpecificStats(),
      ],
    );
  }

  /// Item individual de estatística
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Estatísticas específicas do jogo
  List<Widget> _buildGameSpecificStats() {
    final stats = widget.result.stats;
    final gameSpecificStats = <Widget>[];

    switch (widget.result.type) {
      case GameType.memory:
        if (stats.containsKey('memoryAccuracy')) {
          final accuracy = (stats['memoryAccuracy'] as double) * 100;
          gameSpecificStats.add(
            _buildStatItem(
              icon: Icons.psychology,
              label: 'Precisão',
              value: '${accuracy.round()}%',
              color: Colors.purple,
            ),
          );
        }
        break;
        
      case GameType.reaction:
        if (stats.containsKey('averageReaction')) {
          final avgReaction = stats['averageReaction'] as double;
          gameSpecificStats.add(
            _buildStatItem(
              icon: Icons.flash_on,
              label: 'Reação Média',
              value: '${avgReaction.round()}ms',
              color: Colors.orange,
            ),
          );
        }
        break;
        
      case GameType.puzzle:
        if (stats.containsKey('solvingEfficiency')) {
          final efficiency = (stats['solvingEfficiency'] as double) * 100;
          gameSpecificStats.add(
            _buildStatItem(
              icon: Icons.extension,
              label: 'Eficiência',
              value: '${efficiency.round()}%',
              color: Colors.green,
            ),
          );
        }
        break;
    }

    if (gameSpecificStats.isNotEmpty) {
      return [
        Row(
          children: [
            Expanded(child: gameSpecificStats.first),
            if (gameSpecificStats.length > 1) ...[
              const SizedBox(width: 12),
              Expanded(child: gameSpecificStats[1]),
            ],
          ],
        ),
      ];
    }

    return [];
  }

  /// Seção de conquistas
  Widget _buildAchievements() {
    final achievements = <Widget>[];

    if (widget.result.isPersonalBest) {
      achievements.add(_buildAchievementBadge(
        icon: Icons.emoji_events,
        label: 'Personal Best',
        color: Colors.amber,
      ));
    }

    if (widget.result.rank == 'S') {
      achievements.add(_buildAchievementBadge(
        icon: Icons.star,
        label: 'Rank S',
        color: Colors.amber,
      ));
    }

    if (widget.result.finalScore > 1000) {
      achievements.add(_buildAchievementBadge(
        icon: Icons.trending_up,
        label: '1000+ Pontos',
        color: Colors.blue,
      ));
    }

    if (achievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conquistas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievements,
        ),
      ],
    );
  }

  /// Badge de conquista
  Widget _buildAchievementBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Botões de ação
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onBackToMenu,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.home),
            label: const Text('Menu'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onPlayAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.result.type.themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.replay),
            label: const Text('Jogar Novamente'),
          ),
        ),
      ],
    );
  }

  /// Animação de confete (para personal best)
  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ConfettiPainter(_confettiController.value),
            ),
          ),
        );
      },
    );
  }

  /// Formatar duração
  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

/// Painter para animação de confete
class ConfettiPainter extends CustomPainter {
  final double progress;

  ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final colors = [
      Colors.amber,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];

    // Desenhar partículas de confete
    for (int i = 0; i < 30; i++) {
      final x = (size.width * (i * 0.1 + 0.1)) % size.width;
      final y = size.height * progress * (1 + i * 0.05);
      
      if (y > size.height) continue;

      paint.color = colors[i % colors.length].withOpacity(1 - progress);
      
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 6,
          height: 12,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}