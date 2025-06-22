// lib/features/games/screens/puzzle_game_screen.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/features/games/widgets/reward_animation_controller.dart';
import 'package:unlock/features/games/widgets/reward_gain_overlay.dart';
import 'package:unlock/features/rewards/models/reward_model.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
import 'package:unlock/models/game_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Representa uma peça do quebra-cabeça
class PuzzlePiece {
  final int value; // O número da peça (1-8)
  final Color color;

  PuzzlePiece({required this.value, required this.color});
}

/// Tela do jogo de Quebra-Cabeça.
///
/// Um jogo de puzzle deslizante onde o jogador deve organizar
/// as peças numeradas em ordem crescente.
class PuzzleGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const PuzzleGameScreen({super.key, required this.game});

  @override
  ConsumerState<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends ConsumerState<PuzzleGameScreen>
    with TickerProviderStateMixin {
  final _rewardAnimationController = RewardAnimationController();
  late AnimationController _celebrationController;

  static const int gridSize = 3; // 3x3 grid
  static const int totalPieces = gridSize * gridSize;

  List<PuzzlePiece?> _pieces = [];
  int _emptyPosition = totalPieces - 1; // Última posição é vazia
  int _moves = 0;
  bool _isCompleted = false;
  bool _isFinishing = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _initializePuzzle();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _initializePuzzle() {
    // Cria as peças do puzzle (1 a 8, sendo a última posição vazia)
    _pieces = List.generate(totalPieces, (index) {
      if (index == totalPieces - 1) return null; // Posição vazia

      return PuzzlePiece(value: index + 1, color: _getColorForPiece(index));
    });

    // Embaralha o puzzle
    _shufflePuzzle();
  }

  Color _getColorForPiece(int index) {
    final colors = [
      Colors.red.shade300,
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
      Colors.amber.shade300,
    ];
    return colors[index % colors.length];
  }

  void _shufflePuzzle() {
    final random = Random();

    // Faz 200 movimentos aleatórios válidos para garantir que o puzzle seja bem embaralhado
    for (int i = 0; i < 200; i++) {
      final validMoves = _getValidMoves();
      if (validMoves.isNotEmpty) {
        final randomMove = validMoves[random.nextInt(validMoves.length)];
        _movePieceInternal(randomMove);
      }
    }

    setState(() {
      _moves = 0; // Reset move count after shuffling
    });
  }

  List<int> _getValidMoves() {
    final validMoves = <int>[];
    final row = _emptyPosition ~/ gridSize;
    final col = _emptyPosition % gridSize;

    // Verifica posições adjacentes
    final directions = [
      [-1, 0], // Cima
      [1, 0], // Baixo
      [0, -1], // Esquerda
      [0, 1], // Direita
    ];

    for (final direction in directions) {
      final newRow = row + direction[0];
      final newCol = col + direction[1];

      if (newRow >= 0 &&
          newRow < gridSize &&
          newCol >= 0 &&
          newCol < gridSize) {
        validMoves.add(newRow * gridSize + newCol);
      }
    }

    return validMoves;
  }

  // Movimento interno (usado para embaralhamento)
  void _movePieceInternal(int position) {
    if (!_getValidMoves().contains(position)) return;

    // Troca a peça com a posição vazia
    final piece = _pieces[position];
    _pieces[_emptyPosition] = piece;
    _pieces[position] = null;
    _emptyPosition = position;
  }

  // Movimento do jogador (com contagem e verificação)
  void _movePiece(int position) {
    if (!_getValidMoves().contains(position) || _isCompleted) return;

    setState(() {
      _movePieceInternal(position);
      _moves++;
    });

    _checkIfCompleted();
  }

  void _checkIfCompleted() {
    bool isComplete = true;

    // Verifica se cada peça está na posição correta
    for (int i = 0; i < totalPieces - 1; i++) {
      final piece = _pieces[i];
      if (piece == null || piece.value != i + 1) {
        isComplete = false;
        break;
      }
    }

    // Verifica se a última posição está vazia
    if (_pieces[totalPieces - 1] != null) {
      isComplete = false;
    }

    if (isComplete && !_isCompleted) {
      setState(() => _isCompleted = true);
      _celebrationController.forward();
      _finishGame();
    }
  }

  void _finishGame() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Calcula recompensas baseadas na performance
    final timeElapsed = DateTime.now().difference(_startTime!).inSeconds;
    final efficiency = _calculateEfficiency(timeElapsed, _moves);

    final baseXp = widget.game.baseRewards[RewardType.xp] ?? 0;
    final baseGems = widget.game.baseRewards[RewardType.gems] ?? 0;

    final xpEarned = (baseXp * efficiency).round();
    final gemsEarned = (baseGems * efficiency).round();
    final coinsEarned = _moves < 20 ? 15 : (_moves < 30 ? 10 : 5);

    // Aguarda a animação de celebração
    await Future.delayed(const Duration(seconds: 1));

    // Concede as recompensas
    await ref
        .read(rewardsProvider.notifier)
        .grantGameRewards(
          widget.game,
          user,
          xpAmount: xpEarned,
          coinsAmount: coinsEarned,
          gemsAmount: gemsEarned,
        );

    // Mostra as recompensas
    _rewardAnimationController.show(
      RewardAnimationValues(xp: xpEarned, coins: coinsEarned, gems: gemsEarned),
    );

    // Mostra dialog de resultado
    _showCompletionDialog(timeElapsed, xpEarned, coinsEarned, gemsEarned);
  }

  double _calculateEfficiency(int timeSeconds, int moves) {
    // Eficiência baseada no tempo (menor tempo = maior eficiência)
    final timeEfficiency = (60.0 / (timeSeconds + 30)).clamp(0.3, 1.0);

    // Eficiência baseada nos movimentos (menos movimentos = maior eficiência)
    final moveEfficiency = (20.0 / (moves + 10)).clamp(0.3, 1.0);

    return (timeEfficiency + moveEfficiency) / 2;
  }

  void _showCompletionDialog(int timeSeconds, int xp, int coins, int gems) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Parabéns!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Puzzle completo!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildStatCard('Movimentos', _moves.toString()),
            const SizedBox(height: 8),
            _buildStatCard('Tempo', _formatTime(timeSeconds)),
            const SizedBox(height: 16),
            if (xp > 0 || coins > 0 || gems > 0) ...[
              const Divider(),
              Text(
                'Recompensas:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (xp > 0) _buildRewardChip('${xp}XP', Icons.star),
                  if (coins > 0)
                    _buildRewardChip('${coins}🪙', Icons.monetization_on),
                  if (gems > 0) _buildRewardChip('${gems}💎', Icons.diamond),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _resetPuzzle(),
            child: const Text('Jogar Novamente'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.goNamed('games');
            },
            child: const Text('Voltar aos Jogos'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardChip(String text, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _resetPuzzle() {
    Navigator.of(context).pop(); // Fecha o dialog
    setState(() {
      _isCompleted = false;
      _isFinishing = false;
      _moves = 0;
      _emptyPosition = totalPieces - 1;
      _startTime = DateTime.now();
    });
    _celebrationController.reset();
    _initializePuzzle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetPuzzle,
            tooltip: 'Reiniciar Puzzle',
          ),
        ],
      ),
      body: RewardGainOverlay(
        controller: _rewardAnimationController,
        child: Column(
          children: [
            _buildGameInfo(),
            Expanded(child: Center(child: _buildPuzzleGrid())),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    final timeElapsed = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoCard('Movimentos', _moves.toString(), Icons.touch_app),
          _buildInfoCard('Tempo', _formatTime(timeElapsed), Icons.timer),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleGrid() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_celebrationController.value * 0.1),
          child: Container(
            margin: const EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: totalPieces,
                itemBuilder: (context, index) {
                  return _buildPuzzleTile(index);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPuzzleTile(int position) {
    final piece = _pieces[position];
    final isEmpty = piece == null;
    final isValidMove = _getValidMoves().contains(position);

    return GestureDetector(
      onTap: isEmpty ? null : () => _movePiece(position),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isEmpty
              ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
              : piece!.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !isEmpty && isValidMove
                ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
            width: !isEmpty && isValidMove ? 2 : 1,
          ),
          boxShadow: isEmpty
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isEmpty
            ? Center(
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  size: 32,
                ),
              )
            : Center(
                child: Text(
                  piece!.value.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Toque nas peças destacadas para movê-las e organize os números de 1 a 8!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
