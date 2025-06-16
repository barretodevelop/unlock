// lib/screens/social/affinity_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/models/affinity_question.dart';

import '../../models/affinity_test_model.dart';
import '../../models/unlock_match_model.dart';
import '../../providers/unlock_matching_provider.dart';
import '../../widgets/animated/bounce_widget.dart';
import '../../widgets/animated/fade_in_widget.dart';

class AffinityTestScreen extends ConsumerStatefulWidget {
  final UnlockMatchModel match;

  const AffinityTestScreen({
    super.key,
    required this.match,
    required potentialMatch,
  });

  @override
  ConsumerState<AffinityTestScreen> createState() => _AffinityTestScreenState();
}

class _AffinityTestScreenState extends ConsumerState<AffinityTestScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _questionController;
  late AnimationController _heartController;

  late Animation<double> _progressAnimation;
  late Animation<double> _questionAnimation;
  late Animation<double> _heartAnimation;

  int _currentQuestionIndex = 0;
  Map<String, String> _userAnswers = {};
  bool _isSubmitting = false;
  bool _showResults = false;
  AffinityTestResult? _testResult;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTest();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _questionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _questionAnimation = CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeOutCubic,
    );

    _heartAnimation = CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    );
  }

  void _loadTest() {
    ref
        .read(unlockMatchingProvider.notifier)
        .generateAffinityTest(widget.match.id, widget.match.commonInterests);
    _questionController.forward();
  }

  void _answerQuestion(String questionId, String answer) {
    setState(() {
      _userAnswers[questionId] = answer;
    });

    // Animar transição para próxima pergunta
    _questionController.reverse().then((_) {
      if (_currentQuestionIndex < _getCurrentTest().questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
        _questionController.forward();
        _progressController.animateTo(
          (_currentQuestionIndex + 1) / _getCurrentTest().questions.length,
        );
      } else {
        _submitTest();
      }
    });
  }

  Future<void> _submitTest() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ref
          .read(unlockMatchingProvider.notifier)
          .submitAffinityTest(widget.match.id, _userAnswers);

      setState(() {
        _testResult = result;
        _showResults = true;
        _isSubmitting = false;
      });

      _heartController.forward();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      // Mostrar erro
    }
  }

  AffinityTestModel _getCurrentTest() {
    return ref.watch(unlockMatchingProvider).currentTest!;
  }

  @override
  void dispose() {
    _progressController.dispose();
    _questionController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchingState = ref.watch(unlockMatchingProvider);

    if (matchingState.currentTest == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Teste de Afinidade',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _showResults ? _buildResultsView() : _buildTestView(),
    );
  }

  Widget _buildTestView() {
    final theme = Theme.of(context);
    final test = _getCurrentTest();
    final currentQuestion = test.questions[_currentQuestionIndex];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Barra de progresso
            _buildProgressBar(),
            const SizedBox(height: 32),

            // Info do match
            _buildMatchInfo(),
            const SizedBox(height: 32),

            // Pergunta atual
            Expanded(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(_questionAnimation),
                child: FadeTransition(
                  opacity: _questionAnimation,
                  child: _buildQuestionCard(currentQuestion),
                ),
              ),
            ),

            // Loading
            if (_isSubmitting) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Calculando afinidade...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final theme = Theme.of(context);
    final test = _getCurrentTest();
    final progress = (_currentQuestionIndex + 1) / test.questions.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pergunta ${_currentQuestionIndex + 1}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_currentQuestionIndex + 1}/${test.questions.length}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchInfo() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Avatar misterioso
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.help_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conexão Misteriosa',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compatibilidade: ${widget.match.compatibilityScore.toInt()}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: widget.match.commonInterests
                      .take(3)
                      .map(
                        (interest) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            interest,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          // Ícone de desbloqueio
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.amber,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AffinityQuestion question) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Categoria
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              question.category,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pergunta
          Text(
            question.question,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Opções de resposta
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;

            return FadeInWidget(
              delay: Duration(milliseconds: 200 + (index * 100)),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: BounceWidget(
                  onTap: () => _answerQuestion(question.id, option),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      option,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final theme = Theme.of(context);
    final result = _testResult!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Animação de coração/resultado
            ScaleTransition(
              scale: _heartAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: result.unlocked
                      ? LinearGradient(colors: [Colors.green, Colors.teal])
                      : LinearGradient(colors: [Colors.orange, Colors.red]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (result.unlocked ? Colors.green : Colors.orange)
                          .withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  result.unlocked
                      ? Icons.lock_open_rounded
                      : Icons.lock_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Resultado
            FadeInWidget(
              delay: const Duration(milliseconds: 800),
              child: Text(
                result.unlocked ? 'Perfil Desbloqueado!' : 'Tente Novamente',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: result.unlocked ? Colors.green : Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            FadeInWidget(
              delay: const Duration(milliseconds: 1000),
              child: Text(
                result.unlocked
                    ? 'Vocês têm uma afinidade incrível! Agora podem se conectar de verdade.'
                    : 'A afinidade não foi suficiente desta vez. Que tal tentar com outra pessoa?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Score de afinidade
            FadeInWidget(
              delay: const Duration(milliseconds: 1200),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      'Score de Afinidade',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${result.affinityScore.toInt()}%',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getScoreMessage(result.affinityScore),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Botões de ação
            FadeInWidget(
              delay: const Duration(milliseconds: 1400),
              child: Column(
                children: [
                  if (result.unlocked) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _goToChat(),
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('Iniciar Conversa'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        result.unlocked
                            ? 'Continuar Descobrindo'
                            : 'Tentar Novamente',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreMessage(double score) {
    if (score >= 80) return 'Afinidade excepcional! 🔥';
    if (score >= 60) return 'Boa compatibilidade! 😊';
    if (score >= 40) return 'Algumas coisas em comum 🤔';
    return 'Visões muito diferentes 😅';
  }

  void _goToChat() {
    // Navegar para o chat com a pessoa desbloqueada
    context.go('/chat/${widget.match.id}');
  }
}
