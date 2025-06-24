// lib/features/mini_games/games/reaction_game_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/mini_game_model.dart';
import 'package:unlock/providers/mini_game_provider.dart';

/// Widget do jogo de reação
class ReactionGameWidget extends ConsumerStatefulWidget {
  final GameDifficulty difficulty;
  final Function(GameResult) onGameCompleted;

  const ReactionGameWidget({
    super.key,
    required this.difficulty,
    required this.onGameCompleted,
  });

  @override
  ConsumerState<ReactionGameWidget> createState() => _ReactionGameWidgetState();
}

class _ReactionGameWidgetState extends ConsumerState<ReactionGameWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _targetController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  bool _isGameStarted = false;
  Color _targetColor = Colors.orange;

  @override
  void initState() {
    super.initState();

    AppLogger.info('⚡ ReactionGame: Iniciado', data: {
      'difficulty': widget.difficulty.label,
    });

    // Configurar animações
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _targetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _targetController, curve: Curves.elasticOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Animação cíclica para o botão start
    _pulseController.repeat(reverse: true);

    // Gerar cor aleatória para o target
    _generateRandomColor();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _targetController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameSessionProvider(GameType.reaction));

    return Column(
      children: [
        _buildGameHeader(gameState),
        const SizedBox(height: 24),
        Expanded(
          child: _isGameStarted 
              ? _buildGameContent(gameState)
              : _buildStartScreen(),
        ),
      ],
    );
  }

  /// Header do jogo
  Widget _buildGameHeader(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildInfoItem(
            icon: Icons.bolt,
            label: 'Score',
            value: gameState.currentScore.toString(),
            color: Colors.orange,
          ),
          const SizedBox(width: 24),
          _buildInfoItem(
            icon: Icons.speed,
            label: 'Round',
            value: '${(gameState.gameData['currentRound'] ?? 0) + 1}/${gameState.gameData['rounds'] ?? 0}',
            color: Colors.blue,
          ),
          const SizedBox(width: 24),
          _buildInfoItem(
            icon: Icons.timer,
            label: 'Média',
            value: _getAverageReaction(gameState),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  /// Item de informação
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

  /// Tela inicial
  Widget _buildStartScreen() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    size: 64,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Teste de Reação',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.difficulty.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                _buildInstructions(),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.flash_on),
                  label: const Text(
                    'Testar Reflexos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Instruções
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.flash_on,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            'Como Jogar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1. Aguarde o alvo aparecer na tela\n'
            '2. Clique o mais rápido possível quando ele surgir\n'
            '3. Quanto mais rápido, mais pontos você ganha!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Conteúdo do jogo
  Widget _buildGameContent(GameState gameState) {
    if (gameState.status == GameStatus.completed) {
      return _buildGameCompleted(gameState);
    }

    if (gameState.status == GameStatus.failed) {
      return _buildGameFailed();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGameStatus(gameState),
          const SizedBox(height: 60),
          _buildReactionArea(gameState),
          const SizedBox(height: 60),
          _buildLastReactionTime(gameState),
        ],
      ),
    );
  }

  /// Status do jogo
  Widget _buildGameStatus(GameState gameState) {
    final isWaiting = gameState.gameData['isWaiting'] ?? false;
    final showTarget = gameState.gameData['showTarget'] ?? false;
    
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    if (isWaiting) {
      statusText = 'Aguarde...';
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
    } else if (showTarget) {
      statusText = 'CLIQUE AGORA!';
      statusColor = Colors.red;
      statusIcon = Icons.touch_app;
    } else {
      statusText = 'Preparando próximo round...';
      statusColor = Colors.grey;
      statusIcon = Icons.refresh;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Área de reação
  Widget _buildReactionArea(GameState gameState) {
    final showTarget = gameState.gameData['showTarget'] ?? false;
    
    return GestureDetector(
      onTap: () => _onTargetTapped(gameState),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple effect
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              return Container(
                width: 300 * (1 + _rippleAnimation.value),
                height: 300 * (1 + _rippleAnimation.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _targetColor.withOpacity(1 - _rippleAnimation.value),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          // Target principal
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: showTarget ? _scaleAnimation.value : 0.0,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _targetColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _targetColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.touch_app,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          // Área clicável invisível (maior que o target)
          Container(
            width: 300,
            height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  /// Último tempo de reação
  Widget _buildLastReactionTime(GameState gameState) {
    final reactions = gameState.gameData['reactions'] as List<int>? ?? [];
    
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final lastReaction = reactions.last;
    final isGoodReaction = lastReaction < 300; // Menos de 300ms é bom
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isGoodReaction 
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGoodReaction 
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGoodReaction ? Icons.flash_on : Icons.timer,
            color: isGoodReaction ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${lastReaction}ms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isGoodReaction ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isGoodReaction ? '- Excelente!' : '- Pode melhorar!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Jogo completado
  Widget _buildGameCompleted(GameState gameState) {
    final reactions = gameState.gameData['reactions'] as List<int>? ?? [];
    final avgReaction = reactions.isEmpty ? 0 : reactions.reduce((a, b) => a + b) / reactions.length;
    final bestReaction = reactions.isEmpty ? 0 : reactions.reduce(math.min);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Teste Completo!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          _buildResultCard('Score Final', '${gameState.currentScore} pontos', Colors.orange),
          const SizedBox(height: 12),
          _buildResultCard('Reação Média', '${avgReaction.round()}ms', Colors.blue),
          const SizedBox(height: 12),
          _buildResultCard('Melhor Reação', '${bestReaction}ms', Colors.green),
        ],
      ),
    );
  }

  /// Card de resultado
  Widget _buildResultCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Jogo falhou
  Widget _buildGameFailed() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: const Icon(
              Icons.close,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tempo Esgotado!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ========== LÓGICA DO JOGO ==========

  /// Iniciar jogo
  void _startGame() {
    setState(() {
      _isGameStarted = true;
    });
    
    ref.read(gameSessionProvider(GameType.reaction).notifier)
        .startGame(difficulty: widget.difficulty);
  }

  /// Target clicado
  void _onTargetTapped(GameState gameState) {
    final gameNotifier = ref.read(gameSessionProvider(GameType.reaction).notifier);
    final showTarget = gameState.gameData['showTarget'] ?? false;
    final isWaiting = gameState.gameData['isWaiting'] ?? false;
    
    if (isWaiting) {
      // Clicou muito cedo - penalizar
      gameNotifier.updateScore(-50);
      return;
    }
    
    if (!showTarget) {
      // Não há target para clicar
      return;
    }
    
    // Calcular tempo de reação
    final roundStartTime = gameState.gameData['roundStartTime'] as int;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final reactionTime = currentTime - roundStartTime;
    
    // Calcular pontos baseado no tempo de reação
    int points = _calculatePoints(reactionTime);
    gameNotifier.updateScore(points);
    
    // Atualizar dados do jogo
    final reactions = List<int>.from(gameState.gameData['reactions'] ?? []);
    reactions.add(reactionTime);
    
    gameNotifier.updateGameData({
      'reactions': reactions,
      'showTarget': false,
      'totalMoves': (gameState.gameData['totalMoves'] ?? 0) + 1,
    });
    
    // Animações
    _targetController.reverse();
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
    
    // Próximo round ou finalizar
    final currentRound = gameState.gameData['currentRound'] as int;
    final totalRounds = gameState.gameData['rounds'] as int;
    
    if (currentRound + 1 >= totalRounds) {
      // Finalizar jogo
      _completeGame(gameNotifier);
    } else {
      // Próximo round
      gameNotifier.updateGameData({'currentRound': currentRound + 1});
      _generateRandomColor();
      _startNextRound();
    }
  }

  /// Calcular pontos baseado no tempo de reação
  int _calculatePoints(int reactionTimeMs) {
    if (reactionTimeMs < 200) return 200; // Reação excelente
    if (reactionTimeMs < 300) return 150; // Reação boa
    if (reactionTimeMs < 500) return 100; // Reação ok
    if (reactionTimeMs < 800) return 50;  // Reação lenta
    return 10; // Reação muito lenta
  }

  /// Iniciar próximo round
  void _startNextRound() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        final gameNotifier = ref.read(gameSessionProvider(GameType.reaction).notifier);
        gameNotifier.updateGameData({
          'isWaiting': true,
          'showTarget': false,
        });
        
        // Configurar próximo round (feito pelo provider)
      }
    });
  }

  /// Completar jogo
  void _completeGame(GameSessionNotifier gameNotifier) async {
    final result = await gameNotifier.finishGame(success: true);
    if (result != null) {
      widget.onGameCompleted(result);
    }
  }

  /// Gerar cor aleatória para o target
  void _generateRandomColor() {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    
    setState(() {
      _targetColor = colors[math.Random().nextInt(colors.length)];
    });
  }

  /// Obter reação média
  String _getAverageReaction(GameState gameState) {
    final reactions = gameState.gameData['reactions'] as List<int>? ?? [];
    if (reactions.isEmpty) return '-';
    
    final avg = reactions.reduce((a, b) => a + b) / reactions.length;
    return '${avg.round()}ms';
  }
}

extension on GameSessionNotifier {
  /// Iniciar próximo round de reação
  void startReactionRound() {
    // Esta extensão seria implementada no provider principal
    // Por agora, mantemos a lógica no widget
  }
}