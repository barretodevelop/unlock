// lib/feature/games/social/providers/enhanced_test_session_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/feature/social/providers/test_invite_provider.dart';
import 'package:unlock/feature/social/providers/test_session_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/firebase_test_session_service.dart';
import 'package:unlock/services/notification_service.dart';

/// Provider aprimorado com integração Firebase real
final enhancedTestSessionProvider =
    StateNotifierProvider<EnhancedTestSessionNotifier, TestSessionState>((ref) {
      return EnhancedTestSessionNotifier(ref);
    });

class EnhancedTestSessionNotifier extends StateNotifier<TestSessionState> {
  final Ref _ref;
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  Timer? _timeoutTimer;
  Timer? _heartbeatTimer;

  EnhancedTestSessionNotifier(this._ref) : super(const TestSessionState());

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _timeoutTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  // ============== INICIAR SESSÃO REAL ==============
  Future<bool> startRealSession({
    required String inviteId,
    required UserModel otherUser,
  }) async {
    // Modificação de estado inicial síncrona.
    // A chamada para startRealSession já foi adiada pelo initState da UI.
    if (mounted) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        phase: TestPhase.waiting,
        inviteId: inviteId,
      );
    } else {
      return false; // Notifier não está montado, não prosseguir.
    }

    try {
      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) {
        _handleError('Usuário não autenticado');
        return false;
      }

      // Criar sessão no Firebase
      final sessionId = await FirebaseTestSessionService.createTestSession(
        inviteId: inviteId,
        currentUser: currentUser,
        otherUser: otherUser,
      );

      if (sessionId == null) {
        _handleError('Erro ao criar sessão de teste');
        return false;
      }

      // Atualização de estado após operações async é geralmente segura.
      if (mounted) {
        state = state.copyWith(
          sessionId: sessionId,
          otherUser: otherUser,
          sessionStartedAt: DateTime.now(),
          isLoading: false,
          phase: TestPhase.questions,
          // inviteId já foi definido
        );
      } else {
        return false;
      }

      // Iniciar listeners
      _startSessionListener(sessionId);
      _startHeartbeat();
      _startTimeoutTimer();

      // Notificar sucesso
      NotificationService.showSuccess('Teste de compatibilidade iniciado!');

      if (kDebugMode) {
        print('✅ EnhancedTestSession: Sessão real iniciada: $sessionId');
      }

      return true;
    } catch (e) {
      _handleError('Erro ao iniciar sessão: $e');
      return false;
    }
  }

  // ============== LISTENER REAL-TIME ==============
  void _startSessionListener(String sessionId) {
    _sessionSubscription?.cancel();

    _sessionSubscription = FirebaseTestSessionService.watchSession(sessionId)
        .listen(
          (snapshot) => _handleSessionUpdate(snapshot),
          onError: (error) => _handleError('Erro no listener: $error'),
        );
  }

  void _handleSessionUpdate(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!snapshot.exists) {
      _handleError('Sessão não encontrada');
      return;
    }

    try {
      // Não modificar estado diretamente aqui se for chamado por um listener síncrono
      final data = snapshot.data()!;

      // Extrair perguntas
      final questionsData = List<Map<String, dynamic>>.from(
        data['questions'] ?? [],
      );
      final questions = questionsData
          .map((q) => TestQuestion.fromJson(q))
          .toList();

      // Extrair respostas
      final answersData = Map<String, dynamic>.from(data['answers'] ?? {});
      final Map<String, UserAnswer> allSessionAnswers = {};
      answersData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          allSessionAnswers[key] = UserAnswer.fromJson(value);
        }
      });

      // Determinar fase atual
      final phaseString = data['phase'] as String? ?? 'questions';
      final phase = TestPhase.values.firstWhere(
        (p) => p.name == phaseString,
        orElse: () => TestPhase.questions,
      );

      // Determinar resultado
      final resultString = data['result'] as String? ?? 'pending';
      final result = TestResult.values.firstWhere(
        (r) => r.name == resultString,
        orElse: () => TestResult.pending,
      );

      final currentUser = _ref.read(authProvider).user;
      final currentUserAnswersCount = currentUser != null
          ? allSessionAnswers.values
                .where((ans) => ans.userId == currentUser.uid)
                .length
          : 0;

      if (mounted) {
        state = state.copyWith(
          questions: questions,
          answers: allSessionAnswers,
          phase: phase,
          result: result,
          inviteId:
              data['inviteId']
                  as String?, // Garante que o inviteId seja atualizado se vier do Firestore
          compatibilityScore:
              (data['compatibilityScore'] as num?)?.toDouble() ?? 0.0,
          currentQuestionIndex: currentUserAnswersCount,
          isLoading: false, // Reset isLoading
        );
      }
      // Ações baseadas na fase
      _handlePhaseChange(phase, result);
    } catch (e) {
      _handleError('Erro ao processar atualização: $e');
    }
  }

  void _handlePhaseChange(TestPhase phase, TestResult result) {
    switch (phase) {
      case TestPhase.miniGame:
        _triggerMiniGame();
        break;
      case TestPhase.result:
        _handleTestResult(result);
        break;
      case TestPhase.completed:
        _handleTestCompleted();
        break;
      default:
        break;
    }
  }

  // ============== SUBMETER RESPOSTA ==============
  Future<bool> submitRealAnswer({
    required String questionId,
    required int selectedAnswer,
  }) async {
    try {
      final currentUser = _ref.read(authProvider).user;
      final sessionId = state.sessionId;

      if (currentUser == null || sessionId == null) {
        _handleError('Dados da sessão inválidos');
        return false;
      }

      final success = await FirebaseTestSessionService.submitAnswer(
        sessionId: sessionId,
        userId: currentUser.uid,
        questionId: questionId,
        selectedAnswer: selectedAnswer,
      );

      if (success) {
        final answer = UserAnswer(
          userId: currentUser.uid,
          questionId: questionId,
          selectedAnswer: selectedAnswer,
          answeredAt: DateTime.now(),
        );

        // Usar estrutura Map correta
        final newAnswersMap = Map<String, UserAnswer>.from(state.answers);
        final answerKey = '${currentUser.uid}_$questionId';
        newAnswersMap[answerKey] = answer;

        final currentUserAnswersCount = newAnswersMap.values
            .where((ans) => ans.userId == currentUser.uid)
            .length;

        if (mounted) {
          state = state.copyWith(
            answers: newAnswersMap,
            currentQuestionIndex: currentUserAnswersCount,
          );
        }

        if (currentUserAnswersCount >= state.questions.length) {
          await _attemptCompleteTest();
        }

        return true;
      }

      return false;
    } catch (e) {
      _handleError('Erro ao enviar resposta: $e');
      return false;
    }
  }

  // ============== COMPLETAR TESTE ==============
  Future<void> _attemptCompleteTest() async {
    try {
      final sessionId = state.sessionId;
      final currentUser = _ref.read(authProvider).user;

      if (sessionId == null || currentUser == null) return;

      // A transição para miniGame deve ocorrer após todas as perguntas serem respondidas.
      // E a chamada para completeTest deve ocorrer após o minigame ser concluído por ambos.
      // Esta função _attemptCompleteTest provavelmente deve ser chamada após
      // a conclusão do minigame por ambos os usuários.

      // Verificar se todas as perguntas foram respondidas por ambos
      // (esta lógica pode precisar ser mais robusta, verificando o número de respostas por participante)
      final allQuestionsAnsweredByBoth =
          state.answers.length >= state.questions.length * 2;
      final miniGameCompletedByBoth =
          state.miniGameResults.length >= 2; // Supondo 2 participantes

      if (!allQuestionsAnsweredByBoth || !miniGameCompletedByBoth) {
        if (mounted)
          state = state.copyWith(
            isLoading: false,
          ); // Reset isLoading se não for completar
        return; // Não tentar completar se as condições não forem atendidas
      }

      // Completar teste no Firebase
      final result = await FirebaseTestSessionService.completeTest(
        sessionId: sessionId,
        userId: currentUser.uid,
      );

      if (result != null) {
        final status = result['status'] as String;

        if (status == 'waiting') {
          // Ainda aguardando outro usuário
          // Isso não deveria acontecer se a lógica acima (allQuestionsAnsweredByBoth, etc.) estiver correta
          if (mounted) {
            state = state.copyWith(phase: TestPhase.miniGame, isLoading: false);
          }
          NotificationService.showInfo(result['message'] as String);
        } else if (status == 'completed') {
          // Teste finalizado
          final passed = result['passed'] as bool;
          final compatibility = result['compatibility'] as double;

          if (mounted) {
            state = state.copyWith(
              phase: TestPhase.result,
              result: passed ? TestResult.passed : TestResult.failed,
              compatibilityScore: compatibility,
              isLoading: false,
            );
          }
          // Após Firebase service completar o teste, atualizar o convite original
          if (state.inviteId != null) {
            final Map<String, dynamic> testResultsForInvite = {
              'compatibilityScore': compatibility,
              'result': (passed ? TestResult.passed : TestResult.failed).name,
            };
            _ref
                .read(testInviteProvider.notifier)
                .completeTest(state.inviteId!, testResultsForInvite);
          }
        }
      }
    } catch (e) {
      _handleError('Erro ao completar teste: $e');
    }
  }

  // ============== MINI-GAME SUBMISSION (REAL) ==============
  Future<bool> submitMiniGameRealResult(bool completed, int score) async {
    try {
      final currentUser = _ref.read(authProvider).user;
      final sessionId = state.sessionId;

      if (currentUser == null || sessionId == null) {
        _handleError('Dados da sessão inválidos para submeter mini-game');
        return false;
      }

      // Este método deve chamar FirebaseTestSessionService.submitMiniGameResult
      // e o FirebaseTestSessionService.completeTest deve ser chamado depois que
      // AMBOS os usuários submeterem seus resultados do minigame.
      // A lógica de transição para _attemptCompleteTest precisará ser ajustada
      // para considerar a conclusão do minigame por ambos.
      final success = await FirebaseTestSessionService.submitMiniGameResult(
        sessionId: sessionId,
        userId: currentUser.uid,
        resultData: {'completed': completed, 'score': score},
      );

      if (success) {
        // O listener _handleSessionUpdate irá pegar a mudança e atualizar o state.miniGameResults.
        // Então, _checkPhaseProgression (ou uma lógica similar em _handleSessionUpdate)
        // pode chamar _attemptCompleteTest se ambos os jogadores completaram o minigame.
      }
      return success;
    } catch (e) {
      _handleError('Erro ao enviar resultado do mini-jogo: $e');
      return false;
    }
  }

  // ============== MINI-GAME ==============
  void _triggerMiniGame() {
    if (kDebugMode) {
      print('🎮 Iniciando mini-game...');
    }
    // A UI deve mudar para a visualização do minigame.
    // A lógica de submissão do resultado do minigame é separada.
  }

  // ============== RESULTADO ==============
  void _handleTestResult(TestResult result) {
    final passed = result == TestResult.passed;
    final score = state.compatibilityScore;

    if (passed) {
      NotificationService.showSuccess(
        '🎉 Conexão desbloqueada! Compatibilidade: ${score.toStringAsFixed(1)}%',
      );
    } else {
      NotificationService.showInfo(
        '😔 Compatibilidade insuficiente: ${score.toStringAsFixed(1)}%',
      );
    }
  }

  void _handleTestCompleted() {
    // Limpar timers
    _timeoutTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (kDebugMode) {
      print('✅ Teste finalizado completamente');
    }
    if (mounted) {
      state = state.copyWith(phase: TestPhase.completed);
    }
  }

  // ============== TIMEOUT E HEARTBEAT ==============
  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(minutes: 15), () {
      _handleError('Teste expirado - tempo limite atingido');
      // TODO: Chamar endSession() ou uma lógica de finalização por timeout
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _sendHeartbeat();
    });
  }

  void _sendHeartbeat() {
    // Manter sessão ativa
    final sessionId = state.sessionId;
    if (sessionId != null) {
      FirebaseFirestore.instance
          .collection('test_sessions')
          .doc(sessionId)
          .update({'lastActivity': FieldValue.serverTimestamp()});
    }
  }

  // ============== NAVEGAÇÃO ==============
  Future<void> navigateToUnlockedProfile() async {
    final otherUser = state.otherUser;
    if (otherUser != null && state.result == TestResult.passed) {
      // Implementar navegação para perfil desbloqueado
      if (kDebugMode) {
        print(
          '🔓 Navegando para perfil desbloqueado: ${otherUser.displayName}',
        );
      }
    }
  }

  Future<void> navigateToChat() async {
    final otherUser = state.otherUser;
    if (otherUser != null && state.result == TestResult.passed) {
      // Implementar navegação para chat
      if (kDebugMode) {
        print('💬 Navegando para chat: ${otherUser.displayName}');
      }
    }
  }

  // ============== BUSCAR SESSÕES ATIVAS ==============
  Future<void> loadActiveSessions() async {
    try {
      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) return;

      final sessions = await FirebaseTestSessionService.getUserActiveSessions(
        currentUser.uid,
      );

      if (sessions.isNotEmpty) {
        // Retomar sessão mais recente se existir
        final mostRecent = sessions.first;
        final sessionId = mostRecent['id'] as String;

        if (mounted) {
          state = state.copyWith(
            sessionId: sessionId,
            inviteId: mostRecent['inviteId'] as String?,
            phase: TestPhase.values.firstWhere(
              (p) => p.name == mostRecent['phase'],
              orElse: () => TestPhase.questions,
            ),
          );
        }
        _startSessionListener(sessionId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao carregar sessões ativas: $e');
      }
    }
  }

  // ============== ERROR HANDLING ==============
  void _handleError(String message) {
    if (mounted) {
      state = state.copyWith(error: message, isLoading: false);
    }

    NotificationService.showError(message);

    if (kDebugMode) {
      print('❌ EnhancedTestSession: $message');
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
  }

  // ============== DEBUGGING ==============
  void debugPrintState() {
    if (kDebugMode) {
      print('🐛 TestSession Debug:');
      print('  SessionId: ${state.sessionId}');
      print('  Phase: ${state.phase}');
      print('  Questions: ${state.questions.length}');
      print('  Answers: ${state.answers.length}');
      print('  Score: ${state.compatibilityScore}');
      print('  Result: ${state.result}');
    }
  }
}
