// lib/providers/test_session_provider.dart
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

// ============== TEST SESSION MODELS ==============
enum TestPhase {
  waiting, // Aguardando ambos usuários
  questions, // Fase de perguntas
  miniGame, // Fase de mini-jogo
  result, // Exibindo resultado
  completed, // Teste finalizado
}

enum TestResult {
  pending, // Ainda não calculado
  passed, // Teste passou (≥65%)
  failed, // Teste falhou (<65%)
}

@immutable
class TestQuestion {
  final String id;
  final String text;
  final String category;
  final List<String> options;
  final int correctAnswer;

  const TestQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.options,
    required this.correctAnswer,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    return TestQuestion(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      category: json['category'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
    );
  }
}

@immutable
class UserAnswer {
  final String userId;
  final String questionId;
  final int selectedAnswer;
  final DateTime answeredAt;

  const UserAnswer({
    required this.userId,
    required this.questionId,
    required this.selectedAnswer,
    required this.answeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'questionId': questionId,
      'selectedAnswer': selectedAnswer,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      userId: json['userId'] ?? '',
      questionId: json['questionId'] ?? '',
      selectedAnswer: json['selectedAnswer'] ?? 0,
      answeredAt: DateTime.tryParse(json['answeredAt'] ?? '') ?? DateTime.now(),
    );
  }
}

@immutable
class MiniGameResult {
  final String userId;
  final bool completed;
  final int score;
  final DateTime completedAt;

