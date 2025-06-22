// lib/features/games/screens/math_game_screen.dart

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

/// Tipos de operação matemática
enum MathOperation {
  addition, // +
  subtraction, // -
  multiplication, // ×
  division, // ÷
}

/// Níveis de dificuldade
enum DifficultyLevel {
  easy, // Números 1-20
  medium, // Números 1-50
  hard, // Números 1-100
}

/// Representa um problema matemático
class MathProblem {
  final int number1;
  final int number2;
  final MathOperation operation;
  final int correctAnswer;
  final List<int> options;
  final DifficultyLevel difficulty;

  MathProblem({
    required this.number1,
    required this.number2,
    required this.operation,
    required this.correctAnswer,
    required this.options,
    required this.difficulty,
  });

  String get problemText {
    String operatorSymbol;
    switch (operation) {
      case MathOperation.addition:
        operatorSymbol = '+';
        break;
      case MathOperation.subtraction:
        operatorSymbol = '-';
        break;
      case MathOperation.multiplication:
        operatorSymbol = '×';
        break;
      case MathOperation.division:
        operatorSymbol = '÷';
        break;
    }
    return '$number1 $operatorSymbol $number2 = ?';
  }
}

/// Tela do Desafio Matemático.
///
/// Um jogo de matemática onde o jogador resolve problemas
/// de aritmética básica contra o tempo, com dificuldade crescente.
class MathGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const MathGameScreen({super.key, required this.game});

  @override
  ConsumerState<MathGameScreen> createState() => _MathGameScreenState();
}

