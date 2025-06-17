// lib/services/firebase_test_session_service.dart
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:unlock/feature/social/providers/test_session_provider.dart';
import 'package:unlock/models/user_model.dart';

/// Service para gerenciar sessões de teste no Firebase
/// Substitui a lógica mock por implementação real
class FirebaseTestSessionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Timeout para sessões de teste
  static const Duration _sessionTimeout = Duration(minutes: 15);

  /// Criar nova sessão de teste entre dois usuários
  static Future<String?> createTestSession({
    required String inviteId,
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    try {
      // Validar usuário autenticado
      final firebaseUser = _auth.currentUser;
      if (firebaseUser?.uid != currentUser.uid) {
        throw Exception('Usuário não autorizado');
      }

      // Gerar perguntas baseadas em interesses comuns
      final questions = _generateQuestions(currentUser, otherUser);

      // Criar documento da sessão
      final sessionRef = _db.collection('test_sessions').doc();
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
        'miniGameResults': <String, dynamic>{},
        'phase': TestPhase.questions.name,
        'result': TestResult.pending.name,
        'compatibilityScore': 0.0,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(_sessionTimeout).toIso8601String(),
        'lastActivity': FieldValue.serverTimestamp(),
      };

      await sessionRef.set(sessionData);

      // Atualizar convite como aceito
      await _updateInviteStatus(inviteId, 'in_progress');

      if (kDebugMode) {
        print('✅ TestSession criada: ${sessionRef.id}');
      }

      return sessionRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao criar sessão: $e');
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

      // Usar transaction para consistência
      await _db.runTransaction((transaction) async {
        final sessionDoc = await transaction.get(sessionRef);

        if (!sessionDoc.exists) {
          throw Exception('Sessão não encontrada');
        }

        final sessionData = sessionDoc.data()!;
        final answers = Map<String, dynamic>.from(sessionData['answers'] ?? {});

        // Adicionar nova resposta
        answers['${userId}_$questionId'] = {
          'userId': userId,
          'questionId': questionId,
          'selectedAnswer': selectedAnswer,
          'answeredAt': DateTime.now().toIso8601String(),
        };

        // Atualizar documento
        transaction.update(sessionRef, {
          'answers': answers,
          'lastActivity': FieldValue.serverTimestamp(),
        });
      });

      if (kDebugMode) {
        print('✅ Resposta salva: $questionId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar resposta: $e');
      }
      return false;
    }
  }

  /// Calcular compatibilidade e finalizar teste
  static Future<Map<String, dynamic>?> completeTest({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final sessionRef = _db.collection('test_sessions').doc(sessionId);

      return await _db.runTransaction<Map<String, dynamic>?>((
        transaction,
      ) async {
        final sessionDoc = await transaction.get(sessionRef);

        if (!sessionDoc.exists) return null;

        final sessionData = sessionDoc.data()!;
        final participants = List<String>.from(sessionData['participants']);
        final questions = List<Map<String, dynamic>>.from(
          sessionData['questions'],
        );
        final answers = Map<String, dynamic>.from(sessionData['answers'] ?? {});

        // Verificar se ambos usuários responderam todas as perguntas
        final allAnswered = _checkAllAnswersSubmitted(
          participants,
          questions,
          answers,
        );

        if (!allAnswered) {
          return {'status': 'waiting', 'message': 'Aguardando outro usuário'};
        }

        // Calcular compatibilidade
        final compatibility = _calculateCompatibility(
          participants,
          questions,
          answers,
        );
        final passed = compatibility >= 65.0;

        // Atualizar sessão
        transaction.update(sessionRef, {
          'compatibilityScore': compatibility,
          'result': passed ? TestResult.passed.name : TestResult.failed.name,
          'phase': TestPhase.result.name,
          'status': passed ? 'unlocked' : 'rejected',
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Se passou, criar conexão desbloqueada
        if (passed) {
          await _createUnlockedConnection(participants, compatibility);
        }

        return {
          'status': 'completed',
          'passed': passed,
          'compatibility': compatibility,
          'sessionId': sessionId,
        };
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao completar teste: $e');
      }
      return null;
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
      await sessionRef.update({
        'miniGameResults.$userId': {
          ...resultData,
          'userId': userId,
          'completedAt': DateTime.now().toIso8601String(),
        },
        'lastActivity': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Resultado do MiniGame salvo para $userId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar resultado do MiniGame: $e');
      }
      return false;
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
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar sessões: $e');
      }
      return [];
    }
  }

  // ============== MÉTODOS PRIVADOS ==============

  /// Gerar perguntas baseadas em interesses comuns
  static List<TestQuestion> _generateQuestions(
    UserModel user1,
    UserModel user2,
  ) {
    final commonInterests = user1.interesses
        .where((interest) => user2.interesses.contains(interest))
        .toList();

    final questions = <TestQuestion>[];

    // Banco de perguntas por categoria
    final questionBank = {
      'Música': [
        TestQuestion(
          id: 'm1',
          text: 'Qual seu estilo musical favorito para relaxar?',
          category: 'Música',
          options: ['Jazz/Bossa Nova', 'Pop/Rock', 'Clássica', 'Eletrônica'],
          correctAnswer: 0, // Não há resposta "certa", será comparada
        ),
        TestQuestion(
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
        TestQuestion(
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
        TestQuestion(
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
        TestQuestion(
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
        TestQuestion(
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

    // Adicionar perguntas dos interesses comuns (máximo 2)
    for (final interest in commonInterests.take(2)) {
      final categoryQuestions = questionBank[interest];
      if (categoryQuestions != null) {
        questions.add(
          categoryQuestions[Random().nextInt(categoryQuestions.length)],
        );
      }
    }

    // Completar com perguntas gerais (mínimo 3 perguntas total)
    while (questions.length < 3) {
      final generalQuestions = questionBank['Geral']!;
      final question =
          generalQuestions[Random().nextInt(generalQuestions.length)];
      if (!questions.any((q) => q.id == question.id)) {
        questions.add(question);
      }
    }

    return questions;
  }

  /// Verificar se todos responderam
  static bool _checkAllAnswersSubmitted(
    List<String> participants,
    List<Map<String, dynamic>> questions,
    Map<String, dynamic> answers,
  ) {
    for (final participant in participants) {
      for (final question in questions) {
        final answerKey = '${participant}_${question['id']}';
        if (!answers.containsKey(answerKey)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Calcular compatibilidade entre respostas
  static double _calculateCompatibility(
    List<String> participants,
    List<Map<String, dynamic>> questions,
    Map<String, dynamic> answers,
  ) {
    if (participants.length != 2) return 0.0;

    final user1 = participants[0];
    final user2 = participants[1];
    int totalQuestions = questions.length;
    int compatibleAnswers = 0;

    for (final question in questions) {
      final questionId = question['id'];
      final answer1Key = '${user1}_$questionId';
      final answer2Key = '${user2}_$questionId';

      if (answers.containsKey(answer1Key) && answers.containsKey(answer2Key)) {
        final answer1 = answers[answer1Key]['selectedAnswer'] as int;
        final answer2 = answers[answer2Key]['selectedAnswer'] as int;

        // Respostas idênticas: +100% compatibilidade para essa pergunta
        // Respostas próximas (diferença de 1): +50%
        // Outras: 0%
        if (answer1 == answer2) {
          compatibleAnswers += 100;
        } else if ((answer1 - answer2).abs() == 1) {
          compatibleAnswers += 50;
        }
      }
    }

    return totalQuestions > 0
        ? (compatibleAnswers / (totalQuestions * 100)) * 100
        : 0.0;
  }

  /// Criar conexão desbloqueada
  static Future<void> _createUnlockedConnection(
    List<String> participants,
    double compatibility,
  ) async {
    try {
      final connectionRef = _db.collection('unlocked_connections').doc();
      await connectionRef.set({
        'id': connectionRef.id,
        'participants': participants,
        'compatibility': compatibility,
        'status': 'unlocked',
        'chatEnabled': true,
        'unlockedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // Atualizar estatísticas dos usuários
      for (final userId in participants) {
        await _updateUserStats(userId, passed: true);
      }

      if (kDebugMode) {
        print('✅ Conexão desbloqueada criada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao criar conexão: $e');
      }
    }
  }

  /// Atualizar estatísticas do usuário
  static Future<void> _updateUserStats(
    String userId, {
    required bool passed,
  }) async {
    try {
      final userRef = _db.collection('users').doc(userId);
      await _db.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final userData = userDoc.data() ?? {};

        final stats = Map<String, dynamic>.from(userData['unlockStats'] ?? {});
        final currentTests = stats['totalTests'] ?? 0;
        final currentPassed = stats['testsPassed'] ?? 0;

        transaction.update(userRef, {
          'unlockStats.totalTests': currentTests + 1,
          'unlockStats.testsPassed': passed ? currentPassed + 1 : currentPassed,
          'unlockStats.successRate': passed
              ? ((currentPassed + 1) / (currentTests + 1)) * 100
              : (currentPassed / (currentTests + 1)) * 100,
          'unlockStats.lastTestAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao atualizar stats: $e');
      }
    }
  }

  /// Atualizar status do convite
  static Future<void> _updateInviteStatus(
    String inviteId,
    String status,
  ) async {
    try {
      await _db.collection('test_invites').doc(inviteId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao atualizar convite: $e');
      }
    }
  }
}