  const MiniGameResult({
    required this.userId,
    required this.completed,
    required this.score,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'completed': completed,
      'score': score,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory MiniGameResult.fromJson(Map<String, dynamic> json) {
    return MiniGameResult(
      userId: json['userId'] ?? '',
      completed: json['completed'] ?? false,
      score: json['score'] ?? 0,
      completedAt:
          DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// ============== TEST SESSION STATE ==============
@immutable
class TestSessionState {
  final String? sessionId;
  final UserModel? otherUser;
  final TestPhase phase;
  final List<TestQuestion> questions;
  final Map<String, UserAnswer> answers;
  final Map<String, MiniGameResult> miniGameResults;
  final int currentQuestionIndex;
  final TestResult result;
  final double compatibilityScore;
  final bool isLoading;
  final String? error;
  final DateTime? sessionStartedAt;
  final Duration? timeRemaining;
  final String? inviteId; // Adicionar inviteId

  const TestSessionState({
    this.sessionId,
    this.otherUser,
    this.phase = TestPhase.waiting,
    this.questions = const [],
    this.answers = const {},
    this.miniGameResults = const {},
    this.currentQuestionIndex = 0,
    this.result = TestResult.pending,
    this.compatibilityScore = 0.0,
    this.isLoading = false,
    this.error,
    this.sessionStartedAt,
    this.timeRemaining,
    this.inviteId,
  });

  TestSessionState copyWith({
    String? sessionId,
    UserModel? otherUser,
    TestPhase? phase,
    List<TestQuestion>? questions,
    Map<String, UserAnswer>? answers,
    Map<String, MiniGameResult>? miniGameResults,
    int? currentQuestionIndex,
    TestResult? result,
    double? compatibilityScore,
    bool? isLoading,
    String? error,
    DateTime? sessionStartedAt,
    Duration? timeRemaining,
    String? inviteId,
  }) {
    return TestSessionState(
      sessionId: sessionId ?? this.sessionId,
      otherUser: otherUser ?? this.otherUser,
      phase: phase ?? this.phase,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      miniGameResults: miniGameResults ?? this.miniGameResults,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      result: result ?? this.result,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      inviteId: inviteId ?? this.inviteId,
    );
  }

  bool get hasActiveSession => sessionId != null;
  bool get isWaitingForOtherUser => phase == TestPhase.waiting;
  bool get canAnswer =>
      phase == TestPhase.questions && currentQuestionIndex < questions.length;
  bool get hasMoreQuestions => currentQuestionIndex < questions.length - 1;
  bool get allQuestionsAnswered =>
      answers.length >= questions.length * 2; // 2 usuários
  bool get miniGameCompleted => miniGameResults.length >= 2; // 2 usuários
}

// ============== TEST SESSION PROVIDER ==============
final testSessionProvider =
    StateNotifierProvider<TestSessionNotifier, TestSessionState>((ref) {
      return TestSessionNotifier(ref);
    });

class TestSessionNotifier extends StateNotifier<TestSessionState> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  Timer? _timeoutTimer;

  static const Duration _sessionTimeout = Duration(minutes: 10);

  // Bank de perguntas por categoria
  static final Map<String, List<TestQuestion>> _questionBank = {
    'Geral': [
      TestQuestion(
        id: 'g1',
        text: 'O que você mais valoriza em uma amizade?',
        category: 'Geral',
        options: ['Lealdade', 'Diversão', 'Apoio', 'Honestidade'],
        correctAnswer: 0, // Não há resposta "correta", é compatibilidade
      ),
      TestQuestion(
        id: 'g2',
        text: 'Como você prefere passar um fim de semana?',
        category: 'Geral',
        options: [
          'Em casa relaxando',
          'Saindo com amigos',
          'Explorando novos lugares',
          'Praticando hobbies',
        ],
        correctAnswer: 0,
      ),
      TestQuestion(
        id: 'g3',
        text: 'O que te motiva mais no dia a dia?',
        category: 'Geral',
        options: [
          'Crescimento pessoal',
          'Relacionamentos',
          'Conquistas profissionais',
          'Novas experiências',
        ],
        correctAnswer: 0,
      ),
    ],
    'Música': [
      TestQuestion(
        id: 'm1',
        text: 'Que tipo de música te emociona mais?',
        category: 'Música',
        options: [
          'Letras profundas',
          'Melodias animadas',
          'Ritmos dançantes',
          'Instrumentais',
        ],
        correctAnswer: 0,
      ),
      TestQuestion(
        id: 'm2',
        text: 'Onde você prefere ouvir música?',
        category: 'Música',
        options: ['Em casa', 'Shows e festivais', 'Caminhadas', 'Academia'],
        correctAnswer: 0,
      ),
    ],
    'Viagens': [
      TestQuestion(
        id: 'v1',
        text: 'Qual tipo de viagem você prefere?',
        category: 'Viagens',
        options: [
          'Aventura na natureza',
          'Cidades históricas',
          'Praias paradisíacas',
          'Metrópoles modernas',
        ],
        correctAnswer: 0,
      ),
      TestQuestion(
        id: 'v2',
        text: 'Como você planeja suas viagens?',
        category: 'Viagens',
        options: [
          'Roteiro detalhado',
          'Alguns pontos principais',
          'Improviso total',
          'Depende do destino',
        ],
        correctAnswer: 0,
      ),
    ],
    // Adicionar mais categorias conforme necessário
  };

  TestSessionNotifier(this._ref) : super(const TestSessionState());

  // ============== INICIAR SESSÃO ==============
  Future<bool> startSession(String inviteId, UserModel otherUser) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) {
        _handleError('Usuário não autenticado');
        return false;
      }

      // Gerar perguntas baseadas nos interesses comuns
      final questions = _generateQuestions(currentUser, otherUser);

      // Criar sessão no Firestore
      final sessionId = _firestore.collection('test_sessions').doc().id;
      final sessionData = {
        'id': sessionId,
        'inviteId': inviteId,
        'participants': [currentUser.uid, otherUser.uid],
        'questions': questions.map((q) => q.toJson()).toList(),
        'answers': {},
        'miniGameResults': {},
        'phase': TestPhase.questions.name,
        'result': TestResult.pending.name,
        'compatibilityScore': 0.0,
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(_sessionTimeout).toIso8601String(),
      };

      await _firestore
          .collection('test_sessions')
          .doc(sessionId)
          .set(sessionData);

      state = state.copyWith(
        sessionId: sessionId,
        otherUser: otherUser,
        questions: questions,
        phase: TestPhase.questions,
        sessionStartedAt: DateTime.now(),
        isLoading: false,
        inviteId: inviteId, // Store the inviteId
      );

      // Iniciar listener da sessão
      _startSessionListener(sessionId);

      // Iniciar timer de timeout
      _startTimeoutTimer();

      if (kDebugMode) {
        print('✅ TestSessionProvider: Sessão iniciada: $sessionId');
      }

      return true;
    } catch (e) {
      _handleError('Erro ao iniciar sessão: $e');
      return false;
    }
  }

  List<TestQuestion> _generateQuestions(UserModel user1, UserModel user2) {
    final commonInterests = user1.interesses
        .where((interest) => user2.interesses.contains(interest))
        .toList();

    final questions = <TestQuestion>[];

    // Adicionar perguntas dos interesses comuns
    for (final interest in commonInterests.take(2)) {
      final categoryQuestions = _questionBank[interest];
      if (categoryQuestions != null && categoryQuestions.isNotEmpty) {
        questions.add(
          categoryQuestions[Random().nextInt(categoryQuestions.length)],
        );
      }
    }

    // Completar com perguntas gerais se necessário
    while (questions.length < 3) {
      final generalQuestions = _questionBank['Geral']!;
      final randomQuestion =
          generalQuestions[Random().nextInt(generalQuestions.length)];
      if (!questions.any((q) => q.id == randomQuestion.id)) {
        questions.add(randomQuestion);
      }
    }

    return questions;
  }

  void _startSessionListener(String sessionId) {
    _sessionSubscription = _firestore
        .collection('test_sessions')
        .doc(sessionId)
        .snapshots()
        .listen(_handleSessionUpdate, onError: _handleError);
  }

  void _handleSessionUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;

    // Atualizar respostas
    final answersData = Map<String, dynamic>.from(data['answers'] ?? {});
    final answers = <String, UserAnswer>{};

    answersData.forEach((key, value) {
      answers[key] = UserAnswer.fromJson(Map<String, dynamic>.from(value));
    });

    // Atualizar resultados do mini-jogo
    final miniGameData = Map<String, dynamic>.from(
      data['miniGameResults'] ?? {},
    );
    final miniGameResults = <String, MiniGameResult>{};

    miniGameData.forEach((key, value) {
      miniGameResults[key] = MiniGameResult.fromJson(
        Map<String, dynamic>.from(value),
      );
    });

    // Verificar se deve avançar de fase
    final currentPhase = TestPhase.values.firstWhere(
      (p) => p.name == data['phase'],
      orElse: () => TestPhase.questions,
    );

    state = state.copyWith(
      answers: answers,
      miniGameResults: miniGameResults,
      phase: currentPhase,
      compatibilityScore: (data['compatibilityScore'] ?? 0.0).toDouble(),
      result: TestResult.values.firstWhere(
        (r) => r.name == data['result'],
        orElse: () => TestResult.pending,
      ),
    );

    _checkPhaseProgression();
  }

