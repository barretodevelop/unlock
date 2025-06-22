// lib/features/games/screens/quiz_game_screen.dart

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

/// Representa uma pergunta do quiz
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
  });
}

/// Tela do Quiz de Conhecimento.
///
/// Um jogo de perguntas e respostas com múltiplas escolhas
/// onde o jogador ganha pontos baseado na velocidade e precisão.
class QuizGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const QuizGameScreen({super.key, required this.game});

  @override
  ConsumerState<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends ConsumerState<QuizGameScreen>
    with TickerProviderStateMixin {
  final _rewardAnimationController = RewardAnimationController();
  late AnimationController _progressController;
  late AnimationController _feedbackController;

  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  bool _hasAnswered = false;
  bool _isFinishing = false;
  DateTime? _questionStartTime;
  DateTime? _gameStartTime;
  List<double> _answerTimes = [];

  static const int _totalQuestions = 10;
  static const int _timePerQuestion = 15; // segundos

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: Duration(seconds: _timePerQuestion),
      vsync: this,
    );

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _initializeGame();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    _questions = _generateQuestions();
    _gameStartTime = DateTime.now();
    _startQuestion();
  }

  List<QuizQuestion> _generateQuestions() {
    final random = Random();
    final allQuestions = _getAllQuestions();
    allQuestions.shuffle(random);
    return allQuestions.take(_totalQuestions).toList();
  }

  List<QuizQuestion> _getAllQuestions() {
    return [
      // Conhecimentos Gerais
      QuizQuestion(
        question: 'Qual é a capital do Brasil?',
        options: ['São Paulo', 'Rio de Janeiro', 'Brasília', 'Belo Horizonte'],
        correctIndex: 2,
        category: 'Geografia',
      ),
      QuizQuestion(
        question: 'Quantos continentes existem?',
        options: ['5', '6', '7', '8'],
        correctIndex: 2,
        category: 'Geografia',
      ),
      QuizQuestion(
        question: 'Qual é o maior planeta do sistema solar?',
        options: ['Terra', 'Saturno', 'Júpiter', 'Netuno'],
        correctIndex: 2,
        category: 'Ciências',
      ),
      QuizQuestion(
        question: 'Quem pintou a Mona Lisa?',
        options: ['Picasso', 'Van Gogh', 'Leonardo da Vinci', 'Michelangelo'],
        correctIndex: 2,
        category: 'Arte',
      ),
      QuizQuestion(
        question: 'Qual é o elemento químico representado por "O"?',
        options: ['Ouro', 'Oxigênio', 'Osmônio', 'Óleo'],
        correctIndex: 1,
        category: 'Química',
      ),
      QuizQuestion(
        question: 'Em que ano o homem pisou na Lua pela primeira vez?',
        options: ['1967', '1968', '1969', '1970'],
        correctIndex: 2,
        category: 'História',
      ),
      QuizQuestion(
        question: 'Qual é o animal terrestre mais rápido do mundo?',
        options: ['Leopardo', 'Guepardo', 'Leão', 'Tigre'],
        correctIndex: 1,
        category: 'Animais',
      ),
      QuizQuestion(
        question: 'Quantos lados tem um hexágono?',
        options: ['5', '6', '7', '8'],
        correctIndex: 1,
        category: 'Matemática',
      ),
      QuizQuestion(
        question: 'Qual é o idioma mais falado no mundo?',
        options: ['Inglês', 'Espanhol', 'Mandarim', 'Hindi'],
        correctIndex: 2,
        category: 'Linguística',
      ),
      QuizQuestion(
        question: 'Qual é o menor país do mundo?',
        options: ['Monaco', 'San Marino', 'Vaticano', 'Liechtenstein'],
        correctIndex: 2,
        category: 'Geografia',
      ),
      QuizQuestion(
        question: 'Qual é a fórmula da água?',
        options: ['CO2', 'H2O', 'NaCl', 'CH4'],
        correctIndex: 1,
        category: 'Química',
      ),
      QuizQuestion(
        question: 'Quantos ossos tem o corpo humano adulto?',
        options: ['186', '206', '226', '246'],
        correctIndex: 1,
        category: 'Biologia',
      ),
      QuizQuestion(
        question: 'Qual é a moeda do Japão?',
        options: ['Yuan', 'Won', 'Yen', 'Rupiah'],
        correctIndex: 2,
        category: 'Geografia',
      ),
      QuizQuestion(
        question: 'Quem escreveu "Dom Casmurro"?',
        options: [
          'José de Alencar',
          'Machado de Assis',
          'Clarice Lispector',
          'Guimarães Rosa',
        ],
        correctIndex: 1,
        category: 'Literatura',
      ),
      QuizQuestion(
        question: 'Qual é o resultado de 12 × 8?',
        options: ['84', '96', '104', '112'],
        correctIndex: 1,
        category: 'Matemática',
      ),
    ];
  }

  void _startQuestion() {
    setState(() {
      _hasAnswered = false;
      _questionStartTime = DateTime.now();
    });

    _progressController.reset();
    _progressController.forward();

    // Auto-avança se o tempo esgotar
    _progressController.addStatusListener(_onTimerComplete);
  }

  void _onTimerComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_hasAnswered) {
      _answerQuestion(-1); // -1 indica timeout
    }
  }

  void _answerQuestion(int selectedIndex) {
    if (_hasAnswered) return;

    setState(() => _hasAnswered = true);
    _progressController.removeStatusListener(_onTimerComplete);
    _progressController.stop();

    final question = _questions[_currentQuestionIndex];
    final isCorrect = selectedIndex == question.correctIndex;
    final timeElapsed = DateTime.now()
        .difference(_questionStartTime!)
        .inSeconds;

    _answerTimes.add(timeElapsed.toDouble());

    if (isCorrect) {
      _correctAnswers++;
      // Pontuação baseada na velocidade (mais pontos para respostas rápidas)
      final timeBonus = (_timePerQuestion - timeElapsed).clamp(
        0,
        _timePerQuestion,
      );
      _score += 100 + (timeBonus * 10).round();

      _feedbackController.forward();
    }

    // Mostra feedback visual
    Future.delayed(const Duration(milliseconds: 1500), () {
      _feedbackController.reset();
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
      _startQuestion();
    } else {
      _finishGame();
    }
  }

  void _finishGame() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Calcula recompensas baseadas na performance
    final accuracy = _correctAnswers / _totalQuestions;
    final avgTime = _answerTimes.isNotEmpty
        ? _answerTimes.reduce((a, b) => a + b) / _answerTimes.length
        : _timePerQuestion.toDouble();

    final efficiency = _calculateEfficiency(accuracy, avgTime);

    final baseXp = widget.game.baseRewards[RewardType.xp] ?? 0;
    final baseCoins = widget.game.baseRewards[RewardType.coins] ?? 0;

    final xpEarned = (baseXp * efficiency).round();
    final coinsEarned = (baseCoins * efficiency).round();
    final gemsEarned = accuracy >= 0.8 ? 3 : (accuracy >= 0.6 ? 2 : 1);

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

  double _calculateEfficiency(double accuracy, double avgTime) {
    final accuracyScore = accuracy;
    final speedScore = (_timePerQuestion - avgTime) / _timePerQuestion;
    return ((accuracyScore * 0.7) + (speedScore.clamp(0.0, 1.0) * 0.3)).clamp(
      0.3,
      1.0,
    );
  }

  void _showCompletionDialog(int xp, int coins, int gems) {
    final accuracy = (_correctAnswers / _totalQuestions * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Quiz Finalizado!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Você completou o desafio!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGameStat('Pontuação', _score.toString()),
            const SizedBox(height: 8),
            _buildGameStat('Acertos', '$_correctAnswers/$_totalQuestions'),
            const SizedBox(height: 8),
            _buildGameStat('Precisão', '$accuracy%'),
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
    setState(() {
      _isFinishing = false;
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _answerTimes.clear();
    });
    _initializeGame();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Reiniciar Jogo',
          ),
        ],
      ),
      body: RewardGainOverlay(
        controller: _rewardAnimationController,
        child: Column(
          children: [
            _buildGameInfo(),
            _buildProgressBar(),
            Expanded(child: _buildQuestionCard(question)),
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
          _buildInfoCard(
            'Pergunta',
            '${_currentQuestionIndex + 1}/$_totalQuestions',
            Icons.help,
          ),
          _buildInfoCard('Pontos', _score.toString(), Icons.star),
          _buildInfoCard(
            'Acertos',
            _correctAnswers.toString(),
            Icons.check_circle,
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

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tempo Restante'),
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  final remaining =
                      (_timePerQuestion * (1 - _progressController.value))
                          .round();
                  return Text(
                    '${remaining}s',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: remaining <= 5 ? Colors.red : null,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: 1 - _progressController.value,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progressController.value > 0.8 ? Colors.red : Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  question.category,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                question.question,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: question.options.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildOptionButton(question, index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(QuizQuestion question, int index) {
    final isCorrect = index == question.correctIndex;
    final showFeedback = _hasAnswered;

    Color? backgroundColor;
    Color? foregroundColor;

    if (showFeedback) {
      if (isCorrect) {
        backgroundColor = Colors.green;
        foregroundColor = Colors.white;
      } else {
        backgroundColor = Colors.red.withOpacity(0.3);
      }
    }

    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        return Transform.scale(
          scale: showFeedback && isCorrect
              ? 1.0 + (0.05 * _feedbackController.value)
              : 1.0,
          child: ElevatedButton(
            onPressed: _hasAnswered ? null : () => _answerQuestion(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '${String.fromCharCode(65 + index)}. ${question.options[index]}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.left,
            ),
          ),
        );
      },
    );
  }
}
