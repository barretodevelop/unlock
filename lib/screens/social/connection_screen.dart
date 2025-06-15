import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/data/mock_data_provider.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/screens/games/quebra_cabeca_colaborativo.dart';
import 'package:unlock/utils/helpers.dart';
import 'package:unlock/widgets/animated/animated_button.dart';

final MockDataProvider dataProvider = MockDataProvider();

class ConnectionTestScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> chosenConnection;
  final List<String> userInterests;

  const ConnectionTestScreen({
    super.key,
    required this.chosenConnection,
    required this.userInterests,
  });

  @override
  ConsumerState<ConnectionTestScreen> createState() =>
      _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends ConsumerState<ConnectionTestScreen>
    with TickerProviderStateMixin {
  late AnimationController _questionController;
  late AnimationController _gameController;
  late AnimationController _resultController;

  int _currentPhase = 0; // 0: Questões, 1: Mini-Jogo, 2: Resultado
  int _currentQuestionIndex = 0;
  int _questionsCorrect = 0;
  bool _miniGameResult = false;
  bool _testPassedFinal = false;

  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();

    _questionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _gameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _generateQuestions();
    _questionController.forward();
  }

  void _generateQuestions() {
    final connectionInterests =
        widget.chosenConnection['interesses'] as List<String>;
    final commonInterests = widget.userInterests
        .where((interest) => connectionInterests.contains(interest))
        .toList();

    if (commonInterests.isNotEmpty) {
      _questions = dataProvider.getQuestionsByCategory(
        commonInterests.first,
        count: 2,
      );
    } else {
      _questions = dataProvider.getQuestionsByCategory('Geral', count: 2);
    }
  }

  void _answerQuestion(bool isCorrect) {
    if (isCorrect) {
      _questionsCorrect++;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _questionController.reset();
      _questionController.forward();
    } else {
      _startMiniGame();
    }
  }

  void _startMiniGame() async {
    setState(() {
      _currentPhase = 1;
    });

    _gameController.forward();

    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    _miniGameResult =
        random.nextDouble() < MockDataProvider.appConfig['miniGameSuccessRate'];

    // ✅ Agora espera o resultado do mini game
    final colaborativoResult = await jogarQuebraCabecaColaborativo(context);

    // ✅ Combine resultado da sequência + colaboração
    final questionScore = _questionsCorrect / _questions.length;
    final finalScore =
        (questionScore * 0.6) +
        ((_miniGameResult ? 0.2 : 0) + (colaborativoResult ? 0.2 : 0));

    _testPassedFinal = finalScore >= 0.5; // 50% para passar

    setState(() {
      _currentPhase = 2;
    });

    _resultController.forward();
  }

  Future<bool> jogarQuebraCabecaColaborativo(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuebraCabecaColaborativo(), // sua tela do jogo
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Testando com ${widget.chosenConnection['nome'].toString().split(' ')[0]}',
        ),
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildCurrentPhase(),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_currentPhase) {
      case 0:
        return _buildQuestionsPhase();
      case 1:
        return _buildMiniGamePhase();
      case 2:
        return _buildResultPhase(ref);
      default:
        return Container();
    }
  }

  Widget _buildQuestionsPhase() {
    final question = _questions[_currentQuestionIndex];

    return Container(
      key: const ValueKey('questions'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Questões de Compatibilidade',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Pergunta ${_currentQuestionIndex + 1}/${_questions.length}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          Expanded(
            child: FadeTransition(
              opacity: _questionController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(_questionController),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          question['text'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedButton(
                                onPressed: () => _answerQuestion(false),
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                child: const Text('Resposta A'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AnimatedButton(
                                onPressed: () => _answerQuestion(true),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                child: const Text('Resposta B'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGamePhase() {
    return Container(
      key: const ValueKey('minigame'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _gameController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_gameController.value * 0.1),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withOpacity(0.3),
                        Colors.blue.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.videogame_asset,
                      size: 60,
                      color: Colors.purple,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Mini-Jogo de Compatibilidade!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Testando química através de um jogo rápido...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          CircularProgressIndicator(color: Theme.of(context).primaryColor),
        ],
      ),
    );
  }

  Widget _buildResultPhase(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Container(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _resultController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: _resultController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _testPassedFinal
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  _testPassedFinal ? Icons.check_circle : Icons.cancel,
                  size: 80,
                  color: _testPassedFinal ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _testPassedFinal
                  ? '🎉 Conexão Validada!'
                  : '😔 Conexão Não Realizada',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _testPassedFinal ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _testPassedFinal
                  ? 'Vocês têm ótima compatibilidade! Seus avatares reais foram liberados.'
                  : 'Não foi desta vez, mas não desanime! Há muitas outras pessoas esperando por você.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_testPassedFinal) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Perfis Liberados:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            AppHelpers.buildUserAvatar(
                              avatarId: user?.avatar ?? '',
                              borderId: '', // currentUser.equippedBorder,
                              radius: 30,
                            ),
                            const SizedBox(height: 8),
                            const Text('Você'),
                          ],
                        ),
                        const Icon(Icons.favorite, color: Colors.red, size: 24),
                        Column(
                          children: [
                            AppHelpers.buildUserAvatar(
                              avatarId: widget.chosenConnection['avatarId'],
                              borderId: widget.chosenConnection['borderId'],
                              radius: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.chosenConnection['nome'].toString().split(
                                ' ',
                              )[0],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedButton(
                      onPressed: () {
                        // currentUser.updateStats(connections: 1);
                        // Navigator.pushReplacement(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => ChatScreen(
                        //       connectionData: widget.chosenConnection,
                        //       isRealConnection: true,
                        //     ),
                        //   ),
                        // );
                        context.go('/chat-screen');
                      },
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Começar Conversa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go(
                          '/other-perfil',
                          extra: widget.chosenConnection,
                        );
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => OtherUserProfileScreen(
                        //       connectionData: widget.chosenConnection,
                        //     ),
                        //   ),
                        // );
                      },
                      icon: const Icon(Icons.person_outline),
                      label: Text(
                        'Ver Perfil de ${widget.chosenConnection['nome'].toString().split(' ')[0]}',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go('/home');
                      },
                      icon: const Icon(Icons.person_outline),
                      label: Text('Voltar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sair',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _gameController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}
