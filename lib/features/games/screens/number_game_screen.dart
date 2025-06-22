// lib/features/games/screens/number_game_screen.dart

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

/// Representa um número no grid
class NumberTile {
  final int number;
  final int correctPosition;
  int currentPosition;
  bool isCorrect;

  NumberTile({
    required this.number,
    required this.correctPosition,
    required this.currentPosition,
    this.isCorrect = false,
  });
}

/// Tela do Jogo de Sequência Numérica.
///
/// O jogador deve ordenar números de 1 a 15 em sequência,
/// tocando nos números na ordem correta o mais rápido possível.
class NumberGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const NumberGameScreen({super.key, required this.game});

  @override
  ConsumerState<NumberGameScreen> createState() => _NumberGameScreenState();
}

class _NumberGameScreenState extends ConsumerState<NumberGameScreen>
    with TickerProviderStateMixin {
  final _rewardAnimationController = RewardAnimationController();
  late AnimationController _correctController;
  late AnimationController _wrongController;
  late AnimationController _completeController;

  List<NumberTile> _numbers = [];
  int _currentTarget = 1;
  int _moves = 0;
  bool _isGameStarted = false;
  bool _isGameComplete = false;
  bool _isFinishing = false;
  DateTime? _startTime;
  DateTime? _lastClickTime;
  List<double> _reactionTimes = [];

  static const int _maxNumber = 25;
  static const int _gridSize = 5; // 5x5 grid

  @override
  void initState() {
    super.initState();

    _correctController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _wrongController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _completeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _initializeGame();
  }

  @override
  void dispose() {
    _correctController.dispose();
    _wrongController.dispose();
    _completeController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    _numbers = List.generate(_maxNumber, (index) {
      return NumberTile(
        number: index + 1,
        correctPosition: index,
        currentPosition: index,
      );
    });

    _shuffleNumbers();

    setState(() {
      _currentTarget = 1;
      _moves = 0;
      _isGameStarted = false;
      _isGameComplete = false;
      _isFinishing = false;
      _reactionTimes.clear();
    });
  }

  void _shuffleNumbers() {
    final random = Random();

    // Embaralha as posições dos números
    final positions = List.generate(_maxNumber, (index) => index);
    positions.shuffle(random);

    for (int i = 0; i < _numbers.length; i++) {
      _numbers[i].currentPosition = positions[i];
      _numbers[i].isCorrect = false;
    }
  }

  void _startGame() {
    setState(() {
      _isGameStarted = true;
      _startTime = DateTime.now();
      _lastClickTime = DateTime.now();
    });
  }

  void _onNumberTapped(NumberTile numberTile) {
    if (!_isGameStarted || _isGameComplete) return;

    _moves++;

    if (numberTile.number == _currentTarget) {
      // Número correto!
      _onCorrectNumber(numberTile);
    } else {
      // Número incorreto
      _onWrongNumber();
    }
  }

  void _onCorrectNumber(NumberTile numberTile) {
    // Calcula tempo de reação
    final now = DateTime.now();
    if (_lastClickTime != null) {
      final reactionTime =
          now.difference(_lastClickTime!).inMilliseconds / 1000.0;
      _reactionTimes.add(reactionTime);
    }
    _lastClickTime = now;

    setState(() {
      numberTile.isCorrect = true;
      _currentTarget++;
    });

    _correctController.forward().then((_) {
      _correctController.reset();
    });

    if (_currentTarget > _maxNumber) {
      _completeGame();
    }
  }

  void _onWrongNumber() {
    _wrongController.forward().then((_) {
      _wrongController.reset();
    });
  }

  void _completeGame() {
    setState(() {
      _isGameComplete = true;
    });

    _completeController.forward();
    _finishGame();
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

    final avgReactionTime = _reactionTimes.isNotEmpty
        ? _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length
        : 3.0;

    final efficiency = _calculateEfficiency(
      timeElapsed,
      _moves,
      avgReactionTime,
    );

    final baseXp = widget.game.baseRewards[RewardType.xp] ?? 0;
    final baseCoins = widget.game.baseRewards[RewardType.coins] ?? 0;

    final xpEarned = (baseXp * efficiency).round();
    final coinsEarned = (baseCoins * efficiency).round();
    final gemsEarned = efficiency >= 0.9 ? 4 : (efficiency >= 0.7 ? 2 : 1);

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

    _showCompletionDialog(
      timeElapsed,
      avgReactionTime,
      xpEarned,
      coinsEarned,
      gemsEarned,
    );
  }

  double _calculateEfficiency(
    int timeSeconds,
    int moves,
    double avgReactionTime,
  ) {
    // Eficiência baseada no tempo total (ideal: 30 segundos)
    final timeEfficiency = (30 / timeSeconds.clamp(15, 120)).clamp(0.3, 1.2);

    // Eficiência baseada na precisão (movimentos ideais = 25)
    final moveEfficiency = (25 / moves).clamp(0.3, 1.0);

    // Eficiência baseada no tempo de reação (ideal: < 1 segundo)
    final reactionEfficiency = (1.0 / avgReactionTime.clamp(0.5, 5.0)).clamp(
      0.3,
      1.0,
    );

    return ((timeEfficiency * 0.4) +
            (moveEfficiency * 0.4) +
            (reactionEfficiency * 0.2))
        .clamp(0.3, 1.0);
  }

  void _showCompletionDialog(
    int timeElapsed,
    double avgReactionTime,
    int xp,
    int coins,
    int gems,
  ) {
    final accuracy = ((25 / _moves) * 100).round();
    final minutes = timeElapsed ~/ 60;
    final seconds = timeElapsed % 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.numbers, size: 64, color: Colors.purple),
            const SizedBox(height: 16),
            Text(
              'Sequência Completa!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Você ordenou todos os números!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGameStat(
              'Tempo Total',
              '${minutes}:${seconds.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 8),
            _buildGameStat('Movimentos', _moves.toString()),
            const SizedBox(height: 8),
            _buildGameStat('Precisão', '$accuracy%'),
            const SizedBox(height: 8),
            _buildGameStat(
              'Reação Média',
              '${avgReactionTime.toStringAsFixed(2)}s',
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
    _completeController.reset();
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
            if (!_isGameStarted) _buildInstructions(),
            Expanded(child: _buildNumberGrid()),
            if (!_isGameStarted) _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    final timeElapsed = _isGameStarted && _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoCard(
            'Próximo',
            _currentTarget > _maxNumber ? 'FIM' : _currentTarget.toString(),
            Icons.numbers,
          ),
          _buildInfoCard('Movimentos', _moves.toString(), Icons.touch_app),
          _buildInfoCard(
            'Tempo',
            '${timeElapsed ~/ 60}:${(timeElapsed % 60).toString().padLeft(2, '0')}',
            Icons.timer,
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

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Toque nos números em sequência',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Comece pelo 1 e vá até o 25 o mais rápido possível!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberGrid() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridSize,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: _maxNumber,
        itemBuilder: (context, index) {
          final numberTile = _numbers[index];
          return _buildNumberTile(numberTile);
        },
      ),
    );
  }

  Widget _buildNumberTile(NumberTile numberTile) {
    Color backgroundColor;
    Color textColor = Colors.white;

    if (numberTile.isCorrect) {
      backgroundColor = Colors.green;
    } else if (numberTile.number == _currentTarget && _isGameStarted) {
      backgroundColor = Colors.blue;
    } else {
      backgroundColor = Theme.of(context).colorScheme.primary;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _correctController,
        _wrongController,
        _completeController,
      ]),
      builder: (context, child) {
        double scale = 1.0;

        if (numberTile.isCorrect && _correctController.isAnimating) {
          scale = 1.0 + (0.2 * _correctController.value);
        } else if (numberTile.number == _currentTarget - 1 &&
            _wrongController.isAnimating) {
          // Shake effect for wrong taps
          final shakeValue = sin(_wrongController.value * pi * 8) * 0.1;
          return Transform.translate(
            offset: Offset(shakeValue * 10, 0),
            child: _buildTileContent(numberTile, backgroundColor, textColor),
          );
        }

        if (_isGameComplete && _completeController.isAnimating) {
          scale = 1.0 + (0.1 * sin(_completeController.value * pi * 2));
        }

        return Transform.scale(
          scale: scale,
          child: _buildTileContent(numberTile, backgroundColor, textColor),
        );
      },
    );
  }

  Widget _buildTileContent(
    NumberTile numberTile,
    Color backgroundColor,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: () => _onNumberTapped(numberTile),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
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
            numberTile.number.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _startGame,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar Sequência'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
