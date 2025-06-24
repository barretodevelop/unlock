// lib/features/mini_games/games/memory_game_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/mini_game_model.dart';
import 'package:unlock/providers/mini_game_provider.dart';

/// Widget do jogo de memória
class MemoryGameWidget extends ConsumerStatefulWidget {
  final GameDifficulty difficulty;
  final Function(GameResult) onGameCompleted;

  const MemoryGameWidget({
    super.key,
    required this.difficulty,
    required this.onGameCompleted,
  });

  @override
  ConsumerState<MemoryGameWidget> createState() => _MemoryGameWidgetState();
}

class _MemoryGameWidgetState extends ConsumerState<MemoryGameWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _gridController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  bool _isGameStarted = false;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🧠 MemoryGame: Iniciado', data: {
      'difficulty': widget.difficulty.label,
    });

    // Configurar animações
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _gridController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gridController, curve: Curves.elasticOut),
    );

    // Configurar animações cíclicas
    _pulseController.repeat(reverse: true);
    _gridController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameSessionProvider(GameType.memory));

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

  /// Header do jogo com informações
  Widget _buildGameHeader(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildInfoItem(
            icon: Icons.psychology,
            label: 'Score',
            value: gameState.currentScore.toString(),
            color: Colors.purple,
          ),
          const SizedBox(width: 24),
          if (gameState.hasTimeLimit) ...[
            _buildInfoItem(
              icon: Icons.timer,
              label: 'Tempo',
              value: _formatTime(gameState.timeRemaining ?? Duration.zero),
              color: Colors.orange,
            ),
            const SizedBox(width: 24),
          ],
          _buildInfoItem(
            icon: Icons.trending_up,
            label: 'Sequência',
            value: '${gameState.gameData['currentStep'] ?? 0}/${(gameState.gameData['sequence'] as List?)?.length ?? 0}',
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

  /// Tela inicial do jogo
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
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.purple.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    size: 64,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Jogo de Memória',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
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
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'Iniciar Jogo',
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

  /// Instruções do jogo
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
          Icon(
            Icons.lightbulb_outline,
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
            '1. Memorize a sequência que será mostrada\n'
            '2. Reproduza a sequência clicando nos botões\n'
            '3. Complete a sequência para ganhar pontos!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Conteúdo principal do jogo
  Widget _buildGameContent(GameState gameState) {
    if (gameState.status == GameStatus.completed) {
      return _buildGameCompleted(gameState);
    }

    if (gameState.status == GameStatus.failed) {
      return _buildGameFailed();
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            children: [
              _buildGameStatus(gameState),
              const SizedBox(height: 24),
              Expanded(
                child: _buildMemoryGrid(gameState),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Status do jogo
  Widget _buildGameStatus(GameState gameState) {
    final isShowing = gameState.gameData['isShowing'] ?? false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isShowing 
            ? Colors.orange.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isShowing 
              ? Colors.orange.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isShowing ? Icons.visibility : Icons.touch_app,
            color: isShowing ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            isShowing ? 'Memorize a sequência!' : 'Reproduza a sequência!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isShowing ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  /// Grid de memória
  Widget _buildMemoryGrid(GameState gameState) {
    final gridSize = gameState.gameData['gridSize'] as int;
    final sequence = gameState.gameData['sequence'] as List<int>;
    final currentStep = gameState.gameData['currentStep'] as int;
    final isShowing = gameState.gameData['isShowing'] as bool;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: gridSize * gridSize,
        itemBuilder: (context, index) {
          return _buildMemoryTile(
            index: index,
            isHighlighted: _shouldHighlightTile(index, sequence, currentStep, isShowing),
            isEnabled: !isShowing && gameState.canPlay,
            onTap: () => _onTileTapped(index),
          );
        },
      ),
    );
  }

  /// Tile individual da memória
  Widget _buildMemoryTile({
    required int index,
    required bool isHighlighted,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: isEnabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isHighlighted 
                    ? Colors.purple
                    : isEnabled 
                        ? Colors.purple.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighlighted 
                      ? Colors.purple
                      : Colors.purple.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: isHighlighted ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ] : [],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted 
                        ? Colors.white
                        : Colors.purple,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Jogo completado
  Widget _buildGameCompleted(GameState gameState) {
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
            'Parabéns!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você completou a sequência!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Score: ${gameState.currentScore} pontos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
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
          const SizedBox(height: 8),
          Text(
            'Tente novamente!',
            style: Theme.of(context).textTheme.titleMedium,
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
    
    ref.read(gameSessionProvider(GameType.memory).notifier)
        .startGame(difficulty: widget.difficulty);
  }

  /// Verificar se tile deve ser destacado
  bool _shouldHighlightTile(int index, List<int> sequence, int currentStep, bool isShowing) {
    if (isShowing) {
      // Durante a exibição, mostrar toda a sequência até o step atual
      return sequence.take(currentStep + 1).contains(index);
    } else {
      // Durante a reprodução, não destacar
      return false;
    }
  }

  /// Tile clicado
  void _onTileTapped(int index) {
    final gameNotifier = ref.read(gameSessionProvider(GameType.memory).notifier);
    final gameState = ref.read(gameSessionProvider(GameType.memory));
    
    final sequence = gameState.gameData['sequence'] as List<int>;
    final currentStep = gameState.gameData['currentStep'] as int;
    
    // Verificar se o tile correto foi clicado
    if (sequence[currentStep] == index) {
      // Correto!
      gameNotifier.updateScore(100);
      gameNotifier.updateGameData({
        'currentStep': currentStep + 1,
        'correctMoves': (gameState.gameData['correctMoves'] ?? 0) + 1,
        'totalMoves': (gameState.gameData['totalMoves'] ?? 0) + 1,
      });
      
      // Verificar se completou a sequência
      if (currentStep + 1 >= sequence.length) {
        _completeGame(gameNotifier);
      }
    } else {
      // Incorreto - terminar jogo
      gameNotifier.updateGameData({
        'totalMoves': (gameState.gameData['totalMoves'] ?? 0) + 1,
      });
      gameNotifier.finishGame(success: false);
    }
  }

  /// Completar jogo
  void _completeGame(GameSessionNotifier gameNotifier) async {
    final result = await gameNotifier.finishGame(success: true);
    if (result != null) {
      widget.onGameCompleted(result);
    }
  }

  /// Formatar tempo
  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}