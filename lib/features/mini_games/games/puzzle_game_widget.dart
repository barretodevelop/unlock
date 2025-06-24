// lib/features/mini_games/games/puzzle_game_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/mini_game_model.dart';
import 'package:unlock/providers/mini_game_provider.dart';

/// Widget do jogo de puzzle
class PuzzleGameWidget extends ConsumerStatefulWidget {
  final GameDifficulty difficulty;
  final Function(GameResult) onGameCompleted;

  const PuzzleGameWidget({
    super.key,
    required this.difficulty,
    required this.onGameCompleted,
  });

  @override
  ConsumerState<PuzzleGameWidget> createState() => _PuzzleGameWidgetState();
}

class _PuzzleGameWidgetState extends ConsumerState<PuzzleGameWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late List<AnimationController> _pieceControllers;
  late List<Animation<Offset>> _slideAnimations;

  bool _isGameStarted = false;
  int? _selectedPiece;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🧩 PuzzleGame: Iniciado', data: {
      'difficulty': widget.difficulty.label,
    });

    // Configurar animações
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Inicializar controladores das peças
    _initializePieceAnimations();

    // Animação cíclica
    _pulseController.repeat(reverse: true);
  }

  void _initializePieceAnimations() {
    final pieceCount = GameConfig.forType(
      GameType.puzzle, 
      difficulty: widget.difficulty,
    ).customParams['pieceCount'] as int;

    _pieceControllers = List.generate(
      pieceCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );

    _slideAnimations = _pieceControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    for (final controller in _pieceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameSessionProvider(GameType.puzzle));

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
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildInfoItem(
            icon: Icons.extension,
            label: 'Score',
            value: gameState.currentScore.toString(),
            color: Colors.green,
          ),
          const SizedBox(width: 24),
          _buildInfoItem(
            icon: Icons.swap_horiz,
            label: 'Movimentos',
            value: (gameState.gameData['totalMoves'] ?? 0).toString(),
            color: Colors.blue,
          ),
          const SizedBox(width: 24),
          _buildInfoItem(
            icon: Icons.timer,
            label: 'Tempo',
            value: _formatTime(gameState.elapsed),
            color: Colors.orange,
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
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.extension,
                    size: 64,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Quebra-Cabeça',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'Montar Puzzle',
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
            Icons.extension,
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
            '1. Clique em uma peça para selecioná-la\n'
            '2. Clique em outra peça para trocar posições\n'
            '3. Organize em ordem crescente para vencer!',
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

    return Column(
      children: [
        _buildGameStatus(gameState),
        const SizedBox(height: 24),
        Expanded(
          child: _buildPuzzleGrid(gameState),
        ),
        const SizedBox(height: 16),
        _buildActionButtons(gameState),
      ],
    );
  }

  /// Status do jogo
  Widget _buildGameStatus(GameState gameState) {
    final solved = gameState.gameData['solved'] ?? false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: solved 
            ? Colors.green.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: solved 
              ? Colors.green.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            solved ? Icons.check_circle : Icons.extension,
            color: solved ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            solved ? 'Puzzle Resolvido!' : 'Organize as peças em ordem',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: solved ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  /// Grid do puzzle
  Widget _buildPuzzleGrid(GameState gameState) {
    final gridSize = gameState.gameData['gridSize'] as int;
    final pieces = gameState.gameData['pieces'] as List<int>;

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
        itemCount: pieces.length,
        itemBuilder: (context, index) {
          final pieceValue = pieces[index];
          final isSelected = _selectedPiece == index;
          final isCorrectPosition = pieceValue == index;
          
          return _buildPuzzlePiece(
            index: index,
            value: pieceValue + 1, // +1 para exibição (1-based)
            isSelected: isSelected,
            isCorrectPosition: isCorrectPosition,
            onTap: () => _onPieceTapped(index),
          );
        },
      ),
    );
  }

  /// Peça individual do puzzle
  Widget _buildPuzzlePiece({
    required int index,
    required int value,
    required bool isSelected,
    required bool isCorrectPosition,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: index < _slideAnimations.length ? _slideAnimations[index] : AlwaysStoppedAnimation(Offset.zero),
      builder: (context, child) {
        return SlideTransition(
          position: index < _slideAnimations.length ? _slideAnimations[index] : AlwaysStoppedAnimation(Offset.zero),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [Colors.green, Colors.green.shade300]
                      : isCorrectPosition
                          ? [Colors.blue.withOpacity(0.8), Colors.blue.withOpacity(0.6)]
                          : [Colors.grey.shade300, Colors.grey.shade200],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.green
                      : isCorrectPosition
                          ? Colors.blue
                          : Colors.grey,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected || isCorrectPosition
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                    if (isCorrectPosition) ...[
                      const SizedBox(height: 2),
                      Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Botões de ação
  Widget _buildActionButtons(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shufflePuzzle,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.shuffle),
              label: const Text('Embaralhar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _checkSolution,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Verificar'),
            ),
          ),
        ],
      ),
    );
  }

  /// Jogo completado
  Widget _buildGameCompleted(GameState gameState) {
    final totalMoves = gameState.gameData['totalMoves'] ?? 0;
    final efficiency = _calculateEfficiency(gameState);
    
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
            'Puzzle Resolvido!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          _buildResultCard('Score Final', '${gameState.currentScore} pontos', Colors.green),
          const SizedBox(height: 12),
          _buildResultCard('Movimentos', '$totalMoves', Colors.blue),
          const SizedBox(height: 12),
          _buildResultCard('Tempo', _formatTime(gameState.elapsed), Colors.orange),
          const SizedBox(height: 12),
          _buildResultCard('Eficiência', '${(efficiency * 100).round()}%', Colors.purple),
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

  // ========== LÓGICA DO JOGO ==========

  /// Iniciar jogo
  void _startGame() {
    setState(() {
      _isGameStarted = true;
    });
    
    ref.read(gameSessionProvider(GameType.puzzle).notifier)
        .startGame(difficulty: widget.difficulty);
    
    // Animar entrada das peças
    _animatePiecesIn();
  }

  /// Animar entrada das peças
  void _animatePiecesIn() async {
    for (int i = 0; i < _pieceControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && i < _pieceControllers.length) {
        _pieceControllers[i].forward();
      }
    }
  }

  /// Peça clicada
  void _onPieceTapped(int index) {
    if (_selectedPiece == null) {
      // Selecionar primeira peça
      setState(() {
        _selectedPiece = index;
      });
    } else if (_selectedPiece == index) {
      // Deselecionar
      setState(() {
        _selectedPiece = null;
      });
    } else {
      // Trocar peças
      _swapPieces(_selectedPiece!, index);
      setState(() {
        _selectedPiece = null;
      });
    }
  }

  /// Trocar peças
  void _swapPieces(int index1, int index2) {
    final gameNotifier = ref.read(gameSessionProvider(GameType.puzzle).notifier);
    final gameState = ref.read(gameSessionProvider(GameType.puzzle));
    
    final pieces = List<int>.from(gameState.gameData['pieces']);
    
    // Trocar peças
    final temp = pieces[index1];
    pieces[index1] = pieces[index2];
    pieces[index2] = temp;
    
    // Atualizar estado
    gameNotifier.updateGameData({
      'pieces': pieces,
      'totalMoves': (gameState.gameData['totalMoves'] ?? 0) + 1,
    });
    
    // Pontuar movimento
    gameNotifier.updateScore(10);
    
    // Verificar se resolveu automaticamente
    if (_isPuzzleSolved(pieces)) {
      _solvePuzzle();
    }
  }

  /// Embaralhar puzzle
  void _shufflePuzzle() {
    final gameNotifier = ref.read(gameSessionProvider(GameType.puzzle).notifier);
    final gameState = ref.read(gameSessionProvider(GameType.puzzle));
    
    final pieces = List<int>.from(gameState.gameData['pieces']);
    pieces.shuffle();
    
    gameNotifier.updateGameData({
      'pieces': pieces,
      'solved': false,
    });
    
    setState(() {
      _selectedPiece = null;
    });
  }

  /// Verificar solução
  void _checkSolution() {
    final gameState = ref.read(gameSessionProvider(GameType.puzzle));
    final pieces = gameState.gameData['pieces'] as List<int>;
    
    if (_isPuzzleSolved(pieces)) {
      _solvePuzzle();
    } else {
      // Mostrar feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puzzle ainda não está resolvido. Continue tentando!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Verificar se puzzle está resolvido
  bool _isPuzzleSolved(List<int> pieces) {
    for (int i = 0; i < pieces.length; i++) {
      if (pieces[i] != i) {
        return false;
      }
    }
    return true;
  }

  /// Resolver puzzle
  void _solvePuzzle() {
    final gameNotifier = ref.read(gameSessionProvider(GameType.puzzle).notifier);
    
    // Bonus por resolver
    gameNotifier.updateScore(500);
    
    // Marcar como resolvido
    gameNotifier.updateGameData({'solved': true});
    
    // Finalizar jogo
    _completeGame(gameNotifier);
  }

  /// Completar jogo
  void _completeGame(GameSessionNotifier gameNotifier) async {
    final result = await gameNotifier.finishGame(success: true);
    if (result != null) {
      widget.onGameCompleted(result);
    }
  }

  /// Calcular eficiência
  double _calculateEfficiency(GameState gameState) {
    final pieces = gameState.gameData['pieces'] as List<int>? ?? [];
    final totalMoves = gameState.gameData['totalMoves'] ?? 1;
    final optimalMoves = pieces.length * 2; // Estimativa
    
    return math.min(1.0, optimalMoves / totalMoves);
  }

  /// Formatar tempo
  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}