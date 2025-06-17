// lib/screens/enhanced_connection_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/providers/test_session_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/utils/helpers.dart';
import 'package:unlock/widgtes/animated_button.dart';
import 'package:unlock/widgtes/custom_card.dart';

class EnhancedConnectionTestScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> chosenConnection;
  final List<String> userInterests;

  const EnhancedConnectionTestScreen({
    super.key,
    required this.chosenConnection,
    required this.userInterests,
  });

  @override
  ConsumerState<EnhancedConnectionTestScreen> createState() =>
      _EnhancedConnectionTestScreenState();
}

class _EnhancedConnectionTestScreenState
    extends ConsumerState<EnhancedConnectionTestScreen>
    with TickerProviderStateMixin {
  late AnimationController _questionController;
  late AnimationController _gameController;
  late AnimationController _resultController;
  late AnimationController _progressController;

  late Animation<double> _questionFadeAnimation;
  late Animation<Offset> _questionSlideAnimation;
  late Animation<double> _gameScaleAnimation;
  late Animation<double> _resultFadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
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

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _questionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOut),
    );

    _questionSlideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _questionController, curve: Curves.easeOut),
        );

    _gameScaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _gameController, curve: Curves.easeInOut),
    );

    _resultFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _questionController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final testSessionState = ref.watch(testSessionProvider);
    final authState = ref.watch(authProvider);

    return PopScope(
      canPop:
          testSessionState.phase == TestPhase.completed ||
          testSessionState.phase == TestPhase.result,
      onPopInvoked: (didPop) {
        if (!didPop && testSessionState.hasActiveSession) {
          _showExitConfirmDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Testando com ${widget.chosenConnection['nome'].toString().split(' ')[0]}',
          ),
          elevation: 0,
          leading:
              testSessionState.phase == TestPhase.completed ||
                  testSessionState.phase == TestPhase.result
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/home'),
                )
              : null,
          automaticallyImplyLeading: false,
          actions: [
            if (testSessionState.hasActiveSession &&
                testSessionState.phase != TestPhase.result)
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: _showTestInfo,
              ),
          ],
        ),
        body: _buildBody(testSessionState, authState.user),
      ),
    );
  }

  Widget _buildBody(TestSessionState testSessionState, UserModel? currentUser) {
    if (testSessionState.error != null) {
      return _buildErrorView(testSessionState.error!);
    }

    switch (testSessionState.phase) {
      case TestPhase.waiting:
        return _buildWaitingView();
      case TestPhase.questions:
        return _buildQuestionsView(testSessionState);
      case TestPhase.miniGame:
        return _buildMiniGameView(testSessionState);
      case TestPhase.result:
        return _buildResultView(testSessionState, currentUser);
      case TestPhase.completed:
        return _buildCompletedView(testSessionState);
    }
  }

  // ============== WAITING VIEW ==============
  Widget _buildWaitingView() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Conectando com o outro usuário...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Aguarde enquanto sincronizamos o teste.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============== QUESTIONS VIEW ==============
  Widget _buildQuestionsView(TestSessionState testSessionState) {
    if (testSessionState.questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentQuestion =
        testSessionState.currentQuestionIndex <
            testSessionState.questions.length
        ? testSessionState.questions[testSessionState.currentQuestionIndex]
        : null;

    if (currentQuestion == null) {
      return _buildWaitingForOtherUserView();
    }

    final progress =
        (testSessionState.currentQuestionIndex + 1) /
        testSessionState.questions.length;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(progress),
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
            'Pergunta ${testSessionState.currentQuestionIndex + 1}/${testSessionState.questions.length}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Question card
          Expanded(
            child: FadeTransition(
              opacity: _questionFadeAnimation,
              child: SlideTransition(
                position: _questionSlideAnimation,
                child: _buildQuestionCard(currentQuestion),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(TestQuestion question) {
    return CustomCard(
      borderRadius: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.quiz,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question.text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Column(
            children: question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: () => _answerQuestion(index),
                  backgroundColor: _getOptionColor(index),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '${String.fromCharCode(65 + index)}. $option',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForOtherUserView() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.schedule, size: 64, color: Colors.blue.shade600),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aguardando o outro usuário',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Você completou suas perguntas!\nEsperando a resposta da outra pessoa.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          LinearProgressIndicator(
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
        ],
      ),
    );
  }

  // ============== MINI GAME VIEW ==============
  Widget _buildMiniGameView(TestSessionState testSessionState) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _gameScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _gameScaleAnimation.value,
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
            '🎮 Mini-Jogo Colaborativo!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Trabalhem juntos no quebra-cabeça colaborativo.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Check if user already completed mini-game
          if (testSessionState.miniGameResults.containsKey(
            ref.read(authProvider).user?.uid,
          ))
            _buildMiniGameCompletedView()
          else
            SizedBox(
              width: double.infinity,
              child: AnimatedButton(
                onPressed: _startMiniGame,
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Iniciar Mini-Jogo',
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
      ),
    );
  }

  Widget _buildMiniGameCompletedView() {
    return CustomCard(
      borderRadius: 0,
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 48, color: Colors.green.shade600),
          const SizedBox(height: 16),
          Text(
            '✅ Mini-jogo Completo!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aguardando o outro usuário finalizar.',
            style: TextStyle(fontSize: 14, color: Colors.green.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============== RESULT VIEW ==============
  Widget _buildResultView(
    TestSessionState testSessionState,
    UserModel? currentUser,
  ) {
    final passed = testSessionState.result == TestResult.passed;
    final score = testSessionState.compatibilityScore;

    return Container(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _resultFadeAnimation,
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
                  color: passed
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  passed ? Icons.check_circle : Icons.cancel,
                  size: 80,
                  color: passed ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              passed ? '🎉 Conexão Validada!' : '😔 Conexão Não Realizada',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: passed ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: passed ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: passed ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Score de Compatibilidade',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: passed
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${score.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: passed
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              passed
                  ? 'Vocês têm ótima compatibilidade! Seus perfis reais foram liberados.'
                  : 'Não foi desta vez, mas não desanime! Há muitas outras pessoas esperando por você.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            if (passed) ...[
              _buildUnlockedProfilesView(currentUser),
              const SizedBox(height: 24),
              _buildSuccessActions(),
            ] else ...[
              _buildFailureActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedProfilesView(UserModel? currentUser) {
    return CustomCard(
      borderRadius: 0,
      child: Column(
        children: [
          const Text(
            'Perfis Liberados:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  AppHelpers.buildUserAvatar(
                    avatarId: currentUser?.avatar ?? '',
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
                    avatarId: widget.chosenConnection['avatarId'] ?? '',
                    radius: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.chosenConnection['nome'].toString().split(' ')[0],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: AnimatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go('/chat-screen', extra: widget.chosenConnection);
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              context.go('/other-perfil', extra: widget.chosenConnection);
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
      ],
    );
  }

  Widget _buildFailureActions() {
    return SizedBox(
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
            Icon(Icons.home, size: 20),
            SizedBox(width: 8),
            Text(
              'Voltar ao Início',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ============== COMPLETED VIEW ==============
  Widget _buildCompletedView(TestSessionState testSessionState) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 24),
          const Text(
            'Teste Finalizado',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Obrigado por participar do teste de compatibilidade!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: () => context.go('/home'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              child: const Text('Voltar ao Início'),
            ),
          ),
        ],
      ),
    );
  }

  // ============== ERROR VIEW ==============
  Widget _buildErrorView(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 24),
          const Text(
            'Erro no Teste',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedButton(
                  onPressed: () {
                    ref.read(testSessionProvider.notifier).clearError();
                    // Tentar reiniciar o teste
                  },
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  child: const Text('Tentar Novamente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============== HELPER WIDGETS ==============

  Widget _buildProgressIndicator(double progress) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).toInt()}% completo',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ============== ACTION METHODS ==============

  Future<void> _answerQuestion(int answerIndex) async {
    HapticFeedback.selectionClick();

    final success = await ref
        .read(testSessionProvider.notifier)
        .answerQuestion(answerIndex);

    if (success) {
      // Animar transição para próxima pergunta
      _questionController.reset();
      _questionController.forward();
    } else {
      // Mostrar erro
      if (mounted) {
        AppHelpers.showCustomSnackBar(
          context,
          'Erro ao enviar resposta. Tente novamente.',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  Future<void> _startMiniGame() async {
    // Navegar para o mini-jogo colaborativo
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CollaborativePuzzleGame()),
    );

    if (result != null && mounted) {
      // Enviar resultado do mini-jogo
      await ref
          .read(testSessionProvider.notifier)
          .submitMiniGameResult(result, result ? 100 : 0);
    }
  }

  void _showExitConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Teste?'),
        content: const Text(
          'Se você sair agora, o teste será cancelado e não poderá ser retomado. Tem certeza?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar Teste'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(testSessionProvider.notifier).endSession();
              context.go('/home');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _showTestInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como funciona o teste'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Respondam às perguntas de compatibilidade'),
            SizedBox(height: 8),
            Text('2. Joguem o mini-jogo colaborativo'),
            SizedBox(height: 8),
            Text('3. Aguardem o resultado final'),
            SizedBox(height: 16),
            Text(
              'É necessário 65% de compatibilidade para desbloquear os perfis reais.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Color _getOptionColor(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    return colors[index % colors.length];
  }

  @override
  void dispose() {
    _questionController.dispose();
    _gameController.dispose();
    _resultController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

// ============== COLLABORATIVE PUZZLE GAME ==============
class CollaborativePuzzleGame extends StatefulWidget {
  const CollaborativePuzzleGame({super.key});

  @override
  State<CollaborativePuzzleGame> createState() =>
      _CollaborativePuzzleGameState();
}

class _CollaborativePuzzleGameState extends State<CollaborativePuzzleGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _gameCompleted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _simulateGame();
  }

  void _simulateGame() async {
    _animationController.repeat();

    // Simular jogo por alguns segundos
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _gameCompleted = true;
      });
      _animationController.stop();

      // Auto-retornar com resultado após 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context, true); // Sucesso simulado
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('🧩 Quebra-Cabeça Colaborativo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_gameCompleted) ...[
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2 * 3.14159,
                      child: Icon(
                        Icons.extension,
                        size: 80,
                        color: Colors.purple.shade300,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Resolvendo quebra-cabeça...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Trabalhem juntos para completar o desafio!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 24),
                const Text(
                  '🎉 Quebra-cabeça Completo!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Parabéns! Vocês trabalharam muito bem juntos.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
