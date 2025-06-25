// lib/services/challenge_service.dart - ATUALIZADO COM SISTEMA DE VOTAÇÃO
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/models/submission_model.dart';
import 'package:unlock/models/vote_model.dart';
import 'package:unlock/services/voting_service.dart';

class ChallengeService {
  static final _db = FirebaseFirestore.instance;
  static const _challengesCollection = 'challenges';
  static const _submissionsCollection = 'submissions';

  // ========== MÉTODOS EXISTENTES (MANTIDOS) ==========

  /// Buscar desafios ativos
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

  /// Buscar desafios por tipo
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

  /// Buscar meus desafios
  static Stream<List<Challenge>> getMyChallenges(String userId) {
    return _db
        .collection(_challengesCollection)
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Challenge.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Participar de um desafio
  static Future<bool> joinChallenge(String challengeId, String userId) async {
    try {
      final challengeRef = _db
          .collection(_challengesCollection)
          .doc(challengeId);

      await _db.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);

        if (!challengeDoc.exists) {
          throw Exception('Desafio não encontrado');
        }

        final challengeData = challengeDoc.data()!;
        final participants = List<String>.from(
          challengeData['participants'] ?? [],
        );

        if (!participants.contains(userId)) {
          participants.add(userId);
          transaction.update(challengeRef, {'participants': participants});
        }
      });

