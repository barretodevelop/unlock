// lib/services/challenge_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/models/submission_model.dart';

class ChallengeService {
  static final _db = FirebaseFirestore.instance;
  static const _challengesCollection = 'challenges';
  static const _submissionsCollection = 'submissions';

  // Buscar desafios ativos
  static Stream<List<Challenge>> getActiveChallenges() {
    return _db
        .collection(_challengesCollection)
        .where('status', isEqualTo: 'active')
        .where('startsAt', isLessThanOrEqualTo: DateTime.now())
        .where('endsAt', isGreaterThan: DateTime.now())
        .orderBy('endsAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Challenge.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Buscar desafios por tipo
  static Stream<List<Challenge>> getChallengesByType(ChallengeType type) {
    return _db
        .collection(_challengesCollection)
        .where('type', isEqualTo: type.id)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Challenge.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Participar de um desafio
  static Future<bool> joinChallenge(String challengeId, String userId) async {
    try {
      final challengeRef = _db
          .collection(_challengesCollection)
          .doc(challengeId);

      await _db.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);
        if (!challengeDoc.exists) throw Exception('Desafio não encontrado');

        final challenge = Challenge.fromJson({
          ...challengeDoc.data()!,
          'id': challengeDoc.id,
        });

        if (!challenge.canJoin) {
          throw Exception('Não é possível participar deste desafio');
        }

        if (challenge.participants.contains(userId)) {
          throw Exception('Você já está participando deste desafio');
        }

        final newParticipants = [...challenge.participants, userId];
        transaction.update(challengeRef, {'participants': newParticipants});
      });

      AppLogger.info('Usuário $userId entrou no desafio $challengeId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao participar do desafio', error: e);
      return false;
    }
  }

  // Submeter participação
  static Future<bool> submitEntry(
    String challengeId,
    String userId,
    String username,
    String userAvatar,
    SubmissionType type,
    Map<String, dynamic> content,
  ) async {
    try {
      final submission = Submission(
        id: '',
        challengeId: challengeId,
        userId: userId,
        username: username,
        userAvatar: userAvatar,
        type: type,
        content: content,
        submittedAt: DateTime.now(),
      );

      await _db.collection(_submissionsCollection).add(submission.toJson());
      AppLogger.info('Submissão criada para desafio $challengeId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao submeter entrada', error: e);
      return false;
    }
  }

  // Buscar submissões de um desafio
  static Stream<List<Submission>> getChallengeSubmissions(String challengeId) {
    return _db
        .collection(_submissionsCollection)
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Submission.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Votar em uma submissão
  static Future<bool> voteSubmission(String submissionId, String userId) async {
    try {
      final voteRef = _db.collection('votes').doc('${submissionId}_$userId');
      final submissionRef = _db
          .collection(_submissionsCollection)
          .doc(submissionId);

      await _db.runTransaction((transaction) async {
        final voteDoc = await transaction.get(voteRef);
        if (voteDoc.exists) {
          throw Exception('Você já votou nesta submissão');
        }

        transaction.set(voteRef, {
          'submissionId': submissionId,
          'userId': userId,
          'votedAt': Timestamp.now(),
        });

        transaction.update(submissionRef, {'votes': FieldValue.increment(1)});
      });

      return true;
    } catch (e) {
      AppLogger.error('Erro ao votar', error: e);
      return false;
    }
  }

  // Criar novo desafio
  static Future<String?> createChallenge(Challenge challenge) async {
    try {
      final docRef = await _db
          .collection(_challengesCollection)
          .add(challenge.toJson());
      AppLogger.info('Desafio criado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Erro ao criar desafio', error: e);
      return null;
    }
  }

  // Buscar meus desafios
  static Stream<List<Challenge>> getMyChallenges(String userId) {
    return _db
        .collection(_challengesCollection)
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Challenge.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }
}
