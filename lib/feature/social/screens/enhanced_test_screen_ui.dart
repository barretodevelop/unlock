// lib/feature/games/social/screens/enhanced_test_screen_ui.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/providers/enhanced_test_session_provider.dart';
import 'package:unlock/feature/social/providers/test_session_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/widgtes/animated_button.dart';
import 'package:unlock/widgtes/custom_card.dart';

class EnhancedTestScreenUI extends ConsumerStatefulWidget {
  final Map<String, dynamic> chosenConnection;
  final List<String> userInterests;
  final String inviteId;

  const EnhancedTestScreenUI({
    super.key,
    required this.chosenConnection,
    required this.userInterests,
    required this.inviteId,
  });

  @override
  ConsumerState<EnhancedTestScreenUI> createState() =>
      _EnhancedTestScreenUIState();
}

class _EnhancedTestScreenUIState extends ConsumerState<EnhancedTestScreenUI>
    with TickerProviderStateMixin {
  // ============== ANIMATION CONTROLLERS ==============
  late AnimationController _questionController;
  late AnimationController _progressController;
  late AnimationController _gameController;
  late AnimationController _resultController;
  late AnimationController _pulseController;

  // ============== ANIMATIONS ==============
  late Animation<double> _questionFade;
  late Animation<Offset> _questionSlide;
  late Animation<double> _progressAnimation;
  late Animation<double> _gameScale;
  late Animation<double> _resultFade;
  late Animation<double> _pulseAnimation;

  // ============== STATE ==============
  int? _selectedAnswer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startRealSession();
  }

  void _initializeAnimations() {
    // Controllers
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _gameController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animations
    _questionFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOut),
    );
    _questionSlide =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _questionController, curve: Curves.easeOut),
        );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _gameScale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _gameController, curve: Curves.easeInOut),
    );

    _resultFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start initial animations
    _questionController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _startRealSession() async {
    final otherUser = UserModel(
      uid: widget.chosenConnection['id'],
      username: widget.chosenConnection['nome'] ?? 'Usuário',
      displayName: widget.chosenConnection['nome'] ?? 'Usuário',
      avatar: widget.chosenConnection['avatarId'] ?? 'default',
      email: '',
      level: 1,
      xp: 0,
      coins: 0,
      gems: 0,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      aiConfig: {},
      interesses: List<String>.from(
        widget.chosenConnection['interesses'] ?? [],
      ),
    );

    await ref
        .read(enhancedTestSessionProvider.notifier)
        .startRealSession(inviteId: widget.inviteId, otherUser: otherUser);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _progressController.dispose();
    _gameController.dispose();
    _resultController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(enhancedTestSessionProvider);
    final authState = ref.watch(authProvider);

    return PopScope(
      canPop:
          testState.phase == TestPhase.completed ||
          testState.phase == TestPhase.result,
      onPopInvoked: (didPop) {
        if (!didPop && testState.hasActiveSession) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(testState),
        body: _buildBody(testState, authState.user),
      ),
    );
  }

  // ============== APP BAR ==============
  PreferredSizeWidget _buildAppBar(TestSessionState testState) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      leading:
          testState.phase == TestPhase.completed ||
              testState.phase == TestPhase.result
          ? Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => context.go('/home'),
              ),
            )
          : null,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teste com ${widget.chosenConnection['nome']?.toString().split(' ')[0] ?? 'Usuário'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (testState.questions.isNotEmpty)
            Text(
              'Pergunta ${testState.currentQuestionIndex + 1} de ${testState.questions.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
      actions: [
        if (testState.hasActiveSession &&
            testState.phase == TestPhase.questions)
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.help_outline, color: Colors.blue[700]),
              onPressed: _showTestInfo,
            ),
          ),
      ],
      bottom: testState.phase == TestPhase.questions
          ? _buildProgressBar(testState)
          : null,
    );
  }

  PreferredSize _buildProgressBar(TestSessionState testState) {
    final progress = testState.questions.isEmpty
        ? 0.0
        : testState.currentQuestionIndex / testState.questions.length;

    return PreferredSize(
      preferredSize: const Size.fromHeight(4),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: progress * _progressAnimation.value,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          );
        },
      ),
    );
  }

  // ============== BODY ==============
  Widget _buildBody(TestSessionState testState, UserModel? currentUser) {
    if (testState.error != null) {
      return _buildErrorView(testState.error!);
    }

    switch (testState.phase) {
      case TestPhase.waiting:
        return _buildWaitingView();
      case TestPhase.questions:
        return _buildQuestionsView(testState);
      case TestPhase.miniGame:
        return _buildMiniGameView(testState);
      case TestPhase.result:
        return _buildResultView(testState);
      case TestPhase.completed:
        return _buildCompletedView();
    }
  }

  // ============== WAITING VIEW ==============
  Widget _buildWaitingView() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sync, size: 60, color: Colors.blue[600]),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Sincronizando com o outro usuário...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Aguarde enquanto preparamos o teste de compatibilidade.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============== QUESTIONS VIEW ==============
  Widget _buildQuestionsView(TestSessionState testState) {
    if (testState.questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentQuestion =
        testState.currentQuestionIndex < testState.questions.length
        ? testState.questions[testState.currentQuestionIndex]
        : null;

    if (currentQuestion == null) {
      return const Center(child: Text('Todas as perguntas foram respondidas!'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _questionFade,
        child: SlideTransition(
          position: _questionSlide,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card da pergunta
              CustomCard(
                padding: const EdgeInsets.all(24),
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currentQuestion.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentQuestion.text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Opções de resposta
              ...currentQuestion.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedAnswer == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSubmitting
                            ? null
                            : () => _selectAnswer(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue[300]!
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.blue[600]
                                      : Colors.grey[300],
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.blue[700]
                                        : Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 32),

              // Botão de enviar
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: _selectedAnswer != null && !_isSubmitting
                      ? _submitAnswer
                      : null,
                  backgroundColor: _selectedAnswer != null
                      ? Colors.blue[600]!
                      : Colors.grey[300]!,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Confirmar Resposta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============== MINI GAME VIEW ==============
  Widget _buildMiniGameView(TestSessionState testState) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _gameScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _gameScale.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withOpacity(0.3),
                        Colors.blue.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.psychology,
                      size: 80,
                      color: Colors.purple,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          const Text(
            'Analisando Compatibilidade',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            testState.isLoading
                ? 'Aguardando o outro usuário finalizar...'
                : 'Calculando afinidade baseada nas respostas...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CircularProgressIndicator(color: Colors.purple[600], strokeWidth: 3),
        ],
      ),
    );
  }

  // ============== RESULT VIEW ==============
  Widget _buildResultView(TestSessionState testState) {
    final passed = testState.result == TestResult.passed;
    final score = testState.compatibilityScore;

    // Trigger result animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resultController.forward();
    });

    return Container(
      padding: const EdgeInsets.all(32),
      child: FadeTransition(
        opacity: _resultFade,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone do resultado
            ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: _resultController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: passed
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  border: Border.all(
                    color: passed ? Colors.green : Colors.orange,
                    width: 3,
                  ),
                ),
                child: Icon(
                  passed ? Icons.favorite : Icons.favorite_border,
                  size: 80,
                  color: passed ? Colors.green : Colors.orange,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Título
            Text(
              passed ? '💕 Conexão Desbloqueada!' : '🤝 Boa Tentativa!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: passed ? Colors.green[700] : Colors.orange[700],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Score card
            CustomCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 0,
              child: Column(
                children: [
                  Text(
                    'Compatibilidade',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${score.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: passed ? Colors.green[600] : Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passed
                        ? 'Vocês têm ótima afinidade!'
                        : 'Continue tentando com outros usuários!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Botões de ação
            if (passed) ...[
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: () => ref
                      .read(enhancedTestSessionProvider.notifier)
                      .navigateToChat(),
                  backgroundColor: Colors.green[600]!,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Iniciar Conversa',
                        style: TextStyle(
                          fontSize: 16,
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
                child: AnimatedButton(
                  onPressed: () => ref
                      .read(enhancedTestSessionProvider.notifier)
                      .navigateToUnlockedProfile(),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green[600]!,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ver Perfil Completo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: () => context.go('/home'),
                  backgroundColor: Colors.orange[600]!,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Buscar Outras Conexões',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Botão voltar
            SizedBox(
              width: double.infinity,
              child: AnimatedButton(
                onPressed: () => context.go('/home'),
                backgroundColor: Colors.grey[200]!,
                foregroundColor: Colors.grey[700]!,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Voltar ao Início',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== COMPLETED VIEW ==============
  Widget _buildCompletedView() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 100, color: Colors.green[600]),
          const SizedBox(height: 32),
          const Text(
            'Teste Finalizado',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Obrigado por participar do teste de compatibilidade!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: () => context.go('/home'),
              backgroundColor: Colors.blue[600]!,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                'Voltar ao Início',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============== ERROR VIEW ==============
  Widget _buildErrorView(String error) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: Colors.red[400]),
          const SizedBox(height: 32),
          const Text(
            'Erro no Teste',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: () => context.go('/home'),
              backgroundColor: Colors.red[600]!,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                'Voltar ao Início',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============== ACTIONS ==============
  void _selectAnswer(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = index;
    });
  }

  void _submitAnswer() async {
    if (_selectedAnswer == null || _isSubmitting) return;

    final testState = ref.read(enhancedTestSessionProvider);
    if (testState.questions.isEmpty ||
        testState.currentQuestionIndex >= testState.questions.length)
      return;

    setState(() {
      _isSubmitting = true;
    });

    final currentQuestion = testState.questions[testState.currentQuestionIndex];

    final success = await ref
        .read(enhancedTestSessionProvider.notifier)
        .submitRealAnswer(
          questionId: currentQuestion.id,
          selectedAnswer: _selectedAnswer!,
        );

    if (success) {
      // Reset para próxima pergunta
      setState(() {
        _selectedAnswer = null;
        _isSubmitting = false;
      });

      // Animar transição para próxima pergunta
      _questionController.reset();
      _questionController.forward();
      _progressController.forward();

      HapticFeedback.mediumImpact();
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Teste?'),
        content: const Text(
          'Se você sair agora, o progresso do teste será perdido. Tem certeza?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(enhancedTestSessionProvider.notifier).clearSession();
              context.go('/home');
            },
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
        title: const Text('Como Funciona o Teste'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Responda as perguntas com sinceridade\n'
              '• Não há respostas certas ou erradas\n'
              '• A compatibilidade é calculada comparando suas respostas\n'
              '• É necessário 65% ou mais para desbloquear a conexão\n'
              '• O resultado é baseado em afinidade real',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