      AppLogger.info('✅ Usuário $userId entrou no desafio $challengeId');
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro ao entrar no desafio: $e');
      return false;
    }
  }

  /// Buscar submissões de um desafio
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

  // ========== NOVOS MÉTODOS PARA VOTAÇÃO ==========

  /// Buscar desafios em votação
  static Stream<List<Challenge>> getVotingChallenges() {
    return _db
        .collection(_challengesCollection)
        .where('status', isEqualTo: 'voting')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Challenge.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Verificar se desafio precisa mudar para período de votação
  static Future<void> checkAndUpdateVotingStatus(String challengeId) async {
    try {
      final challengeRef = _db
          .collection(_challengesCollection)
          .doc(challengeId);

      await _db.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);

        if (!challengeDoc.exists) return;

        final challenge = Challenge.fromJson({
          ...challengeDoc.data()!,
          'id': challengeId,
        });

        final now = DateTime.now();

        // Verificar se deve iniciar votação
        if (challenge.status == ChallengeStatus.active &&
            challenge.submissionEndsAt != null &&
            now.isAfter(challenge.submissionEndsAt!) &&
            challenge.hasVoting) {
          AppLogger.info('🗳️ Iniciando período de votação: $challengeId');
          transaction.update(challengeRef, {'status': 'voting'});
        }
        // Verificar se votação deve terminar
        else if (challenge.status == ChallengeStatus.voting &&
            challenge.votingConfig?.votingEndsAt != null &&
            now.isAfter(challenge.votingConfig!.votingEndsAt!)) {
          AppLogger.info('🏁 Finalizando votação: $challengeId');
          await _finalizeVoting(challengeId, transaction);
        }
      });
    } catch (e) {
      AppLogger.error('❌ Erro ao verificar status de votação: $e');
    }
  }

  /// Finalizar votação e determinar vencedores
  static Future<void> _finalizeVoting(
    String challengeId,
    Transaction transaction,
  ) async {
    try {
      // Buscar ranking final de votação
      final rankingStats = await VotingService.getVotingRanking(
        challengeId: challengeId,
        limit: 100,
      ).first;

      if (rankingStats.isNotEmpty) {
        // Determinar vencedores (top 3)
        final winners = rankingStats.take(3).toList();

        for (int i = 0; i < winners.length; i++) {
          final stats = winners[i];
          final submissionRef = _db
              .collection(_submissionsCollection)
              .doc(stats.submissionId);

          // Marcar submissão como vencedora se for o primeiro lugar
          transaction.update(submissionRef, {
            'isWinner': i == 0,
            'finalRanking': i + 1,
            'finalScore': stats.score,
          });
        }

        AppLogger.info('🏆 Vencedores determinados para $challengeId');
      }

      // Atualizar status do desafio
      final challengeRef = _db
          .collection(_challengesCollection)
          .doc(challengeId);
      transaction.update(challengeRef, {
        'status': 'completed',
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      AppLogger.error('❌ Erro ao finalizar votação: $e');
      rethrow;
    }
  }

  /// Criar desafio com votação
  static Future<String?> createChallengeWithVoting({
    required String title,
    required String description,
    required ChallengeType type,
    required ArenaType arena,
    required String creatorId,
    required DateTime startsAt,
    required DateTime submissionEndsAt,
    required DateTime votingEndsAt,
    bool allowSelfVoting = false,
    int maxVotesPerUser = 100,
    List<VoteType> allowedVoteTypes = VoteType.values,
    Map<String, dynamic>? antiManipulation,
    int? maxParticipants,
    int? entryFee,
    Map<String, int>? rewards,
    List<String>? tags,
    String? groupId,
    Map<String, dynamic>? rules,
  }) async {
    try {
      AppLogger.info('🎯 Criando desafio com votação: $title');

      final challenge = Challenge.createWithVoting(
        title: title,
        description: description,
        type: type,
        arena: arena,
        creatorId: creatorId,
        startsAt: startsAt,
        submissionEndsAt: submissionEndsAt,
        votingEndsAt: votingEndsAt,
        allowSelfVoting: allowSelfVoting,
        maxVotesPerUser: maxVotesPerUser,
        allowedVoteTypes: allowedVoteTypes,
        antiManipulation: antiManipulation,
        maxParticipants: maxParticipants,
        entryFee: entryFee,
        rewards: rewards,
        tags: tags,
        groupId: groupId,
        rules: rules,
      );

      final docRef = await _db
          .collection(_challengesCollection)
          .add(challenge.toJson());

      // Atualizar com ID gerado
      await docRef.update({'id': docRef.id});

      AppLogger.info('✅ Desafio criado com sucesso: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('❌ Erro ao criar desafio: $e');
      return null;
    }
  }

  /// Enviar submissão para desafio
  static Future<String?> submitToChallenge({
    required String challengeId,
    required String userId,
    required String username,
    required String userAvatar,
    required SubmissionType type,
    required Map<String, dynamic> content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.info('📤 Enviando submissão para desafio: $challengeId');

      // Verificar se ainda está no período de submissão
      final challengeDoc = await _db
          .collection(_challengesCollection)
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) {
        AppLogger.warning('❌ Desafio não encontrado: $challengeId');
        return null;
      }

      final challenge = Challenge.fromJson({
        ...challengeDoc.data()!,
        'id': challengeId,
      });

      if (!challenge.isSubmissionPeriod) {
        AppLogger.warning('❌ Período de submissão encerrado: $challengeId');
        return null;
      }

      // Verificar se usuário já tem submissão
      final existingSubmission = await _getUserSubmissionInChallenge(
        challengeId,
        userId,
      );
      if (existingSubmission != null) {
        AppLogger.warning('❌ Usuário já tem submissão neste desafio');
        return null;
      }

      final submission = Submission.create(
        challengeId: challengeId,
        userId: userId,
        username: username,
        userAvatar: userAvatar,
        type: type,
        content: content,
        metadata: metadata,
      );

      final docRef = await _db
          .collection(_submissionsCollection)
          .add(submission.toJson());

      // Atualizar com ID gerado
      await docRef.update({'id': docRef.id});

      AppLogger.info('✅ Submissão criada com sucesso: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('❌ Erro ao enviar submissão: $e');
      return null;
    }
  }

  /// Buscar submissão do usuário em um desafio
  static Future<Submission?> _getUserSubmissionInChallenge(
    String challengeId,
    String userId,
  ) async {
    try {
      final querySnapshot = await _db
          .collection(_submissionsCollection)
          .where('challengeId', isEqualTo: challengeId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Submission.fromJson({...doc.data(), 'id': doc.id});
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar submissão do usuário: $e');
      return null;
    }
  }

  /// Buscar submissões do usuário em desafios
  static Stream<List<Submission>> getUserSubmissions(String userId) {
    return _db
        .collection(_submissionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Submission.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Buscar desafios que estão prestes a entrar em votação (próximas 24h)
  static Stream<List<Challenge>> getUpcomingVotingChallenges() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    return _db
        .collection(_challengesCollection)
        .where('status', isEqualTo: 'active')
        .where('submissionEndsAt', isGreaterThan: now)
        .where('submissionEndsAt', isLessThanOrEqualTo: tomorrow)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Challenge.fromJson({...doc.data(), 'id': doc.id}))
              .where((challenge) => challenge.hasVoting)
              .toList(),
        );
  }

  /// Buscar estatísticas gerais de votação
  static Future<Map<String, dynamic>> getVotingStatistics(
    String challengeId,
  ) async {
    try {
      final submissionsSnapshot = await _db
          .collection(_submissionsCollection)
          .where('challengeId', isEqualTo: challengeId)
          .get();

      final votesSnapshot = await _db
          .collection('votes')
          .where('challengeId', isEqualTo: challengeId)
          .get();

      final totalSubmissions = submissionsSnapshot.docs.length;
      final totalVotes = votesSnapshot.docs.length;
      final uniqueVoters = votesSnapshot.docs
          .map((doc) => doc.data()['voterId'])
          .toSet()
          .length;

      // Calcular média de votos por submissão
      final avgVotesPerSubmission = totalSubmissions > 0
          ? (totalVotes / totalSubmissions).toStringAsFixed(1)
          : '0';

      return {
        'totalSubmissions': totalSubmissions,
        'totalVotes': totalVotes,
        'uniqueVoters': uniqueVoters,
        'avgVotesPerSubmission': avgVotesPerSubmission,
        'participationRate': totalSubmissions > 0
            ? ((uniqueVoters / totalSubmissions) * 100).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar estatísticas: $e');
      return {};
    }
  }

  /// Agendar verificações automáticas de status
  static Future<void> scheduleVotingStatusChecks() async {
    try {
      // Buscar desafios que podem precisar de atualização de status
      final challenges = await _db
          .collection(_challengesCollection)
          .where('status', whereIn: ['active', 'voting'])
          .get();

      for (final doc in challenges.docs) {
        final challengeId = doc.id;
        await checkAndUpdateVotingStatus(challengeId);

        // Pequeno delay para não sobrecarregar o Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      AppLogger.info('✅ Verificação automática de status concluída');
    } catch (e) {
      AppLogger.error('❌ Erro na verificação automática: $e');
    }
  }

  /// Obter detalhes completos de um desafio com estatísticas
  static Future<Map<String, dynamic>?> getChallengeWithDetails(
    String challengeId,
  ) async {
    try {
      final challengeDoc = await _db
          .collection(_challengesCollection)
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) return null;

      final challenge = Challenge.fromJson({
        ...challengeDoc.data()!,
        'id': challengeId,
      });

      final stats = await getVotingStatistics(challengeId);

      return {'challenge': challenge, 'statistics': stats};
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar detalhes do desafio: $e');
      return null;
    }
  }

  /// Buscar top submissões por votos em todos os desafios
  static Stream<List<Submission>> getTopVotedSubmissions({int limit = 10}) {
    return _db
        .collection(_submissionsCollection)
        .where('votes', isGreaterThan: 0)
        .orderBy('votes', descending: true)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Submission.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Buscar desafios por status
  static Stream<List<Challenge>> getChallengesByStatus(ChallengeStatus status) {
    return _db
        .collection(_challengesCollection)
        .where('status', isEqualTo: status.id)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Challenge.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }
}
