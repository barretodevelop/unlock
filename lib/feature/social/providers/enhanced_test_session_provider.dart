// lib/feature/social/providers/enhanced_test_session_provider.dart - CORRIGIDO
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/feature/social/providers/test_session_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/notification_service.dart';

final enhancedTestSessionProvider =
    StateNotifierProvider<EnhancedTestSessionNotifier, TestSessionState>((ref) {
      return EnhancedTestSessionNotifier(ref);
    });

class EnhancedTestSessionNotifier extends StateNotifier<TestSessionState> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  Timer? _timeoutTimer;
  Timer? _heartbeatTimer;

  static const Duration _sessionTimeout = Duration(minutes: 15);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  EnhancedTestSessionNotifier(this._ref) : super(const TestSessionState());

  // ============== ✅ CORREÇÃO 5: INICIALIZAÇÃO MELHORADA ==============
  Future<bool> startRealSession({
    required String inviteId,
    required UserModel otherUser,
  }) async {
    if (kDebugMode)
      print('🚀 EnhancedTestSession: Iniciando sessão para invite $inviteId');

    try {
      // Validações iniciais
      if (inviteId.isEmpty) {
        _handleError('ID do convite é obrigatório');
        return false;
      }

      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) {
        _handleError('Usuário não autenticado');
        return false;
      }

      // ✅ Estado de loading
      if (mounted) {
        state = state.copyWith(
          isLoading: true,
          error: null,
          phase: TestPhase.waiting,
          inviteId: inviteId,
          otherUser: otherUser,
        );
      }

      // Verificar se sessão já existe
      final existingSession = await _checkExistingSession(inviteId);
      if (existingSession != null) {
        if (kDebugMode)
          print('📋 Retomando sessão existente: $existingSession');
        await _resumeSession(existingSession);
        return true;
      }

      // Criar nova sessão
      final sessionId = await _createNewSession(
        inviteId,
        currentUser,
        otherUser,
      );
      if (sessionId == null) {
        _handleError('Falha ao criar sessão de teste');
        return false;
      }

      // ✅ Atualizar estado com sucesso
      if (mounted) {
        final questions = _generateQuestions(currentUser, otherUser);
        state = state.copyWith(
          sessionId: sessionId,
          questions: questions,
          phase: TestPhase.questions,
          sessionStartedAt: DateTime.now(),
          isLoading: false,
        );

        // Iniciar monitoramento
        _startSessionListener(sessionId);
        _startHeartbeat();
        _startTimeoutTimer();

        if (kDebugMode) print('✅ Sessão criada com sucesso: $sessionId');
        return true;
      }

      return false;
    } catch (e) {
      _handleError('Erro inesperado ao iniciar sessão: $e');
      return false;
    }
  }

  // ============== VERIFICAR SESSÃO EXISTENTE ==============
  Future<String?> _checkExistingSession(String inviteId) async {
    try {
      final query = await _firestore
          .collection('test_sessions')
          .where('inviteId', isEqualTo: inviteId)
          .where('phase', whereIn: ['questions', 'miniGame'])
          .limit(1)
          .get();

      return query.docs.isNotEmpty ? query.docs.first.id : null;
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao verificar sessão existente: $e');
      return null;
    }
  }

  // ============== CRIAR NOVA SESSÃO ==============
  Future<String?> _createNewSession(
    String inviteId,
    UserModel currentUser,
    UserModel otherUser,
  ) async {
    try {
      final sessionRef = _firestore.collection('test_sessions').doc();
      final questions = _generateQuestions(currentUser, otherUser);

      final sessionData = {
        'id': sessionRef.id,
        'inviteId': inviteId,
        'participants': [currentUser.uid, otherUser.uid],
        'questions': questions.map((q) => q.toJson()).toList(),
        'answers': <String, dynamic>{},
        'miniGameResults': <String, dynamic>{},
        'phase': TestPhase.questions.name,
        'result': TestResult.pending.name,
        'compatibilityScore': 0.0,
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(_sessionTimeout).toIso8601String(),
        'lastHeartbeat': {currentUser.uid: DateTime.now().toIso8601String()},
      };

      await sessionRef.set(sessionData);
      return sessionRef.id;
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao criar sessão: $e');
      return null;
    }
  }

  // ============== RETOMAR SESSÃO ==============
  Future<void> _resumeSession(String sessionId) async {
    try {
      final sessionDoc = await _firestore
          .collection('test_sessions')
          .doc(sessionId)
          .get();
      if (!sessionDoc.exists) {
        _handleError('Sessão não encontrada');
        return;
      }

      final data = sessionDoc.data()!;
      final questions = (data['questions'] as List)
          .map((q) => TestQuestion.fromJson(q))
          .toList();

      if (mounted) {
        state = state.copyWith(
          sessionId: sessionId,
          questions: questions,
          phase: TestPhase.values.firstWhere(
            (p) => p.name == data['phase'],
            orElse: () => TestPhase.questions,
          ),
          currentQuestionIndex: (data['answers'] as Map).length,
          isLoading: false,
        );

        _startSessionListener(sessionId);
        _startHeartbeat();
        _startTimeoutTimer();
      }
    } catch (e) {
      _handleError('Erro ao retomar sessão: $e');
    }
  }

  // ============== GERAR PERGUNTAS ==============
  List<TestQuestion> _generateQuestions(UserModel user1, UserModel user2) {
    final commonInterests = user1.interesses
        .where((interest) => user2.interesses.contains(interest))
        .toList();

    final questions = <TestQuestion>[
      // Pergunta sobre valores
      TestQuestion(
        id: 'valores_1',
        text: 'O que é mais importante em um relacionamento?',
        category: 'Valores',
        options: ['Confiança', 'Diversão', 'Crescimento mútuo', 'Estabilidade'],
        correctAnswer: 0,
      ),
      // Pergunta sobre lifestyle
      TestQuestion(
        id: 'lifestyle_1',
        text: 'Como você prefere passar o tempo livre?',
        category: 'Lifestyle',
        options: [
          'Em casa relaxando',
          'Explorando novos lugares',
          'Com amigos',
          'Aprendendo algo novo',
        ],
        correctAnswer: 0,
      ),
      // Pergunta baseada em interesse comum
      if (commonInterests.isNotEmpty)
        TestQuestion(
          id: 'interesse_comum_1',
          text: 'Sobre ${commonInterests.first}, o que mais te atrai?',
          category: commonInterests.first,
          options: [
            'A criatividade',
            'A comunidade',
            'O desafio',
            'A diversão',
          ],
          correctAnswer: 0,
        ),
    ];

    return questions;
  }

  // ============== SUBMETER RESPOSTA ==============
  Future<void> submitAnswer({
    required String questionId,
    required int answerIndex,
  }) async {
    if (state.sessionId == null) {
      _handleError('Nenhuma sessão ativa');
      return;
    }

    try {
      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) return;

      // Atualizar Firestore
      await _firestore.collection('test_sessions').doc(state.sessionId).update({
        'answers.${currentUser.uid}_$questionId': answerIndex,
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      // Atualizar estado local
      if (mounted) {
        final newAnswers = Map<String, UserAnswer>.from(state.answers);
        newAnswers['${currentUser.uid}_$questionId'] = UserAnswer(
          questionId: questionId,
          selectedAnswer: answerIndex,
          userId: currentUser.uid,
          answeredAt: DateTime.now(),
        );

        final nextIndex = state.currentQuestionIndex + 1;
        final isLastQuestion = nextIndex >= state.questions.length;

        state = state.copyWith(
          answers: newAnswers,
          currentQuestionIndex: isLastQuestion
              ? state.currentQuestionIndex
              : nextIndex,
          phase: isLastQuestion ? TestPhase.miniGame : TestPhase.questions,
        );

        if (isLastQuestion) {
          await _checkIfBothUsersFinished();
        }
      }
    } catch (e) {
      _handleError('Erro ao enviar resposta: $e');
    }
  }

  // ============== VERIFICAR SE AMBOS TERMINARAM ==============
  Future<void> _checkIfBothUsersFinished() async {
    if (state.sessionId == null) return;

    try {
      final sessionDoc = await _firestore
          .collection('test_sessions')
          .doc(state.sessionId)
          .get();
      if (!sessionDoc.exists) return;

      final data = sessionDoc.data()!;
      final answers = data['answers'] as Map<String, dynamic>;
      final participants = List<String>.from(data['participants']);
      final totalQuestions = state.questions.length;

      final user1Answers = answers.keys
          .where((k) => k.startsWith(participants[0]))
          .length;
      final user2Answers = answers.keys
          .where((k) => k.startsWith(participants[1]))
          .length;

      if (user1Answers >= totalQuestions && user2Answers >= totalQuestions) {
        await _calculateFinalResult();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao verificar progresso: $e');
    }
  }

  // ============== CALCULAR RESULTADO ==============
  Future<void> _calculateFinalResult() async {
    if (state.sessionId == null) return;

    try {
      // Simular cálculo de compatibilidade
      final score = 65.0 + Random().nextDouble() * 30; // 65-95%
      final passed = score >= 65.0;

      await _firestore.collection('test_sessions').doc(state.sessionId).update({
        'compatibilityScore': score,
        'result': passed ? TestResult.passed.name : TestResult.failed.name,
        'phase': TestPhase.result.name,
        'completedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        state = state.copyWith(
          compatibilityScore: score,
          result: passed ? TestResult.passed : TestResult.failed,
          phase: TestPhase.result,
        );

        // Notificar resultado
        if (passed) {
          NotificationService.showSuccess(
            '🎉 Conexão desbloqueada com ${score.toStringAsFixed(1)}% de compatibilidade!',
          );
        } else {
          NotificationService.showInfo(
            'Compatibilidade de ${score.toStringAsFixed(1)}%. Continue tentando!',
          );
        }
      }
    } catch (e) {
      _handleError('Erro ao calcular resultado: $e');
    }
  }

  // ============== LISTENERS E TIMERS ==============
  void _startSessionListener(String sessionId) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _firestore
        .collection('test_sessions')
        .doc(sessionId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            final data = snapshot.data()!;
            // Sincronizar estado com Firebase
            _syncWithFirebase(data);
          }
        });
  }

  void _syncWithFirebase(Map<String, dynamic> data) {
    if (!mounted) return;

    final newPhase = TestPhase.values.firstWhere(
      (p) => p.name == data['phase'],
      orElse: () => state.phase,
    );

    if (newPhase != state.phase) {
      state = state.copyWith(
        phase: newPhase,
        compatibilityScore: (data['compatibilityScore'] ?? 0.0).toDouble(),
        result: TestResult.values.firstWhere(
          (r) => r.name == data['result'],
          orElse: () => state.result,
        ),
      );
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
      (_) => _sendHeartbeat(),
    );
  }

  Future<void> _sendHeartbeat() async {
    if (state.sessionId == null) return;

    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      await _firestore.collection('test_sessions').doc(state.sessionId).update({
        'lastHeartbeat.${currentUser.uid}': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('❌ Erro no heartbeat: $e');
    }
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_sessionTimeout, () {
      if (mounted) {
        _handleError('Sessão expirou');
        clearSession();
      }
    });
  }

  // ============== ERROR HANDLING MELHORADO ==============
  void _handleError(String message) {
    if (kDebugMode) print('❌ EnhancedTestSession: $message');

    if (mounted) {
      state = state.copyWith(error: message, isLoading: false);
    }

    // Notificar usuário apenas para erros importantes
    if (message.contains('expirou') ||
        message.contains('falha') ||
        message.contains('autenticado')) {
      NotificationService.showError(message);
    }
  }

  // ============== LIMPEZA ==============
  void clearSession() {
    _sessionSubscription?.cancel();
    _timeoutTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (mounted) {
      state = const TestSessionState();
    }

    if (kDebugMode) print('🧹 Sessão limpa');
  }

  void clearError() {
    if (mounted) {
      state = state.copyWith(error: null);
    }
  }

  @override
  void dispose() {
    clearSession();
    super.dispose();
  }
}

// ============== EXTENSION HELPERS ==============
extension EnhancedTestSessionX on WidgetRef {
  EnhancedTestSessionNotifier get enhancedTestSession =>
      read(enhancedTestSessionProvider.notifier);
  TestSessionState get enhancedTestSessionState =>
      watch(enhancedTestSessionProvider);
}

// ============== DEBUGGING ==============
extension TestSessionDebug on TestSessionState {
  void debugPrint() {
    if (kDebugMode) {
      print('🐛 TestSession State:');
      print('  SessionId: $sessionId');
      print('  Phase: $phase');
      print('  Questions: ${questions.length}');
      print('  CurrentIndex: $currentQuestionIndex');
      print('  Score: $compatibilityScore');
      print('  Result: $result');
      print('  Error: $error');
      print('  IsLoading: $isLoading');
    }
  }
}
