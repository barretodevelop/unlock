// lib/services/firebase_test_session_service.dart
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as fb_auth; // Alias para evitar conflito
import 'package:flutter/foundation.dart';
import 'package:unlock/feature/social/providers/test_invite_provider.dart';
import 'package:unlock/feature/social/providers/test_session_provider.dart'; // Para TestPhase, TestResult
import 'package:unlock/models/user_model.dart';

/// Service para gerenciar sessões de teste no Firebase
class FirebaseTestSessionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final fb_auth.FirebaseAuth _auth =
      fb_auth.FirebaseAuth.instance; // Usar alias

  // Timeout para sessões de teste
  static const Duration _sessionTimeout = Duration(minutes: 15);

  /// Criar nova sessão de teste entre dois usuários
  static Future<String?> createTestSession({
    required String inviteId,
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser?.uid != currentUser.uid) {
        throw Exception('Usuário não autorizado para criar sessão.');
      }

      final questions = _generateQuestions(currentUser, otherUser);
      final sessionRef = _db.collection('test_sessions').doc();
      final now = DateTime.now();

      final sessionData = {
        'id': sessionRef.id,
        'inviteId': inviteId,
        'participants': [currentUser.uid, otherUser.uid],
        'participantData': {
          currentUser.uid: {
            'name': currentUser.displayName,
            'avatar': currentUser.avatar,
            'interests': currentUser.interesses,
          },
          otherUser.uid: {
            'name': otherUser.displayName,
            'avatar': otherUser.avatar,
            'interests': otherUser.interesses,
          },
        },
        'questions': questions.map((q) => q.toJson()).toList(),
        'answers': <String, dynamic>{},
        'miniGameResults':
            <
              String,
              dynamic
            >{}, // userId: {completed: bool, score: int, completedAt: ISOString}
        'phase': TestPhase.questions.name,
        'result': TestResult.pending.name,
        'compatibilityScore': 0.0,
        'status': 'active', // active, completed, expired, error
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': now.add(_sessionTimeout).toIso8601String(),
        'lastActivity': FieldValue.serverTimestamp(),
      };

      await sessionRef.set(sessionData);
      await _updateInviteStatus(
        inviteId,
        TestInviteStatus.inProgress.name,
      ); // Usar enum.name

      if (kDebugMode) {
        print(
          '✅ FirebaseTestSessionService: TestSession criada: ${sessionRef.id}',
        );
      }
      return sessionRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FirebaseTestSessionService: Erro ao criar sessão: $e');
      }
      return null;
    }
  }

  /// Submeter resposta para uma pergunta
  static Future<bool> submitAnswer({
    required String sessionId,
    required String userId,
    required String questionId,
    required int selectedAnswer,
  }) async {
    try {
      final sessionRef = _db.collection('test_sessions').doc(sessionId);
      final answerKey = '${userId}_$questionId';
      final userAnswer = UserAnswer(
        userId: userId,
        questionId: questionId,
        selectedAnswer: selectedAnswer,
        answeredAt: DateTime.now(),
      );

      await sessionRef.update({
        'answers.$answerKey': userAnswer.toJson(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print(
          '✅ FirebaseTestSessionService: Resposta salva para $questionId por $userId',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FirebaseTestSessionService: Erro ao salvar resposta: $e');
      }
      return false;
    }
  }

  /// Submeter resultado do mini-jogo
  static Future<bool> submitMiniGameResult({
    required String sessionId,
    required String userId,
    required Map<String, dynamic>
    resultData, // e.g., {'completed': true, 'score': 100}
  }) async {
    try {
      final sessionRef = _db.collection('test_sessions').doc(sessionId);
      final miniGameResult = MiniGameResult(
        userId: userId,
        completed: resultData['completed'] as bool? ?? false,
        score: resultData['score'] as int? ?? 0,
        completedAt: DateTime.now(),
      );

      await sessionRef.update({
        'miniGameResults.$userId': miniGameResult.toJson(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print(
          '✅ FirebaseTestSessionService: Resultado do MiniGame salvo para $userId',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ FirebaseTestSessionService: Erro ao salvar resultado do MiniGame: $e',
        );
      }
      return false;
    }
  }

  /// Calcular compatibilidade e finalizar teste
  /// Esta função deve ser chamada DEPOIS que ambos os usuários completaram as perguntas E o minigame.
  static Future<Map<String, dynamic>?> completeTest({
    required String sessionId,
    required String
    userId, // UID do usuário que está acionando a finalização (pode ser um ou o sistema)
  }) async {
    try {
      final sessionRef = _db.collection('test_sessions').doc(sessionId);

      return await _db.runTransaction<Map<String, dynamic>?>((
        transaction,
      ) async {
        final sessionDoc = await transaction.get(sessionRef);
        if (!sessionDoc.exists) {
          if (kDebugMode)
            print(
              '❌ FirebaseTestSessionService: Sessão $sessionId não encontrada para completar.',
            );
          return null;
        }

        final sessionData = sessionDoc.data()!;
        // Não finalizar se já estiver finalizado
        if (sessionData['phase'] == TestPhase.result.name ||
            sessionData['phase'] == TestPhase.completed.name) {
          if (kDebugMode)
            print(
              'ℹ️ FirebaseTestSessionService: Sessão $sessionId já finalizada.',
            );
          return {
            'status': 'already_completed',
            'passed': sessionData['result'] == TestResult.passed.name,
            'compatibility':
                (sessionData['compatibilityScore'] as num?)?.toDouble() ?? 0.0,
            'sessionId': sessionId,
          };
        }

        final participants = List<String>.from(
          sessionData['participants'] as List? ?? [],
        );
        final questions = List<Map<String, dynamic>>.from(
          sessionData['questions'] as List? ?? [],
        );
        final answers = Map<String, dynamic>.from(
          sessionData['answers'] as Map? ?? {},
        );
        final miniGameResultsData = Map<String, dynamic>.from(
          sessionData['miniGameResults'] as Map? ?? {},
        );

        // Verificar se ambos usuários responderam todas as perguntas
        final allQuestionsAnswered = _checkAllAnswersSubmitted(
          participants,
          questions,
          answers,
        );
        if (!allQuestionsAnswered) {
          if (kDebugMode)
            print(
              '⏳ FirebaseTestSessionService: Sessão $sessionId aguardando respostas.',
            );
          return {
            'status': 'waiting_answers',
            'message': 'Aguardando todas as respostas.',
          };
        }

        // Verificar se ambos usuários completaram o minigame
        final allMiniGamesCompleted = _checkAllMiniGamesCompleted(
          participants,
          miniGameResultsData,
        );
        if (!allMiniGamesCompleted) {
          if (kDebugMode)
            print(
              '⏳ FirebaseTestSessionService: Sessão $sessionId aguardando resultados do minigame.',
            );
          return {
            'status': 'waiting_minigame',
            'message': 'Aguardando resultados do minigame.',
          };
        }

        final questionCompatibility = _calculateQuestionCompatibility(
          participants,
          questions,
          answers,
        );
        final miniGameCompatibility = _calculateMiniGameCompatibility(
          participants,
          miniGameResultsData,
        );

        // Ponderação: 60% perguntas, 40% minigame
        final compatibility =
            (questionCompatibility * 0.6) + (miniGameCompatibility * 0.4);
        final passed = compatibility >= 65.0;

        transaction.update(sessionRef, {
          'compatibilityScore': compatibility,
          'result': passed ? TestResult.passed.name : TestResult.failed.name,
          'phase': TestPhase.result.name, // Mudar para result primeiro
          'status': 'completed', // Status geral da sessão
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Atualizar status do convite para 'completed'
        final inviteId = sessionData['inviteId'] as String?;
        if (inviteId != null) {
          await _updateInviteStatus(
            inviteId,
            TestInviteStatus.completed.name,
            transaction: transaction,
          );
        }

        if (passed) {
          await _createUnlockedConnection(
            participants,
            compatibility,
            transaction: transaction,
          );
        } else {
          // Atualizar estatísticas de falha para ambos os usuários
          for (final participantId in participants) {
            await _updateUserStats(
              participantId,
              passed: false,
              transaction: transaction,
            );
          }
        }

        if (kDebugMode)
          print(
            '✅ FirebaseTestSessionService: Teste $sessionId completado. Score: $compatibility, Passou: $passed',
          );
        return {
          'status': 'completed',
          'passed': passed,
          'compatibility': compatibility,
          'sessionId': sessionId,
        };
      });
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ FirebaseTestSessionService: Erro ao completar teste $sessionId: $e',
        );
      }
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Escutar mudanças na sessão em tempo real
  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchSession(
    String sessionId,
  ) {
    return _db.collection('test_sessions').doc(sessionId).snapshots();
  }

  /// Buscar sessões ativas do usuário
  static Future<List<Map<String, dynamic>>> getUserActiveSessions(
    String userId,
  ) async {
    try {
      final query = await _db
          .collection('test_sessions')
          .where('participants', arrayContains: userId)
          .where('status', isEqualTo: 'active') // Apenas sessões ativas
          .orderBy('createdAt', descending: true)
          .limit(10) // Limitar para performance
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ FirebaseTestSessionService: Erro ao buscar sessões ativas: $e',
        );
      }
      return [];
    }
  }

  // ============== MÉTODOS PRIVADOS ==============

  static List<TestQuestion> _generateQuestions(
    UserModel user1,
    UserModel user2,
  ) {
    final commonInterests = user1.interesses
        .where((interest) => user2.interesses.contains(interest))
        .toList();
    commonInterests.shuffle();

    final questions = <TestQuestion>[];
    final usedQuestionIds = <String>{};

    final questionBank = {
      'Música': [
        const TestQuestion(
          id: 'm1',
          text: 'Qual seu estilo musical favorito para relaxar?',
          category: 'Música',
          options: ['Jazz/Bossa Nova', 'Pop/Rock', 'Clássica', 'Eletrônica'],
          correctAnswer: 0,
        ),
        const TestQuestion(
          id: 'm2',
          text: 'Prefere descobrir música nova como?',
          category: 'Música',
          options: [
            'Playlists de amigos',
            'Algoritmos do app',
            'Rádio',
            'Shows ao vivo',
          ],
          correctAnswer: 0,
        ),
      ],
      'Viagens': [
        const TestQuestion(
          id: 'v1',
          text: 'Seu tipo de viagem ideal:',
          category: 'Viagens',
          options: [
            'Aventura/Natureza',
            'Cultura/História',
            'Relaxamento',
            'Negócios',
          ],
          correctAnswer: 0,
        ),
        const TestQuestion(
          id: 'v2',
          text: 'Como gosta de planejar viagens?',
          category: 'Viagens',
          options: [
            'Roteiro detalhado',
            'Pontos principais',
            'Improviso total',
            'Depende do destino',
          ],
          correctAnswer: 0,
        ),
      ],
      'Geral': [
        const TestQuestion(
          id: 'g1',
          text: 'Em relacionamentos, você valoriza mais:',
          category: 'Geral',
          options: [
            'Comunicação aberta',
            'Momentos juntos',
            'Independência',
            'Aventuras compartilhadas',
          ],
          correctAnswer: 0,
        ),
        const TestQuestion(
          id: 'g2',
          text: 'Seu fim de semana perfeito:',
          category: 'Geral',
          options: [
            'Casa com amigos',
            'Explorar a cidade',
            'Natureza/Outdoor',
            'Eventos culturais',
          ],
          correctAnswer: 0,
        ),
      ],
    };

    for (final interest in commonInterests.take(2)) {
      final categoryQuestions = questionBank[interest];
      if (categoryQuestions != null && categoryQuestions.isNotEmpty) {
        final availableQuestions = categoryQuestions
            .where((q) => !usedQuestionIds.contains(q.id))
            .toList();
        if (availableQuestions.isNotEmpty) {
          final question =
              availableQuestions[Random().nextInt(availableQuestions.length)];
          questions.add(question);
          usedQuestionIds.add(question.id);
        }
      }
    }

    final generalQuestions = questionBank['Geral']!;
    while (questions.length < 3 &&
        usedQuestionIds.length <
            generalQuestions.length + commonInterests.length * 2) {
      final availableGeneralQuestions = generalQuestions
          .where((q) => !usedQuestionIds.contains(q.id))
          .toList();
      if (availableGeneralQuestions.isEmpty) break;
      final randomQuestion =
          availableGeneralQuestions[Random().nextInt(
            availableGeneralQuestions.length,
          )];
      questions.add(randomQuestion);
      usedQuestionIds.add(randomQuestion.id);
    }
    questions.shuffle();
    return questions;
  }

  static bool _checkAllAnswersSubmitted(
    List<String> participants,
    List<Map<String, dynamic>> questions,
    Map<String, dynamic> answers,
  ) {
    if (participants.isEmpty || questions.isEmpty) return false;
    for (final participant in participants) {
      for (final question in questions) {
        final questionId = question['id'] as String?;
        if (questionId == null) continue;
        final answerKey = '${participant}_$questionId';
        if (!answers.containsKey(answerKey)) {
          return false;
        }
      }
    }
    return true;
  }

  static bool _checkAllMiniGamesCompleted(
    List<String> participants,
    Map<String, dynamic> miniGameResultsData,
  ) {
    if (participants.isEmpty) return false;
    for (final participantId in participants) {
      final result =
          miniGameResultsData[participantId] as Map<String, dynamic>?;
      if (result == null || (result['completed'] as bool? ?? false) == false) {
        return false; // Se algum participante não tem resultado ou não completou
      }
    }
    return true; // Todos completaram
  }

  static double _calculateQuestionCompatibility(
    List<String> participants,
    List<Map<String, dynamic>> questions,
    Map<String, dynamic> answers,
  ) {
    if (participants.length != 2 || questions.isEmpty) return 0.0;

    final user1 = participants[0];
    final user2 = participants[1];
    double totalCompatibilityPoints = 0;

    for (final questionMap in questions) {
      final questionId = questionMap['id'] as String?;
      if (questionId == null) continue;

      final answer1Data =
          answers['${user1}_$questionId'] as Map<String, dynamic>?;
      final answer2Data =
          answers['${user2}_$questionId'] as Map<String, dynamic>?;

      if (answer1Data != null && answer2Data != null) {
        final answer1 = answer1Data['selectedAnswer'] as int?;
        final answer2 = answer2Data['selectedAnswer'] as int?;

        if (answer1 != null && answer2 != null) {
          if (answer1 == answer2) {
            totalCompatibilityPoints += 1.0; // 1 ponto por resposta idêntica
          } else if ((answer1 - answer2).abs() == 1) {
            totalCompatibilityPoints += 0.5; // 0.5 ponto por resposta próxima
          }
        }
      }
    }
    return (totalCompatibilityPoints / questions.length) * 100.0;
  }

  static double _calculateMiniGameCompatibility(
    List<String> participants,
    Map<String, dynamic> miniGameResultsData,
  ) {
    if (participants.length != 2) return 0.0;

    final user1Id = participants[0];
    final user2Id = participants[1];

    final result1 = miniGameResultsData[user1Id] as Map<String, dynamic>?;
    final result2 = miniGameResultsData[user2Id] as Map<String, dynamic>?;

    final completed1 = result1?['completed'] as bool? ?? false;
    final score1 = (result1?['score'] as num?)?.toDouble() ?? 0.0;
    final completed2 = result2?['completed'] as bool? ?? false;
    final score2 = (result2?['score'] as num?)?.toDouble() ?? 0.0;

    if (completed1 && completed2) {
      // Média dos scores se ambos completaram, normalizado para 0-100
      // Supondo que o score máximo do minigame seja 100 para cada.
      return ((score1 + score2) / 2.0).clamp(0.0, 100.0);
    } else if (completed1 || completed2) {
      return 30.0; // Pontuação menor se apenas um completou
    }
    return 0.0; // Nenhum completou
  }

  static Future<void> _createUnlockedConnection(
    List<String> participants,
    double compatibility, {
    Transaction? transaction, // Permitir passar uma transação existente
  }) async {
    try {
      final connectionRef = _db.collection('unlocked_connections').doc();
      final data = {
        'id': connectionRef.id,
        'participants': participants,
        'compatibility': compatibility,
        'status': 'active', // 'active', 'archived', etc.
        'chatEnabled': true,
        'unlockedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        // Adicionar IDs dos usuários para facilitar queries de "minhas conexões"
        'user1Id': participants[0],
        'user2Id': participants[1],
      };

      if (transaction != null) {
        transaction.set(connectionRef, data);
      } else {
        await connectionRef.set(data);
      }

      for (final userId in participants) {
        await _updateUserStats(userId, passed: true, transaction: transaction);
      }

      if (kDebugMode) {
        print(
          '✅ FirebaseTestSessionService: Conexão desbloqueada criada: ${connectionRef.id}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ FirebaseTestSessionService: Erro ao criar conexão desbloqueada: $e',
        );
      }
      // Considerar relançar o erro se estiver dentro de uma transação maior
      if (transaction != null) throw e;
    }
  }

  static Future<void> _updateUserStats(
    String userId, {
    required bool passed,
    Transaction? transaction, // Permitir passar uma transação existente
  }) async {
    try {
      final userRef = _db.collection('users').doc(userId);

      final DocumentSnapshot<Map<String, dynamic>> userDoc;
      if (transaction != null) {
        userDoc = await transaction.get(userRef);
      } else {
        userDoc = await userRef.get();
      }

      final userData = userDoc.data() ?? {};
      final stats = Map<String, dynamic>.from(
        userData['unlockStats'] as Map? ?? {},
      );
      final currentTests = (stats['totalTests'] as num?)?.toInt() ?? 0;
      final currentPassed = (stats['testsPassed'] as num?)?.toInt() ?? 0;
      final newTotalTests = currentTests + 1;
      final newTestsPassed = passed ? currentPassed + 1 : currentPassed;

      final Map<String, dynamic> updateData = {
        'unlockStats.totalTests': newTotalTests,
        'unlockStats.testsPassed': newTestsPassed,
        'unlockStats.successRate': newTotalTests > 0
            ? (newTestsPassed / newTotalTests) * 100
            : 0.0,
        'unlockStats.lastTestAt': FieldValue.serverTimestamp(),
      };

      if (transaction != null) {
        transaction.update(userRef, updateData);
      } else {
        await userRef.update(updateData);
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ FirebaseTestSessionService: Erro ao atualizar stats do usuário $userId: $e',
        );
      }
      if (transaction != null) throw e;
    }
  }

  static Future<void> _updateInviteStatus(
    String inviteId,
    String status, {
    Transaction? transaction, // Permitir passar uma transação existente
  }) async {
    try {
      final inviteRef = _db.collection('test_invites').doc(inviteId);
      final data = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (transaction != null) {
        transaction.update(inviteRef, data);
      } else {
        await inviteRef.update(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ FirebaseTestSessionService: Erro ao atualizar status do convite $inviteId: $e',
        );
      }
      if (transaction != null) throw e;
    }
  }
}