  void _checkPhaseProgression() {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    // Verificar se deve ir para mini-game
    if (state.phase == TestPhase.questions && state.allQuestionsAnswered) {
      _advanceToMiniGame();
    }
    // Verificar se deve calcular resultado
    else if (state.phase == TestPhase.miniGame && state.miniGameCompleted) {
      _calculateFinalResult();
    }
  }

  // ============== RESPONDER PERGUNTA ==============
  Future<bool> answerQuestion(int answerIndex) async {
    if (!state.canAnswer || state.sessionId == null) return false;

    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return false;

    try {
      final question = state.questions[state.currentQuestionIndex];
      final answer = UserAnswer(
        userId: currentUser.uid,
        questionId: question.id,
        selectedAnswer: answerIndex,
        answeredAt: DateTime.now(),
      );

      final answerKey = '${currentUser.uid}_${question.id}';

      await _firestore.collection('test_sessions').doc(state.sessionId!).update(
        {'answers.$answerKey': answer.toJson()},
      );

      // Avançar para próxima pergunta localmente
      if (state.hasMoreQuestions) {
        state = state.copyWith(
          currentQuestionIndex: state.currentQuestionIndex + 1,
        );
      }

      if (kDebugMode) {
        print('✅ TestSessionProvider: Pergunta respondida: ${question.id}');
      }

      return true;
    } catch (e) {
      _handleError('Erro ao responder pergunta: $e');
      return false;
    }
  }

  // ============== MINI-JOGO ==============
  Future<void> _advanceToMiniGame() async {
    if (state.sessionId == null) return;

    try {
      await _firestore
          .collection('test_sessions')
          .doc(state.sessionId!)
          .update({
            'phase': TestPhase.miniGame.name,
            'miniGameStartedAt': DateTime.now().toIso8601String(),
          });

      if (kDebugMode) {
        print('🎮 TestSessionProvider: Avançando para mini-jogo');
      }
    } catch (e) {
      _handleError('Erro ao avançar para mini-jogo: $e');
    }
  }

