// lib/services/challenge_service.dart - ATUALIZADO COM MINI-GAMES
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/models/mini_game_model.dart';
import 'package:unlock/models/submission_model.dart';
import 'package:unlock/services/mini_game_service.dart';

class ChallengeService {
  static final _db = FirebaseFirestore.instance;
  static const _challengesCollection = 'challenges';
  static const _submissionsCollection = 'submissions';
  static const _challengeParticipantsCollection =
      'challenge_participants'; // ✅ NOVO

  // ========== BUSCAR DESAFIOS ==========

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
              .map((doc) => Challenge.fromJson({...doc.data()!, 'id': doc.id}))
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
              .map((doc) => Challenge.fromJson({...doc.data()!, 'id': doc.id}))
              .toList(),
        );
  }

  /// ✅ NOVO: Buscar desafios de mini-games
  static Stream<List<Challenge>> getMiniGameChallenges({
    GameType? gameType,
    GameDifficulty? difficulty,
  }) {
    Query query = _db
        .collection(_challengesCollection)
        .where('type', isEqualTo: 'performance')
        .where('status', isEqualTo: 'active')
        .where('miniGameConfig', isNotEqualTo: null);

    if (gameType != null) {
      query = query.where('miniGameConfig.gameType', isEqualTo: gameType.id);
    }

    if (difficulty != null) {
      query = query.where(
        'miniGameConfig.difficulty',
        isEqualTo: difficulty.id,
      );
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                if (data == null || data is! Map<String, dynamic>) return null;
                return Challenge.fromJson({...data, 'id': doc.id});
              })
              .whereType<Challenge>()
              .toList(),
        );
  }

  /// Buscar meus desafios
  static Stream<List<Challenge>> getMyChallenges(String userId) {
    return _db
        .collection(_challengesCollection)
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => doc.data() != null
                    ? Challenge.fromJson({...doc.data(), 'id': doc.id})
                    : null,
              )
              .whereType<Challenge>()
              .toList(),
        );
  }

  // ========== PARTICIPAÇÃO EM DESAFIOS ==========

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

        final challenge = Challenge.fromJson({
          ...challengeDoc.data()!,
          'id': challengeDoc.id,
        });

        if (!challenge.canUserJoin(userId)) {
          throw Exception('Não é possível participar do desafio');
        }

        // Atualizar lista de participantes
        final updatedParticipants = List<String>.from(challenge.participants);
        if (!updatedParticipants.contains(userId)) {
          updatedParticipants.add(userId);
        }

        transaction.update(challengeRef, {'participants': updatedParticipants});

        // ✅ NOVO: Para desafios de mini-game, criar registro de participação
        if (challenge.isMiniGameChallenge) {
          await _createMiniGameParticipation(
            transaction,
            challengeId,
            userId,
            challenge.miniGameConfig!,
          );
        }
      });

      AppLogger.info(
        '✅ Usuário entrou no desafio',
        data: {'challengeId': challengeId, 'userId': userId},
      );

      return true;
    } catch (e) {
      AppLogger.error('❌ Erro ao entrar no desafio', error: e);
      return false;
    }
  }

  /// ✅ NOVO: Criar participação em mini-game
  static Future<void> _createMiniGameParticipation(
    Transaction transaction,
    String challengeId,
    String userId,
    MiniGameChallengeConfig config,
  ) async {
    final participationRef = _db
        .collection(_challengeParticipantsCollection)
        .doc('${challengeId}_$userId');

    transaction.set(participationRef, {
      'challengeId': challengeId,
      'userId': userId,
      'gameType': config.gameType.id,
      'difficulty': config.difficulty.id,
      'targetScore': config.targetScore,
      'maxAttempts': config.maxAttempts,
      'attemptsUsed': 0,
      'bestScore': 0,
      'bestResult': null,
      'joinedAt': Timestamp.now(),
      'lastAttemptAt': null,
      'status': 'active',
    });
  }

  /// ✅ NOVO: Submeter resultado de mini-game para desafio
  static Future<bool> submitMiniGameResult(
    String challengeId,
    String userId,
    GameResult gameResult,
  ) async {
    try {
      AppLogger.info(
        '🎮 Submetendo resultado de mini-game',
        data: {
          'challengeId': challengeId,
          'userId': userId,
          'score': gameResult.finalScore,
        },
      );

      final participationRef = _db
          .collection(_challengeParticipantsCollection)
          .doc('${challengeId}_$userId');

      await _db.runTransaction((transaction) async {
        final participationDoc = await transaction.get(participationRef);

        if (!participationDoc.exists) {
          throw Exception('Participação não encontrada');
        }

        final participationData = participationDoc.data()!;
        final attemptsUsed = participationData['attemptsUsed'] as int;
        final maxAttempts = participationData['maxAttempts'] as int;
        final currentBest = participationData['bestScore'] as int;

        // Verificar se ainda tem tentativas
        if (attemptsUsed >= maxAttempts) {
          throw Exception('Máximo de tentativas excedido');
        }

        // Atualizar se é melhor score
        final isNewBest = gameResult.finalScore > currentBest;

        final updatedData = {
          'attemptsUsed': attemptsUsed + 1,
          'lastAttemptAt': Timestamp.now(),
        };

        if (isNewBest) {
          updatedData['bestScore'] = gameResult.finalScore;
          updatedData['bestResult'] = gameResult.toJson();
        }

        transaction.update(participationRef, updatedData);

        // Salvar resultado individual também
        await MiniGameService.saveGameResult(gameResult);

        // Criar submissão para o desafio
        await _createChallengeSubmission(
          transaction,
          challengeId,
          userId,
          gameResult,
          isNewBest,
        );
      });

      AppLogger.info('✅ Resultado de mini-game submetido com sucesso');
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro ao submeter resultado de mini-game', error: e);
      return false;
    }
  }

  /// ✅ NOVO: Criar submissão de desafio
  static Future<void> _createChallengeSubmission(
    Transaction transaction,
    String challengeId,
    String userId,
    GameResult gameResult,
    bool isNewBest,
  ) async {
    final submissionRef = _db.collection(_submissionsCollection).doc();

    final submission = Submission(
      id: submissionRef.id,
      challengeId: challengeId,
      userId: userId,
      username: '', // Será preenchido depois
      userAvatar: '🎮',
      type:
          SubmissionType.score, // ✅ CORRIGIDO: Adicionado parâmetro obrigatório
      content: {
        'gameType': gameResult.type.id,
        'difficulty': gameResult.difficulty.id,
        'score': gameResult.finalScore,
        'duration': gameResult.duration.inMilliseconds,
        'rank': gameResult.rank,
        'stats': gameResult.stats,
        'isNewBest': isNewBest,
      },
      submittedAt: DateTime.now(),
      score: gameResult.finalScore.toDouble(),
      metadata: {
        'gameResultId': gameResult.gameId,
        'isPersonalBest': gameResult.isPersonalBest,
      },
    );

    transaction.set(submissionRef, submission.toJson());
  }

  /// ✅ NOVO: Buscar participação do usuário em desafio de mini-game
  static Future<Map<String, dynamic>?> getMiniGameParticipation(
    String challengeId,
    String userId,
  ) async {
    try {
      final participationDoc = await _db
          .collection(_challengeParticipantsCollection)
          .doc('${challengeId}_$userId')
          .get();

      if (participationDoc.exists) {
        return participationDoc.data();
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar participação', error: e);
      return null;
    }
  }

  /// ✅ NOVO: Buscar ranking de desafio de mini-game
  static Stream<List<Map<String, dynamic>>> getMiniGameChallengeRanking(
    String challengeId,
  ) {
    return _db
        .collection(_challengeParticipantsCollection)
        .where('challengeId', isEqualTo: challengeId)
        .where('bestScore', isGreaterThan: 0)
        .orderBy('bestScore', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            final data = doc.data();

            return {...data, 'position': index + 1, 'id': doc.id};
          }).toList();
        });
  }

  // ========== SUBMISSÕES ==========

  /// Buscar submissões de um desafio
  static Stream<List<Submission>> getChallengeSubmissions(String challengeId) {
    return _db
        .collection(_submissionsCollection)
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('score', descending: true)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Submission.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// ✅ NOVO: Buscar submissões de mini-game de um desafio
  static Stream<List<Submission>> getMiniGameChallengeSubmissions(
    String challengeId,
  ) {
    return _db
        .collection(_submissionsCollection)
        .where('challengeId', isEqualTo: challengeId)
        .where('type', isEqualTo: 'score')
        .orderBy('score', descending: true)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Submission.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // ========== CRIAR DESAFIOS ==========

  /// ✅ NOVO: Criar desafio de mini-game
  static Future<String?> createMiniGameChallenge({
    required String title,
    required String description,
    required String creatorId,
    required DateTime startsAt,
    required DateTime endsAt,
    required ArenaType arena,
    required GameType gameType,
    required GameDifficulty difficulty,
    required int targetScore,
    Duration? timeLimit,
    int? maxAttempts,
    int? maxParticipants,
    int? entryFee,
    Map<String, int>? rewards,
    List<String>? tags,
    String? groupId,
  }) async {
    try {
      AppLogger.info(
        '🎮 Criando desafio de mini-game',
        data: {
          'title': title,
          'gameType': gameType.name,
          'difficulty': difficulty.label,
          'arena': arena.label,
        },
      );

      final miniGameConfig = MiniGameChallengeConfig(
        gameType: gameType,
        difficulty: difficulty,
        targetScore: targetScore,
        timeLimit: timeLimit,
        maxAttempts: maxAttempts ?? 3,
      );

      final challenge = Challenge.createMiniGame(
        title: title,
        description: description,
        creatorId: creatorId,
        startsAt: startsAt,
        endsAt: endsAt,
        arena: arena,
        miniGameConfig: miniGameConfig,
        maxParticipants: maxParticipants,
        entryFee: entryFee,
        rewards: rewards,
        tags: tags,
        groupId: groupId,
      );

      final docRef = await _db
          .collection(_challengesCollection)
          .add(challenge.toJson());

      AppLogger.info(
        '✅ Desafio de mini-game criado',
        data: {'challengeId': docRef.id},
      );

      return docRef.id;
    } catch (e) {
      AppLogger.error('❌ Erro ao criar desafio de mini-game', error: e);
      return null;
    }
  }

  /// Criar desafio tradicional
  static Future<String?> createChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required ArenaType arena,
    required String creatorId,
    required DateTime startsAt,
    required DateTime endsAt,
    DateTime? votingEndsAt,
    int? maxParticipants,
    int? entryFee,
    Map<String, int>? rewards,
    List<String>? tags,
    String? groupId,
    Map<String, dynamic>? rules,
  }) async {
    try {
      AppLogger.info(
        '📝 Criando desafio',
        data: {'title': title, 'type': type.label, 'arena': arena.label},
      );

      final challenge = Challenge.create(
        title: title,
        description: description,
        type: type,
        arena: arena,
        creatorId: creatorId,
        startsAt: startsAt,
        endsAt: endsAt,
        votingEndsAt: votingEndsAt,
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

      AppLogger.info('✅ Desafio criado', data: {'challengeId': docRef.id});

      return docRef.id;
    } catch (e) {
      AppLogger.error('❌ Erro ao criar desafio', error: e);
      return null;
    }
  }

  // ========== SUBMISSÕES TRADICIONAIS ==========

  /// ✅ NOVO: Submeter entrada tradicional (não mini-game)
  static Future<String?> submitEntry({
    required String challengeId,
    required String userId,
    required String username,
    required String userAvatar,
    required SubmissionType type,
    required Map<String, dynamic> content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.info(
        '📝 Submetendo entrada tradicional',
        data: {'challengeId': challengeId, 'userId': userId, 'type': type.name},
      );

      final submissionRef = _db.collection(_submissionsCollection).doc();

      final submission = Submission(
        id: submissionRef.id,
        challengeId: challengeId,
        userId: userId,
        username: username,
        userAvatar: userAvatar,
        type: type,
        content: content,
        submittedAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      await submissionRef.set(submission.toJson());

      AppLogger.info('✅ Entrada submetida com sucesso');
      return submissionRef.id;
    } catch (e) {
      AppLogger.error('❌ Erro ao submeter entrada', error: e);
      return null;
    }
  }

  /// ✅ NOVO: Votar em submissão
  static Future<bool> voteSubmission({
    required String submissionId,
    required String userId,
    required bool isUpvote,
  }) async {
    try {
      AppLogger.info(
        '🗳️ Votando em submissão',
        data: {
          'submissionId': submissionId,
          'userId': userId,
          'isUpvote': isUpvote,
        },
      );

      final submissionRef = _db
          .collection(_submissionsCollection)
          .doc(submissionId);

      await _db.runTransaction((transaction) async {
        final submissionDoc = await transaction.get(submissionRef);

        if (!submissionDoc.exists) {
          throw Exception('Submissão não encontrada');
        }

        final submission = Submission.fromJson({
          ...submissionDoc.data()!,
          'id': submissionDoc.id,
        });

        final newVotes = isUpvote ? submission.votes + 1 : submission.votes - 1;

        transaction.update(submissionRef, {
          'votes': newVotes.clamp(0, double.infinity).toInt(),
        });
      });

      AppLogger.info('✅ Voto registrado com sucesso');
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro ao votar', error: e);
      return false;
    }
  }

  // ========== UTILIDADES ==========

  /// ✅ NOVO: Verificar se usuário pode tentar novamente
  static Future<bool> canUserRetryMiniGame(
    String challengeId,
    String userId,
  ) async {
    try {
      final participation = await getMiniGameParticipation(challengeId, userId);

      if (participation == null) return false;

      final attemptsUsed = participation['attemptsUsed'] as int;
      final maxAttempts = participation['maxAttempts'] as int;

      return attemptsUsed < maxAttempts;
    } catch (e) {
      AppLogger.error('❌ Erro ao verificar tentativas', error: e);
      return false;
    }
  }

  /// ✅ NOVO: Obter tentativas restantes
  static Future<int> getRemainingAttempts(
    String challengeId,
    String userId,
  ) async {
    try {
      final participation = await getMiniGameParticipation(challengeId, userId);

      if (participation == null) return 0;

      final attemptsUsed = participation['attemptsUsed'] as int;
      final maxAttempts = participation['maxAttempts'] as int;

      return maxAttempts - attemptsUsed;
    } catch (e) {
      AppLogger.error('❌ Erro ao obter tentativas restantes', error: e);
      return 0;
    }
  }

  /// Buscar desafio por ID
  static Future<Challenge?> getChallengeById(String challengeId) async {
    try {
      final doc = await _db
          .collection(_challengesCollection)
          .doc(challengeId)
          .get();

      if (doc.exists) {
        return Challenge.fromJson({...doc.data()!, 'id': doc.id});
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar desafio', error: e);
      return null;
    }
  }

  /// Cancelar desafio
  static Future<bool> cancelChallenge(String challengeId) async {
    try {
      await _db.collection(_challengesCollection).doc(challengeId).update({
        'status': 'cancelled',
      });

      AppLogger.info('✅ Desafio cancelado', data: {'challengeId': challengeId});
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro ao cancelar desafio', error: e);
      return false;
    }
  }
}
