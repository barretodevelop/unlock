// lib/features/games/screens/snake_game_screen.dart

import 'dart:async';
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

/// Representa uma posição no grid
class Position {
  final int x;
  final int y;

  Position(this.x, this.y);

  @override
  bool operator ==(Object other) {
    return other is Position && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// Direções possíveis do movimento
enum Direction { up, down, left, right }

/// Tela do Jogo Snake.
///
/// Jogo clássico onde o jogador controla uma cobra que cresce
/// ao comer frutas, evitando colidir com as paredes ou consigo mesma.
class SnakeGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const SnakeGameScreen({super.key, required this.game});

  @override
  ConsumerState<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends ConsumerState<SnakeGameScreen>
    with TickerProviderStateMixin {
  final _rewardAnimationController = RewardAnimationController();
  late AnimationController _growController;
  late AnimationController _gameOverController;

  Timer? _gameTimer;
  List<Position> _snake = [];
  Position? _food;
  Direction _direction = Direction.right;
  Direction? _nextDirection;
  int _score = 0;
  bool _isGameOver = false;
  bool _isPlaying = false;
  bool _isFinishing = false;
  DateTime? _startTime;

  static const int _gridSize = 20;
  static const int _initialSpeed = 300; // ms entre movimentos
  int _currentSpeed = _initialSpeed;

  @override
  void initState() {
    super.initState();

    _growController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _gameOverController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _initializeGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _growController.dispose();
    _gameOverController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    _snake = [Position(5, 10), Position(4, 10), Position(3, 10)];
    _generateFood();
    _direction = Direction.right;
    _nextDirection = null;
    _score = 0;
    _isGameOver = false;
    _isPlaying = false;
    _currentSpeed = _initialSpeed;

    setState(() {});
  }

  void _generateFood() {
    final random = Random();
    Position newFood;

    do {
      newFood = Position(random.nextInt(_gridSize), random.nextInt(_gridSize));
    } while (_snake.contains(newFood));

    _food = newFood;
  }

  void _startGame() {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _startTime = DateTime.now();
    });

    _gameTimer = Timer.periodic(Duration(milliseconds: _currentSpeed), (timer) {
      _moveSnake();
    });
  }

  void _pauseGame() {
    setState(() => _isPlaying = false);
    _gameTimer?.cancel();
  }