class _MathGameScreenState extends ConsumerState<MathGameScreen>
    with TickerProviderStateMixin {
  final _rewardAnimationController = RewardAnimationController();
  late AnimationController _correctController;
  late AnimationController _wrongController;
  late AnimationController _timeController;

  DifficultyLevel _currentDifficulty = DifficultyLevel.easy;
  MathProblem? _currentProblem;
  Timer? _gameTimer;
  Timer? _problemTimer;

  int _score = 0;
  int _correctAnswers = 0;
  int _totalProblems = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _timeRemaining = 60; // segundos
  bool _isGameActive = false;
  bool _isFinishing = false;
  DateTime? _startTime;
  DateTime? _problemStartTime;
  List<double> _solveTimes = [];

  static const int _gameDuration = 60; // segundos
  static const int _problemTimeLimit = 10; // segundos por problema

  @override
  void initState() {
    super.initState();

    _correctController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _wrongController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _timeController = AnimationController(
      duration: Duration(seconds: _problemTimeLimit),
      vsync: this,
    );

    _generateNewProblem();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _problemTimer?.cancel();
    _correctController.dispose();
    _wrongController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _score = 0;
      _correctAnswers = 0;
      _totalProblems = 0;
      _streak = 0;
      _maxStreak = 0;
      _timeRemaining = _gameDuration;
      _currentDifficulty = DifficultyLevel.easy;
      _solveTimes.clear();
      _startTime = DateTime.now();
    });

    _generateNewProblem();
    _startGameTimer();
    _startProblemTimer();
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _timeRemaining--);

      if (_timeRemaining <= 0) {
        _endGame();
      }
    });
  }

  void _startProblemTimer() {
    _problemStartTime = DateTime.now();
    _timeController.reset();
    _timeController.forward();

    _problemTimer = Timer(Duration(seconds: _problemTimeLimit), () {
      if (_isGameActive) {
        _onAnswer(-1); // Timeout
      }
    });
  }

  void _generateNewProblem() {
    final random = Random();

    // Aumenta dificuldade baseado na pontuação
    if (_score >= 500 && _currentDifficulty == DifficultyLevel.easy) {
      _currentDifficulty = DifficultyLevel.medium;
    } else if (_score >= 1000 && _currentDifficulty == DifficultyLevel.medium) {
      _currentDifficulty = DifficultyLevel.hard;
    }

    // Define limite de números baseado na dificuldade
    int maxNumber;
    switch (_currentDifficulty) {
      case DifficultyLevel.easy:
        maxNumber = 20;
        break;
      case DifficultyLevel.medium:
        maxNumber = 50;
        break;
      case DifficultyLevel.hard:
        maxNumber = 100;
        break;
    }

    // Escolhe operação (mais multiplicação/divisão em níveis mais altos)
    List<MathOperation> availableOps;
    switch (_currentDifficulty) {
      case DifficultyLevel.easy:
        availableOps = [MathOperation.addition, MathOperation.subtraction];
        break;
      case DifficultyLevel.medium:
        availableOps = [
          MathOperation.addition,
          MathOperation.subtraction,
          MathOperation.multiplication,
        ];
        break;
      case DifficultyLevel.hard:
        availableOps = MathOperation.values;
        break;
    }

    final operation = availableOps[random.nextInt(availableOps.length)];

    int num1, num2, correctAnswer;

    switch (operation) {
      case MathOperation.addition:
        num1 = random.nextInt(maxNumber) + 1;
        num2 = random.nextInt(maxNumber) + 1;
        correctAnswer = num1 + num2;
        break;

      case MathOperation.subtraction:
        num1 = random.nextInt(maxNumber) + 1;
        num2 = random.nextInt(min(num1, maxNumber)) + 1;
        correctAnswer = num1 - num2;
        break;

      case MathOperation.multiplication:
        num1 = random.nextInt(min(maxNumber ~/ 4, 15)) + 1;
        num2 = random.nextInt(min(maxNumber ~/ 4, 15)) + 1;
        correctAnswer = num1 * num2;
        break;

      case MathOperation.division:
        correctAnswer = random.nextInt(min(maxNumber ~/ 4, 20)) + 1;
        num2 = random.nextInt(min(maxNumber ~/ 4, 15)) + 1;
        num1 = correctAnswer * num2;
        break;
    }

    // Gera opções de resposta
    final options = _generateOptions(correctAnswer, random);

    setState(() {
      _currentProblem = MathProblem(
        number1: num1,
        number2: num2,
        operation: operation,
        correctAnswer: correctAnswer,
        options: options,
        difficulty: _currentDifficulty,
      );
    });
  }

  List<int> _generateOptions(int correctAnswer, Random random) {
    final options = <int>[correctAnswer];

    // Gera 3 respostas incorretas
    while (options.length < 4) {
      int wrongAnswer;

      if (correctAnswer <= 10) {
        wrongAnswer = correctAnswer + random.nextInt(10) - 5;
      } else if (correctAnswer <= 100) {
        wrongAnswer = correctAnswer + random.nextInt(20) - 10;
      } else {
        wrongAnswer = correctAnswer + random.nextInt(50) - 25;
      }

      if (wrongAnswer > 0 && !options.contains(wrongAnswer)) {
        options.add(wrongAnswer);
      }
    }

    options.shuffle(random);
    return options;
  }

  void _onAnswer(int selectedAnswer) {
    if (!_isGameActive || _currentProblem == null) return;

    _problemTimer?.cancel();
    _timeController.stop();

    final isCorrect = selectedAnswer == _currentProblem!.correctAnswer;
    _totalProblems++;

    if (isCorrect) {
      _onCorrectAnswer();
    } else {
      _onWrongAnswer();
    }

    // Aguarda animação antes do próximo problema
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_isGameActive) {
        _generateNewProblem();
        _startProblemTimer();
      }
    });
  }

  void _onCorrectAnswer() {
    final solveTime =
        DateTime.now().difference(_problemStartTime!).inMilliseconds / 1000.0;
    _solveTimes.add(solveTime);

    _correctAnswers++;
    _streak++;
    _maxStreak = max(_maxStreak, _streak);

    // Pontuação baseada na dificuldade, velocidade e streak
    int basePoints = 10;
    switch (_currentDifficulty) {
      case DifficultyLevel.easy:
        basePoints = 10;
        break;
      case DifficultyLevel.medium:
        basePoints = 20;
        break;
      case DifficultyLevel.hard:
        basePoints = 30;
        break;
    }

    final speedBonus = max(0, (_problemTimeLimit - solveTime.ceil()) * 2);
    final streakBonus = min(_streak * 5, 50);
    final totalPoints = basePoints + speedBonus + streakBonus;

    setState(() => _score += totalPoints);

    _correctController.forward().then((_) => _correctController.reset());
  }

  void _onWrongAnswer() {
    setState(() => _streak = 0);
    _wrongController.forward().then((_) => _wrongController.reset());
  }

  void _endGame() {
    _gameTimer?.cancel();
    _problemTimer?.cancel();

    setState(() => _isGameActive = false);

    _finishGame();
  }

  void _finishGame() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Calcula estatísticas
    final accuracy = _totalProblems > 0
        ? _correctAnswers / _totalProblems
        : 0.0;
    final avgSolveTime = _solveTimes.isNotEmpty
        ? _solveTimes.reduce((a, b) => a + b) / _solveTimes.length
        : 10.0;

    // Calcula recompensas baseadas na performance
    final efficiency = _calculateEfficiency(
      _score,
      accuracy,
      avgSolveTime,
      _maxStreak,
    );

    final baseXp = widget.game.baseRewards[RewardType.xp] ?? 0;
    final baseGems = widget.game.baseRewards[RewardType.gems] ?? 0;

    final xpEarned = (baseXp * efficiency).round();
    final gemsEarned = (baseGems * efficiency).round();
    final coinsEarned = (_score / 20).round(); // 1 moeda a cada 20 pontos

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
      accuracy,
      avgSolveTime,
      xpEarned,
      coinsEarned,
      gemsEarned,
    );
  }

  double _calculateEfficiency(
    int score,
    double accuracy,
    double avgSolveTime,
    int maxStreak,
  ) {
    // Eficiência baseada na pontuação
    final scoreEfficiency = (score / 1000).clamp(0.3, 1.5);

    // Eficiência baseada na precisão
    final accuracyEfficiency = accuracy.clamp(0.3, 1.0);

    // Eficiência baseada na velocidade média
    final speedEfficiency = (5.0 / avgSolveTime.clamp(2.0, 10.0)).clamp(
      0.3,
      1.2,
    );

    // Eficiência baseada no streak máximo
    final streakEfficiency = (maxStreak / 10).clamp(0.3, 1.3);

    return ((scoreEfficiency * 0.3) +
            (accuracyEfficiency * 0.3) +
            (speedEfficiency * 0.2) +
            (streakEfficiency * 0.2))
        .clamp(0.3, 1.2);
  }

  void _showCompletionDialog(
    double accuracy,
    double avgSolveTime,
    int xp,
    int coins,
    int gems,
  ) {
    final accuracyPercent = (accuracy * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calculate, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Desafio Completo!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Você arrasou na matemática!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGameStat('Pontuação Final', _score.toString()),
            const SizedBox(height: 8),
            _buildGameStat(
              'Problemas Resolvidos',
              '$_correctAnswers/$_totalProblems',
            ),
            const SizedBox(height: 8),
            _buildGameStat('Precisão', '$accuracyPercent%'),
            const SizedBox(height: 8),
            _buildGameStat('Sequência Máxima', '${_maxStreak}x'),
            const SizedBox(height: 8),
            _buildGameStat(
              'Tempo Médio',
              '${avgSolveTime.toStringAsFixed(1)}s',
            ),
            const SizedBox(height: 8),
            _buildGameStat(
              'Nível Final',
              _getDifficultyName(_currentDifficulty),
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

  String _getDifficultyName(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Fácil';
      case DifficultyLevel.medium:
        return 'Médio';
      case DifficultyLevel.hard:
        return 'Difícil';
    }
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
    _problemTimer?.cancel();
    _timeController.reset();
    setState(() {
      _isGameActive = false;
      _isFinishing = false;
      _currentDifficulty = DifficultyLevel.easy;
    });
    _generateNewProblem();
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
            if (_isGameActive) _buildTimeProgress(),
            Expanded(child: _buildGameContent()),
            if (!_isGameActive && _currentProblem != null) _buildStartButton(),
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
          _buildInfoCard(
            'Acertos',
            '$_correctAnswers/$_totalProblems',
            Icons.check_circle,
          ),
          _buildInfoCard('Sequência', '${_streak}x', Icons.flash_on),
          _buildInfoCard('Tempo', '${_timeRemaining}s', Icons.timer),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tempo do Problema',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              AnimatedBuilder(
                animation: _timeController,
                builder: (context, child) {
                  final remaining =
                      (_problemTimeLimit * (1 - _timeController.value)).round();
                  return Text(
                    '${remaining}s',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: remaining <= 3 ? Colors.red : null,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _timeController,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: 1 - _timeController.value,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _timeController.value > 0.7 ? Colors.red : Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    if (_currentProblem == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDifficultyIndicator(),
          const SizedBox(height: 20),
          _buildProblemCard(),
          const SizedBox(height: 32),
          _buildAnswerOptions(),
        ],
      ),
    );
  }

  Widget _buildDifficultyIndicator() {
    Color difficultyColor;
    String difficultyText;

    switch (_currentDifficulty) {
      case DifficultyLevel.easy:
        difficultyColor = Colors.green;
        difficultyText = 'FÁCIL';
        break;
      case DifficultyLevel.medium:
        difficultyColor = Colors.orange;
        difficultyText = 'MÉDIO';
        break;
      case DifficultyLevel.hard:
        difficultyColor = Colors.red;
        difficultyText = 'DIFÍCIL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: difficultyColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: difficultyColor),
      ),
      child: Text(
        difficultyText,
        style: TextStyle(color: difficultyColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProblemCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_correctController, _wrongController]),
      builder: (context, child) {
        Color? backgroundColor;

        if (_correctController.isAnimating) {
          backgroundColor = Colors.green.withOpacity(
            0.3 * _correctController.value,
          );
        } else if (_wrongController.isAnimating) {
          backgroundColor = Colors.red.withOpacity(
            0.3 * _wrongController.value,
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _currentProblem!.problemText,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildAnswerOptions() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.0,
      ),
      itemCount: _currentProblem!.options.length,
      itemBuilder: (context, index) {
        final option = _currentProblem!.options[index];
        return _buildAnswerButton(option);
      },
    );
  }

  Widget _buildAnswerButton(int answer) {
    return ElevatedButton(
      onPressed: _isGameActive ? () => _onAnswer(answer) : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      child: Text(answer.toString()),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _startGame,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar Desafio'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
