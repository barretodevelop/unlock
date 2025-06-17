// lib/feature/social/screens/enhanced_test_screen_ui.dart - VERSÃO FUNCIONAL
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/providers/enhanced_test_session_provider.dart';
import 'package:unlock/feature/social/providers/test_session_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/widgtes/animated_button.dart';

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
  late AnimationController _resultController;
  late AnimationController _pulseController;

  // ============== ANIMATIONS ==============
  late Animation<double> _questionFade;
  late Animation<Offset> _questionSlide;
  late Animation<double> _progressAnimation;
  late Animation<double> _resultFade;
  late Animation<double> _pulseAnimation;

  // ============== STATE ==============
  int? _selectedAnswerIndex;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🚀 === ENHANCED TEST SCREEN INIT ===');
      print('📝 Dados recebidos:');
      print('  chosenConnection: ${widget.chosenConnection}');
      print('  userInterests: ${widget.userInterests}');
      print('  inviteId: "${widget.inviteId}"');
      print('  inviteId.isEmpty: ${widget.inviteId.isEmpty}');
    }

    _initializeAnimations();

    // ✅ CORREÇÃO: Inicializar sessão apenas se inviteId não estiver vazio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.inviteId.isNotEmpty) {
        _initializeTestSession();
      } else {
        if (kDebugMode) {
          print('⚠️ InviteId vazio - sessão não será inicializada');
        }
      }
    });
  }

  void _initializeAnimations() {
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

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
    _resultFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _questionController.forward();
  }

  // ✅ CORREÇÃO: Método de inicialização da sessão melhorado
  Future<void> _initializeTestSession() async {
    if (kDebugMode) {
      print('🎮 === INICIALIZANDO SESSÃO DE TESTE ===');
    }

    try {
      final currentUser = ref.read(authProvider).user;
      if (currentUser == null) {
        if (kDebugMode) {
          print('❌ Usuário não autenticado');
        }
        return;
      }

      // Verificar se já existe uma sessão ativa
      final testState = ref.read(enhancedTestSessionProvider);
      if (testState.sessionId != null) {
        if (kDebugMode) {
          print('✅ Sessão já existe: ${testState.sessionId}');
        }
        return;
      }

      // Criar UserModel do outro usuário
      final otherUser = _createOtherUser();
      if (kDebugMode) {
        print('✅ UserModel criado: ${otherUser.uid}');
      }

      // Inicializar sessão
      final success = await ref
          .read(enhancedTestSessionProvider.notifier)
          .startRealSession(inviteId: widget.inviteId, otherUser: otherUser);

      if (kDebugMode) {
        print('🎮 Resultado startRealSession: $success');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exceção em _initializeTestSession: $e');
      }
    }
  }

  // ✅ Criar UserModel com todos os campos obrigatórios
  UserModel _createOtherUser() {
    return UserModel(
      uid: widget.chosenConnection['id'] as String? ?? 'unknown',
      username:
          widget.chosenConnection['username'] as String? ??
          widget.chosenConnection['nome']?.toString().toLowerCase().replaceAll(
            ' ',
            '_',
          ) ??
          'user_${DateTime.now().millisecondsSinceEpoch}',
      displayName: widget.chosenConnection['nome'] as String? ?? 'Usuário',
      avatar: widget.chosenConnection['avatarId'] as String? ?? 'avatar1',
      email:
          widget.chosenConnection['email'] as String? ??
          '${widget.chosenConnection['id'] ?? 'user'}@temp.com',
      level: widget.chosenConnection['level'] as int? ?? 1,
      xp: widget.chosenConnection['xp'] as int? ?? 0,
      coins: widget.chosenConnection['coins'] as int? ?? 0,
      gems: widget.chosenConnection['gems'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(
            widget.chosenConnection['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      lastLoginAt:
          DateTime.tryParse(
            widget.chosenConnection['lastLoginAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      aiConfig: Map<String, dynamic>.from(
        widget.chosenConnection['aiConfig'] as Map? ?? {},
      ),
      codinome: widget.chosenConnection['codinome'] as String?,
      interesses: List<String>.from(
        widget.chosenConnection['interesses'] as List? ?? [],
      ),
      relationshipInterest:
          widget.chosenConnection['relationshipInterest'] as String?,
      onboardingCompleted:
          widget.chosenConnection['onboardingCompleted'] as bool? ?? true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(enhancedTestSessionProvider);
    final currentUser = ref.watch(authProvider).user;

    return PopScope(
      canPop:
          testState.phase == TestPhase.completed ||
          testState.phase == TestPhase.result,
      onPopInvoked: (didPop) {
        if (!didPop && testState.hasActiveSession) {
          _showExitConfirmDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Teste com ${widget.chosenConnection['nome']?.toString().split(' ')[0] ?? 'Usuário'}',
          ),
          elevation: 0,
          leading:
              testState.phase == TestPhase.completed ||
                  testState.phase == TestPhase.result
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/home'),
                )
              : null,
          automaticallyImplyLeading: false,
          actions: [
            if (testState.hasActiveSession &&
                testState.phase != TestPhase.result)
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: _showTestInfo,
              ),
          ],
        ),
        body: _buildBody(testState, currentUser),
      ),
    );
  }

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

  Widget _buildWaitingView() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
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
            ),
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

  Widget _buildQuestionsView(TestSessionState testState) {
    if (testState.questions.isEmpty)
      return const Center(child: CircularProgressIndicator());

    final currentQuestion =
        testState.currentQuestionIndex < testState.questions.length
        ? testState.questions[testState.currentQuestionIndex]
        : null;

    if (currentQuestion == null) {
      return const Center(child: Text('Todas as perguntas foram respondidas!'));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor:
                  (testState.currentQuestionIndex + 1) /
                  testState.questions.length,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Question
          FadeTransition(
            opacity: _questionFade,
            child: SlideTransition(
              position: _questionSlide,
              child: Column(
                children: [
                  Text(
                    currentQuestion.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Options
                  ...currentQuestion.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: AnimatedButton(
                        onPressed: () =>
                            setState(() => _selectedAnswerIndex = index),
                        backgroundColor: _selectedAnswerIndex == index
                            ? Colors.purple
                            : Colors.grey[100]!,
                        foregroundColor: _selectedAnswerIndex == index
                            ? Colors.white
                            : Colors.black87,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Submit button
          if (_selectedAnswerIndex != null)
            SizedBox(
              width: double.infinity,
              child: AnimatedButton(
                onPressed: _isSubmitting ? null : _submitAnswer,
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirmar Resposta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniGameView(TestSessionState testState) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.games, size: 100, color: Colors.purple[600]),
          const SizedBox(height: 32),
          const Text(
            'Mini Jogo',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Aguardando o outro usuário finalizar...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CircularProgressIndicator(color: Colors.purple[600], strokeWidth: 3),
        ],
      ),
    );
  }

  Widget _buildResultView(TestSessionState testState) {
    final passed = testState.result == TestResult.passed;
    final score = testState.compatibilityScore;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resultController.forward(),
    );

    return Container(
      padding: const EdgeInsets.all(32),
      child: FadeTransition(
        opacity: _resultFade,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
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
            const SizedBox(height: 40),
            Text(
              passed ? '💕 Conexão Desbloqueada!' : '🤝 Boa Tentativa!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: passed ? Colors.green : Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: passed ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: passed
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Text(
                'Score de Compatibilidade: ${score.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: passed
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: AnimatedButton(
                onPressed: () => context.go('/home'),
                backgroundColor: passed ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                child: Text(
                  passed ? 'Iniciar Conversa' : 'Voltar ao Início',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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

  Future<void> _submitAnswer() async {
    if (_selectedAnswerIndex == null) return;

    setState(() => _isSubmitting = true);

    await ref
        .read(enhancedTestSessionProvider.notifier)
        .submitAnswer(
          questionId: ref
              .read(enhancedTestSessionProvider)
              .questions[ref
                  .read(enhancedTestSessionProvider)
                  .currentQuestionIndex]
              .id,
          answerIndex: _selectedAnswerIndex!,
        );

    setState(() {
      _isSubmitting = false;
      _selectedAnswerIndex = null;
    });

    _questionController.reset();
    _questionController.forward();
  }

  void _showExitConfirmDialog() {
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
        content: const Text(
          '• Responda as perguntas com sinceridade\n'
          '• Não há respostas certas ou erradas\n'
          '• A compatibilidade é calculada comparando suas respostas\n'
          '• É necessário 65% ou mais para desbloquear a conexão\n'
          '• O resultado é baseado em afinidade real',
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

  @override
  void dispose() {
    _questionController.dispose();
    _progressController.dispose();
    _resultController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