  void _moveSnake() {
    if (_nextDirection != null) {
      _direction = _nextDirection!;
      _nextDirection = null;
    }

    final head = _snake.first;
    Position newHead;

    switch (_direction) {
      case Direction.up:
        newHead = Position(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Position(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Position(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Position(head.x + 1, head.y);
        break;
    }

    // Verifica colisões
    if (_checkCollision(newHead)) {
      _gameOver();
      return;
    }

    _snake.insert(0, newHead);

    // Verifica se comeu a comida
    if (newHead == _food) {
      _ateFood();
    } else {
      _snake.removeLast();
    }

    setState(() {});
  }

  bool _checkCollision(Position newHead) {
    // Colisão com paredes
    if (newHead.x < 0 ||
        newHead.x >= _gridSize ||
        newHead.y < 0 ||
        newHead.y >= _gridSize) {
      return true;
    }

    // Colisão com o próprio corpo
    if (_snake.contains(newHead)) {
      return true;
    }

    return false;
  }

  void _ateFood() {
    _score += 10;
    _growController.forward().then((_) => _growController.reset());
    _generateFood();

    // Aumenta velocidade gradualmente
    if (_score % 50 == 0 && _currentSpeed > 100) {
      _currentSpeed -= 20;
      _gameTimer?.cancel();
      _gameTimer = Timer.periodic(Duration(milliseconds: _currentSpeed), (
        timer,
      ) {
        _moveSnake();
      });
    }
  }

  void _gameOver() {
    _gameTimer?.cancel();
    setState(() {
      _isGameOver = true;
      _isPlaying = false;
    });

    _gameOverController.forward();
    _finishGame();
  }

  void _changeDirection(Direction newDirection) {
    if (!_isPlaying || _isGameOver) return;

    // Não pode ir na direção oposta
    if ((_direction == Direction.up && newDirection == Direction.down) ||
        (_direction == Direction.down && newDirection == Direction.up) ||
        (_direction == Direction.left && newDirection == Direction.right) ||
        (_direction == Direction.right && newDirection == Direction.left)) {
      return;
    }

    _nextDirection = newDirection;
  }

  void _finishGame() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Calcula recompensas baseadas na performance
    final timeElapsed = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    final efficiency = _calculateEfficiency(_score, _snake.length, timeElapsed);

    final baseXp = widget.game.baseRewards[RewardType.xp] ?? 0;
    final baseCoins = widget.game.baseRewards[RewardType.coins] ?? 0;

    final xpEarned = (baseXp * efficiency).round();
    final coinsEarned = (baseCoins * efficiency).round();
    final gemsEarned = _score >= 200
        ? 5
        : (_score >= 100 ? 3 : (_score >= 50 ? 1 : 0));

    // Aguarda um momento
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

    _showCompletionDialog(xpEarned, coinsEarned, gemsEarned);
  }

  double _calculateEfficiency(int score, int length, int timeSeconds) {
    // Pontuação base
    final scoreEfficiency = (score / 100).clamp(0.3, 2.0);

    // Tamanho da cobra
    final lengthEfficiency = ((length - 3) / 10).clamp(0.3, 1.5);

    // Tempo de sobrevivência
    final timeEfficiency = (timeSeconds / 60).clamp(0.3, 1.2);

    return ((scoreEfficiency + lengthEfficiency + timeEfficiency) / 3).clamp(
      0.3,
      1.5,
    );
  }

  void _showCompletionDialog(int xp, int coins, int gems) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gamepad, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Game Over!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Você jogou muito bem!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGameStat('Pontuação Final', _score.toString()),
            const SizedBox(height: 8),
            _buildGameStat('Tamanho da Cobra', _snake.length.toString()),
            const SizedBox(height: 8),
            _buildGameStat(
              'Comidas Coletadas',
              ((_score / 10).round()).toString(),
            ),
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
            onPressed: () => _resetGame(),
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

  Widget _buildGameStat(String label, String value) {
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

  void _resetGame() {
    Navigator.of(context).pop();
    _gameTimer?.cancel();
    _gameOverController.reset();
    setState(() => _isFinishing = false);
    _initializeGame();
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
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: _isGameOver
                ? null
                : (_isPlaying ? _pauseGame : _startGame),
            tooltip: _isPlaying ? 'Pausar' : 'Iniciar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Reiniciar',
          ),
        ],
      ),
      body: RewardGainOverlay(
        controller: _rewardAnimationController,
        child: Column(
          children: [
            _buildGameInfo(),
            Expanded(child: _buildGameBoard()),
            _buildControls(),
            if (!_isPlaying && !_isGameOver) _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoCard('Pontos', _score.toString(), Icons.star),
          _buildInfoCard('Tamanho', _snake.length.toString(), Icons.timeline),
          _buildInfoCard(
            'Velocidade',
            '${(400 - _currentSpeed) ~/ 20}',
            Icons.speed,
          ),
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

  Widget _buildGameBoard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize,
          ),
          itemCount: _gridSize * _gridSize,
          itemBuilder: (context, index) {
            final x = index % _gridSize;
            final y = index ~/ _gridSize;
            final position = Position(x, y);

            return _buildGridCell(position);
          },
        ),
      ),
    );
  }

  Widget _buildGridCell(Position position) {
    Color cellColor = Colors.black;
    Widget? cellContent;

    if (_snake.contains(position)) {
      // Corpo da cobra
      final isHead = _snake.first == position;
      cellColor = isHead ? Colors.lightGreen : Colors.green;

      if (isHead) {
        cellContent = const Center(
          child: Icon(Icons.circle, color: Colors.white, size: 8),
        );
      }
    } else if (_food == position) {
      // Comida
      cellColor = Colors.red;
      cellContent = AnimatedBuilder(
        animation: _growController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (0.3 * _growController.value),
            child: const Center(
              child: Icon(Icons.apple, color: Colors.white, size: 12),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _gameOverController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            color: _isGameOver
                ? cellColor.withOpacity(0.5 + (0.5 * _gameOverController.value))
                : cellColor,
            borderRadius: BorderRadius.circular(1),
          ),
          child: cellContent,
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Seta para cima
          GestureDetector(
            onTap: () => _changeDirection(Direction.up),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Setas laterais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => _changeDirection(Direction.left),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_left,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _changeDirection(Direction.right),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_right,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Seta para baixo
          GestureDetector(
            onTap: () => _changeDirection(Direction.down),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _startGame,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar Jogo'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
    );
  }
}