  Future<bool> submitMiniGameResult(bool success, int score) async {
    if (state.sessionId == null) return false;

    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return false;

    try {
      final result = MiniGameResult(
        userId: currentUser.uid,
        completed: success,
        score: score,
        completedAt: DateTime.now(),
      );

      await _firestore.collection('test_sessions').doc(state.sessionId!).update(
        {'miniGameResults.${currentUser.uid}': result.toJson()},
      );

      if (kDebugMode) {
        print('✅ TestSessionProvider: Resultado do mini-jogo enviado');
      }

      return true;
    } catch (e) {
      _handleError('Erro ao enviar resultado do mini-jogo: $e');
      return false;
    }
  }

  // ============== CALCULAR RESULTADO FINAL ==============
  Future<void> _calculateFinalResult() async {
    if (state.sessionId == null || state.otherUser == null) return;

    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      // Calcular compatibilidade das respostas (60% do score)
      double questionScore = _calculateQuestionCompatibility();

      // Calcular sucesso no mini-jogo (40% do score)
      double miniGameScore = _calculateMiniGameScore();

      // Score final
      final finalScore = (questionScore * 0.6) + (miniGameScore * 0.4);
      final passed = finalScore >= 65.0; // 65% mínimo para passar

      await _firestore
          .collection('test_sessions')
          .doc(state.sessionId!)
          .update({
            'phase': TestPhase.result.name,
            'result': passed ? TestResult.passed.name : TestResult.failed.name,
            'compatibilityScore': finalScore,
            'calculatedAt': DateTime.now().toIso8601String(),
          });

      if (kDebugMode) {
        print(
          '📊 TestSessionProvider: Resultado calculado: ${finalScore.toStringAsFixed(1)}% (${passed ? 'PASSOU' : 'FALHOU'})',
        );
      }
    } catch (e) {
      _handleError('Erro ao calcular resultado: $e');
    }
  }

  double _calculateQuestionCompatibility() {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null || state.otherUser == null) return 0.0;

    int compatibleAnswers = 0;
    int totalQuestions = state.questions.length;

    for (final question in state.questions) {
      final userAnswer = state.answers['${currentUser.uid}_${question.id}'];
      final otherAnswer =
          state.answers['${state.otherUser!.uid}_${question.id}'];

      if (userAnswer != null && otherAnswer != null) {
        if (userAnswer.selectedAnswer == otherAnswer.selectedAnswer) {
          compatibleAnswers++;
        }
      }
    }

    return totalQuestions > 0
        ? (compatibleAnswers / totalQuestions) * 100
        : 0.0;
  }

  double _calculateMiniGameScore() {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null || state.otherUser == null) return 0.0;

    final userResult = state.miniGameResults[currentUser.uid];
    final otherResult = state.miniGameResults[state.otherUser!.uid];

    if (userResult != null && otherResult != null) {
      // Se ambos completaram com sucesso, score máximo
      if (userResult.completed && otherResult.completed) {
        return 100.0;
      }
      // Se um completou, score médio
      else if (userResult.completed || otherResult.completed) {
        return 50.0;
      }
    }

    return 0.0;
  }

  // ============== TIMER E TIMEOUT ==============
  void _startTimeoutTimer() {
    _timeoutTimer = Timer(_sessionTimeout, () {
      if (state.hasActiveSession) {
        _handleSessionTimeout();
      }
    });
  }

  void _handleSessionTimeout() {
    _handleError('Sessão expirou por inatividade');
    endSession();
  }

  // ============== CONTROLE DE SESSÃO ==============
  Future<void> endSession() async {
    try {
      if (state.sessionId != null) {
        await _firestore
            .collection('test_sessions')
            .doc(state.sessionId!)
            .update({
              'phase': TestPhase.completed.name,
              'endedAt': DateTime.now().toIso8601String(),
            });
      }

      _sessionSubscription?.cancel();
      _timeoutTimer?.cancel();

      state = const TestSessionState();

      if (kDebugMode) {
        print('✅ TestSessionProvider: Sessão finalizada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestSessionProvider: Erro ao finalizar sessão: $e');
      }
    }
  }

  // ============== CONTROLE DE ESTADO ==============
  void clearError() {
    state = state.copyWith(error: null);
  }

  void _handleError(String error) {
    if (kDebugMode) {
      print('❌ TestSessionProvider: $error');
    }

    state = state.copyWith(isLoading: false, error: error);
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}

// ============== EXTENSION PARA FACILITAR USO ==============
extension TestSessionProviderX on WidgetRef {
  TestSessionNotifier get testSession => read(testSessionProvider.notifier);
  TestSessionState get testSessionState => watch(testSessionProvider);
}
