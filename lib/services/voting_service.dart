// lib/services/voting_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/submission_model.dart';
import 'package:unlock/models/vote_model.dart';

class VotingService {
  static final _db = FirebaseFirestore.instance;
  static const _votesCollection = 'votes';
  static const _submissionsCollection = 'submissions';

  /// Votar em uma submissão
  static Future<bool> voteOnSubmission({
    required String submissionId,
    required String challengeId,
    required String voterId,
    required String voterUsername,
    required VoteType voteType,
    VotingConfig? config,
  }) async {
    try {
      AppLogger.debug('🗳️ Iniciando votação: $submissionId');

      // Validar permissões de votação
      final canVote = await _canUserVote(
        submissionId: submissionId,
        challengeId: challengeId,
        voterId: voterId,
        config: config,
      );

      if (!canVote.isValid) {
        AppLogger.warning('❌ Votação negada: ${canVote.reason}');
        return false;
      }

      // Verificar se já votou (para substituir ou bloquear)
      final existingVote = await _getUserVoteOnSubmission(
        submissionId: submissionId,
        voterId: voterId,
      );

      final vote = Vote(
        id: '', // Firestore gerará
        submissionId: submissionId,
        challengeId: challengeId,
        voterId: voterId,
        voterUsername: voterUsername,
        type: voteType,
        createdAt: DateTime.now(),
        ipAddress: await _getClientIP(),
        deviceId: await _getDeviceId(),
        metadata: {
          'userAgent': await _getUserAgent(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      await _db.runTransaction((transaction) async {
        if (existingVote != null) {
          // Atualizar voto existente
          final voteRef = _db.collection(_votesCollection).doc(existingVote.id);
          transaction.update(voteRef, vote.toJson());
          AppLogger.debug('🔄 Voto atualizado: ${voteType.emoji}');
        } else {
          // Criar novo voto
          final voteRef = _db.collection(_votesCollection).doc();
          transaction.set(voteRef, {...vote.toJson(), 'id': voteRef.id});
          AppLogger.debug('✅ Novo voto criado: ${voteType.emoji}');
        }

        // Atualizar contadores na submissão
        await _updateSubmissionVoteStats(submissionId, transaction);
      });

      AppLogger.info('🗳️ Votação realizada com sucesso');
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro ao votar: $e');
      return false;
    }
  }

  /// Remover voto de uma submissão
  static Future<bool> removeVote({
    required String submissionId,
    required String voterId,
  }) async {
    try {
      AppLogger.debug('🗑️ Removendo voto: $submissionId');

      final existingVote = await _getUserVoteOnSubmission(
        submissionId: submissionId,
        voterId: voterId,
      );

      if (existingVote == null) {
        AppLogger.warning('⚠️ Voto não encontrado para remoção');
        return false;
      }

      await _db.runTransaction((transaction) async {
        // Remover voto
        final voteRef = _db.collection(_votesCollection).doc(existingVote.id);
        transaction.delete(voteRef);

        // Atualizar contadores na submissão
        await _updateSubmissionVoteStats(submissionId, transaction);
      });

      AppLogger.info('🗑️ Voto removido com sucesso');
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro ao remover voto: $e');
      return false;
    }
  }

  /// Buscar votos de uma submissão
  static Stream<List<Vote>> getSubmissionVotes(String submissionId) {
    return _db
        .collection(_votesCollection)
        .where('submissionId', isEqualTo: submissionId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Vote.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Buscar estatísticas de votação de uma submissão
  static Future<VotingStats> getSubmissionVotingStats(
    String submissionId,
  ) async {
    try {
      final votesSnapshot = await _db
          .collection(_votesCollection)
          .where('submissionId', isEqualTo: submissionId)
          .get();

      final votes = votesSnapshot.docs
          .map((doc) => Vote.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return VotingStats.fromVotes(submissionId, votes);
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar estatísticas: $e');
      return VotingStats.fromVotes(submissionId, []);
    }
  }

  /// Buscar ranking de submissões por votos
  static Stream<List<VotingStats>> getVotingRanking({
    required String challengeId,
    int limit = 20,
  }) {
    return _db
        .collection(_submissionsCollection)
        .where('challengeId', isEqualTo: challengeId)
        .snapshots()
        .asyncMap((snapshot) async {
          final submissions = snapshot.docs;
          final List<VotingStats> stats = [];

          for (final submissionDoc in submissions) {
            final submissionId = submissionDoc.id;
            final votingStats = await getSubmissionVotingStats(submissionId);
            stats.add(votingStats);
          }

          // Ordenar por score e atualizar rankings
          stats.sort((a, b) => b.score.compareTo(a.score));

          final List<VotingStats> rankedStats = [];
          for (int i = 0; i < stats.length; i++) {
            rankedStats.add(
              stats[i].copyWith(ranking: i + 1, isLeading: i == 0),
            );
          }

          return rankedStats.take(limit).toList();
        });
  }

  /// Buscar voto do usuário em uma submissão
  static Future<Vote?> getUserVoteOnSubmission({
    required String submissionId,
    required String voterId,
  }) async {
    return await _getUserVoteOnSubmission(
      submissionId: submissionId,
      voterId: voterId,
    );
  }

  /// Buscar todos os votos do usuário em um desafio
  static Stream<List<Vote>> getUserVotesInChallenge({
    required String challengeId,
    required String voterId,
  }) {
    return _db
        .collection(_votesCollection)
        .where('challengeId', isEqualTo: challengeId)
        .where('voterId', isEqualTo: voterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Vote.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Verificar se usuário pode votar
  static Future<VoteValidation> _canUserVote({
    required String submissionId,
    required String challengeId,
    required String voterId,
    VotingConfig? config,
  }) async {
    try {
      // Validar configuração de votação
      if (config != null && !config.isVotingActive) {
        return VoteValidation(false, 'Período de votação encerrado');
      }

      // Verificar se é auto-voto
      final submission = await _db
          .collection(_submissionsCollection)
          .doc(submissionId)
          .get();

      if (submission.exists) {
        final submissionData = submission.data()!;
        final submissionUserId = submissionData['userId'];

        if (submissionUserId == voterId && (config?.allowSelfVoting == false)) {
          return VoteValidation(
            false,
            'Não é possível votar na própria submissão',
          );
        }
      }

      // Verificar limite de votos por usuário
      if (config != null) {
        final userVotesCount = await _getUserVoteCountInChallenge(
          challengeId: challengeId,
          voterId: voterId,
        );

        if (userVotesCount >= config.maxVotesPerUser) {
          return VoteValidation(false, 'Limite de votos excedido');
        }
      }

      // Verificar anti-manipulação (IP/Device)
      final antiManipulation = await _checkAntiManipulation(
        submissionId: submissionId,
        voterId: voterId,
        config: config,
      );

      if (!antiManipulation.isValid) {
        return antiManipulation;
      }

      return VoteValidation(true, 'Pode votar');
    } catch (e) {
      AppLogger.error('❌ Erro ao validar voto: $e');
      return VoteValidation(false, 'Erro interno');
    }
  }

  /// Buscar voto existente do usuário
  static Future<Vote?> _getUserVoteOnSubmission({
    required String submissionId,
    required String voterId,
  }) async {
    try {
      final querySnapshot = await _db
          .collection(_votesCollection)
          .where('submissionId', isEqualTo: submissionId)
          .where('voterId', isEqualTo: voterId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Vote.fromJson({...doc.data(), 'id': doc.id});
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar voto existente: $e');
      return null;
    }
  }

  /// Contar votos do usuário em um desafio
  static Future<int> _getUserVoteCountInChallenge({
    required String challengeId,
    required String voterId,
  }) async {
    try {
      final querySnapshot = await _db
          .collection(_votesCollection)
          .where('challengeId', isEqualTo: challengeId)
          .where('voterId', isEqualTo: voterId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      AppLogger.error('❌ Erro ao contar votos: $e');
      return 0;
    }
  }

  /// Atualizar estatísticas de voto na submissão
  static Future<void> _updateSubmissionVoteStats(
    String submissionId,
    Transaction transaction,
  ) async {
    try {
      // Este método será chamado dentro da transação
      // para manter consistência dos dados
      final submissionRef = _db
          .collection(_submissionsCollection)
          .doc(submissionId);

      // Buscar votos atuais (fora da transação para leitura)
      final votesSnapshot = await _db
          .collection(_votesCollection)
          .where('submissionId', isEqualTo: submissionId)
          .get();

      final votes = votesSnapshot.docs
          .map((doc) => Vote.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      final stats = VotingStats.fromVotes(submissionId, votes);

      // Atualizar submissão com novas estatísticas
      transaction.update(submissionRef, {
        'votes': stats.totalVotes,
        'score': stats.score,
        'lastVote': Timestamp.fromDate(stats.lastVote),
        'voteCounts': stats.voteCounts.map((k, v) => MapEntry(k.id, v)),
      });
    } catch (e) {
      AppLogger.error('❌ Erro ao atualizar estatísticas: $e');
      rethrow;
    }
  }

  /// Sistema anti-manipulação
  static Future<VoteValidation> _checkAntiManipulation({
    required String submissionId,
    required String voterId,
    VotingConfig? config,
  }) async {
    if (config?.antiManipulation.isEmpty != false) {
      return VoteValidation(true, 'Sem verificação anti-manipulação');
    }

    try {
      final clientIP = await _getClientIP();
      final deviceId = await _getDeviceId();

      // Verificar múltiplos votos do mesmo IP
      if (config!.antiManipulation['checkIP'] == true) {
        final ipVotesSnapshot = await _db
            .collection(_votesCollection)
            .where('submissionId', isEqualTo: submissionId)
            .where('ipAddress', isEqualTo: clientIP)
            .get();

        final maxVotesPerIP = config.antiManipulation['maxVotesPerIP'] ?? 5;
        if (ipVotesSnapshot.docs.length >= maxVotesPerIP) {
          return VoteValidation(false, 'Muitos votos do mesmo IP');
        }
      }

      // Verificar múltiplos votos do mesmo device
      if (config.antiManipulation['checkDevice'] == true) {
        final deviceVotesSnapshot = await _db
            .collection(_votesCollection)
            .where('submissionId', isEqualTo: submissionId)
            .where('deviceId', isEqualTo: deviceId)
            .get();

        final maxVotesPerDevice =
            config.antiManipulation['maxVotesPerDevice'] ?? 3;
        if (deviceVotesSnapshot.docs.length >= maxVotesPerDevice) {
          return VoteValidation(false, 'Muitos votos do mesmo dispositivo');
        }
      }

      return VoteValidation(true, 'Verificação anti-manipulação passou');
    } catch (e) {
      AppLogger.error('❌ Erro na verificação anti-manipulação: $e');
      return VoteValidation(true, 'Erro na verificação, permitindo voto');
    }
  }

  /// Obter IP do cliente (simulado)
  static Future<String?> _getClientIP() async {
    // Em produção, implementar detecção real de IP
    return '127.0.0.1';
  }

  /// Obter ID do dispositivo (simulado)
  static Future<String?> _getDeviceId() async {
    // Em produção, usar device_info_plus ou similar
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Obter User Agent (simulado)
  static Future<String?> _getUserAgent() async {
    // Em produção, implementar detecção real
    return 'ClashUp-Flutter-App/1.0';
  }

  /// Buscar submissões mais votadas globalmente
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

  /// Buscar votos recentes para análise de segurança
  static Future<List<Vote>> getRecentVotes({
    String? submissionId,
    String? challengeId,
    Duration? timeWindow,
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(
        timeWindow ?? const Duration(minutes: 5),
      );

      Query query = _db
          .collection(_votesCollection)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffTime));

      if (submissionId != null) {
        query = query.where('submissionId', isEqualTo: submissionId);
      }

      if (challengeId != null) {
        query = query.where('challengeId', isEqualTo: challengeId);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map(
            (doc) => Vote.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar votos recentes: $e');
      return [];
    }
  }

  /// Buscar estatísticas agregadas de votação
  static Future<Map<String, dynamic>> getAggregatedVotingStats(
    String challengeId,
  ) async {
    try {
      final votesSnapshot = await _db
          .collection(_votesCollection)
          .where('challengeId', isEqualTo: challengeId)
          .get();

      final submissionsSnapshot = await _db
          .collection(_submissionsCollection)
          .where('challengeId', isEqualTo: challengeId)
          .get();

      final totalVotes = votesSnapshot.docs.length;
      final totalSubmissions = submissionsSnapshot.docs.length;
      final uniqueVoters = votesSnapshot.docs
          .map((doc) => doc.data()['voterId'])
          .toSet()
          .length;

      // Calcular distribuição por tipo de voto
      final voteTypeDistribution = <String, int>{};
      for (final doc in votesSnapshot.docs) {
        final voteType = doc.data()['type'] as String;
        voteTypeDistribution[voteType] =
            (voteTypeDistribution[voteType] ?? 0) + 1;
      }

      return {
        'totalVotes': totalVotes,
        'totalSubmissions': totalSubmissions,
        'uniqueVoters': uniqueVoters,
        'avgVotesPerSubmission': totalSubmissions > 0
            ? totalVotes / totalSubmissions
            : 0,
        'participationRate': totalSubmissions > 0
            ? (uniqueVoters / totalSubmissions) * 100
            : 0,
        'voteTypeDistribution': voteTypeDistribution,
      };
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar estatísticas agregadas: $e');
      return {};
    }
  }

  /// Verificar se usuário já votou em uma submissão (método auxiliar)
  static Future<bool> hasUserVotedOnSubmission(
    String submissionId,
    String userId,
  ) async {
    try {
      final vote = await _getUserVoteOnSubmission(
        submissionId: submissionId,
        voterId: userId,
      );
      return vote != null;
    } catch (e) {
      AppLogger.error('❌ Erro ao verificar se usuário votou: $e');
      return false;
    }
  }

  /// Contar total de votos de um usuário em um desafio
  static Future<int> getUserVoteCountInChallenge(
    String challengeId,
    String userId,
  ) async {
    return await _getUserVoteCountInChallenge(
      challengeId: challengeId,
      voterId: userId,
    );
  }

  /// Limpar votos órfãos (maintenance method)
  static Future<void> cleanupOrphanedVotes() async {
    try {
      AppLogger.info('🧹 Iniciando limpeza de votos órfãos');

      // Buscar votos sem submissão correspondente
      final votesSnapshot = await _db.collection(_votesCollection).get();
      final orphanedVotes = <String>[];

      for (final voteDoc in votesSnapshot.docs) {
        final submissionId = voteDoc.data()['submissionId'] as String;

        final submissionDoc = await _db
            .collection(_submissionsCollection)
            .doc(submissionId)
            .get();

        if (!submissionDoc.exists) {
          orphanedVotes.add(voteDoc.id);
        }
      }

      // Remover votos órfãos
      final batch = _db.batch();
      for (final voteId in orphanedVotes) {
        batch.delete(_db.collection(_votesCollection).doc(voteId));
      }

      await batch.commit();
      AppLogger.info('🧹 Removidos ${orphanedVotes.length} votos órfãos');
    } catch (e) {
      AppLogger.error('❌ Erro na limpeza de votos órfãos: $e');
    }
  }
}

/// Resultado da validação de voto
class VoteValidation {
  final bool isValid;
  final String reason;

  const VoteValidation(this.isValid, this.reason);
}
