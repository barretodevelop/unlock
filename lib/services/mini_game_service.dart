// lib/services/mini_game_service.dart
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/mini_game_model.dart';
// ✅ CORRIGIDO: Usar analytics helper se AnalyticsIntegration não existir
import 'package:unlock/services/analytics/analytics_helper.dart';

class MiniGameService {
  static final _db = FirebaseFirestore.instance;
  static const _gameResultsCollection = 'game_results';
  static const _gameStatsCollection = 'game_stats';

  // ========== SALVAR RESULTADOS ==========

  /// Salvar resultado de jogo
  static Future<bool> saveGameResult(GameResult result) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.info('🎮 Salvando resultado do jogo', data: {
        'gameType': result.type.name,
        'userId': result.userId,
        'score': result.finalScore,
        'difficulty': result.difficulty.label,
      });

      // Salvar resultado individual
      await _db.collection(_gameResultsCollection).add(result.toJson());

      // Atualizar estatísticas do usuário
      await _updateUserGameStats(result);

      // Verificar e atualizar personal best
      await _checkAndUpdatePersonalBest(result);

      stopwatch.stop();

      // 📊 Analytics
      await _trackGameEvent('game_completed', {
        'game_type': result.type.id,
        'difficulty': result.difficulty.id,
        'score': result.finalScore,
        'rank': result.rank,
        'duration_seconds': result.duration.inSeconds,
        'is_personal_best': result.isPersonalBest,
      });

      AppLogger.info('✅ Resultado salvo com sucesso', data: {
        'duration': '${stopwatch.elapsedMilliseconds}ms',
      });

      return true;
    } catch (e) {
      stopwatch.stop();

      AppLogger.error('❌ Erro ao salvar resultado', error: e);
      
      // 📊 Analytics - Erro
      await _trackGameEvent('game_save_error', {
        'game_type': result.type.id,
        'error': e.toString(),
        'duration_ms': stopwatch.elapsedMilliseconds,
      });

      return false;
    }
  }

  /// Atualizar estatísticas do usuário
  static Future<void> _updateUserGameStats(GameResult result) async {
    final userStatsRef = _db
        .collection(_gameStatsCollection)
        .doc(result.userId);

    await _db.runTransaction((transaction) async {
      final userStatsDoc = await transaction.get(userStatsRef);
      
      Map<String, dynamic> stats;
      if (userStatsDoc.exists) {
        stats = Map<String, dynamic>.from(userStatsDoc.data()!);
      } else {
        stats = _createInitialUserStats(result.userId);
      }

      // Atualizar estatísticas gerais
      stats['totalGames'] = (stats['totalGames'] ?? 0) + 1;
      stats['totalScore'] += result.finalScore;
      stats['lastPlayedAt'] = Timestamp.fromDate(result.completedAt);

      // Atualizar estatísticas por jogo
      final gameKey = result.type.id;
      final gameStats = Map<String, dynamic>.from(stats['games']?[gameKey] ?? {});
      
      gameStats['gamesPlayed'] = (gameStats['gamesPlayed'] ?? 0) + 1;
      gameStats['totalScore'] = (gameStats['totalScore'] ?? 0) + result.finalScore;
      gameStats['bestScore'] = math.max(
        gameStats['bestScore'] ?? 0,
        result.finalScore,
      );
      gameStats['lastPlayedAt'] = Timestamp.fromDate(result.completedAt);

      // Atualizar por dificuldade
      final diffKey = result.difficulty.id;
      final diffStats = Map<String, dynamic>.from(gameStats['difficulties']?[diffKey] ?? {});
      
      diffStats['gamesPlayed'] = (diffStats['gamesPlayed'] ?? 0) + 1;
      diffStats['bestScore'] = math.max(
        diffStats['bestScore'] ?? 0,
        result.finalScore,
      );

      gameStats['difficulties'] ??= {};
      gameStats['difficulties'][diffKey] = diffStats;

      stats['games'] ??= {};
      stats['games'][gameKey] = gameStats;

      transaction.set(userStatsRef, stats, SetOptions(merge: true));
    });
  }

  /// Verificar e atualizar personal best
  static Future<void> _checkAndUpdatePersonalBest(GameResult result) async {
    final personalBest = await getPersonalBest(
      result.userId,
      result.type,
      result.difficulty,
    );

    if (personalBest == null || result.finalScore > personalBest.finalScore) {
      // É um novo personal best!
      final bestRef = _db
          .collection(_gameResultsCollection)
          .doc('${result.userId}_${result.type.id}_${result.difficulty.id}_best');

      await bestRef.set(result.copyWith(isPersonalBest: true).toJson());

      AppLogger.info('🏆 Novo personal best!', data: {
        'gameType': result.type.name,
        'difficulty': result.difficulty.label,
        'score': result.finalScore,
        'previousBest': personalBest?.finalScore ?? 0,
      });

      // 📊 Analytics - Personal Best
      await _trackGameEvent('personal_best', {
        'game_type': result.type.id,
        'difficulty': result.difficulty.id,
        'new_score': result.finalScore,
        'previous_score': personalBest?.finalScore ?? 0,
      });
    }
  }

  /// Criar estatísticas iniciais do usuário
  static Map<String, dynamic> _createInitialUserStats(String userId) {
    return {
      'userId': userId,
      'totalGames': 0,
      'totalScore': 0,
      'createdAt': Timestamp.now(),
      'lastPlayedAt': Timestamp.now(),
      'games': {},
    };
  }

  // ========== BUSCAR DADOS ==========

  /// Buscar personal best do usuário
  static Future<GameResult?> getPersonalBest(
    String userId,
    GameType gameType,
    GameDifficulty difficulty,
  ) async {
    try {
      AppLogger.debug('🔍 Buscando personal best', data: {
        'userId': userId,
        'gameType': gameType.name,
        'difficulty': difficulty.label,
      });

      final bestDoc = await _db
          .collection(_gameResultsCollection)
          .doc('${userId}_${gameType.id}_${difficulty.id}_best')
          .get();

      if (bestDoc.exists) {
        final result = GameResult.fromJson(bestDoc.data()!);
        AppLogger.debug('✅ Personal best encontrado: ${result.finalScore}');
        return result;
      }

      AppLogger.debug('📭 Nenhum personal best encontrado');
      return null;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar personal best', error: e);
      return null;
    }
  }

  /// Buscar histórico de jogos do usuário
  static Stream<List<GameResult>> getUserGameHistory(String userId) {
    AppLogger.debug('🔄 Stream: Histórico de jogos para $userId');

    return _db
        .collection(_gameResultsCollection)
        .where('userId', isEqualTo: userId)
        .where('isPersonalBest', isEqualTo: false) // Excluir personal bests duplicados
        .orderBy('completedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return GameResult.fromJson({...doc.data(), 'id': doc.id});
          }).toList();
        })
        .handleError((error) {
          AppLogger.error('❌ Erro no stream de histórico', error: error);
          return <GameResult>[];
        });
  }

  /// Buscar leaderboard global de um jogo
  static Stream<List<GameResult>> getLeaderboard(
    GameType gameType, {
    GameDifficulty? difficulty,
    int limit = 50,
  }) {
    AppLogger.debug('🔄 Stream: Leaderboard de ${gameType.name}');

    Query query = _db
        .collection(_gameResultsCollection)
        .where('type', isEqualTo: gameType.id)
        .where('isPersonalBest', isEqualTo: true);

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.id);
    }

    return query
        .orderBy('finalScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            final data = doc.data() as Map<String, dynamic>;
            
            return GameResult.fromJson({
              ...data,
              'id': doc.id,
              'position': index + 1, // Adicionar posição no ranking
            });
          }).toList();
        })
        .handleError((error) {
          AppLogger.error('❌ Erro no stream de leaderboard', error: error);
          return <GameResult>[];
        });
  }

  /// Buscar posição do usuário no ranking
  static Future<int?> getUserPosition(
    String userId,
    GameType gameType,
    GameDifficulty difficulty,
  ) async {
    try {
      AppLogger.debug('🔍 Buscando posição no ranking', data: {
        'userId': userId,
        'gameType': gameType.name,
        'difficulty': difficulty.label,
      });

      // Buscar score do usuário
      final userBest = await getPersonalBest(userId, gameType, difficulty);
      if (userBest == null) {
        AppLogger.debug('📭 Usuário sem score registrado');
        return null;
      }

      // Contar quantos users têm score maior
      final higherScoresQuery = await _db
          .collection(_gameResultsCollection)
          .where('type', isEqualTo: gameType.id)
          .where('difficulty', isEqualTo: difficulty.id)
          .where('isPersonalBest', isEqualTo: true)
          .where('finalScore', isGreaterThan: userBest.finalScore)
          .get();

      final position = higherScoresQuery.docs.length + 1;
      
      AppLogger.debug('✅ Posição encontrada: $position');
      return position;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar posição', error: e);
      return null;
    }
  }

  /// Buscar estatísticas do usuário
  static Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      AppLogger.debug('🔍 Buscando estatísticas do usuário: $userId');

      final statsDoc = await _db
          .collection(_gameStatsCollection)
          .doc(userId)
          .get();

      if (statsDoc.exists) {
        final stats = statsDoc.data()!;
        AppLogger.debug('✅ Estatísticas encontradas');
        return stats;
      }

      AppLogger.debug('📭 Nenhuma estatística encontrada');
      return null;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar estatísticas', error: e);
      return null;
    }
  }

  // ========== ANALYTICS ==========

  /// Track eventos de jogo
  static Future<void> _trackGameEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      // ✅ CORRIGIDO: Usar helper de analytics
      await AnalyticsHelper.logEvent(eventName, parameters);
    } catch (e) {
      AppLogger.warning('⚠️ Erro ao enviar analytics de jogo', data: {
        'event': eventName,
        'error': e.toString(),
      });
    }
  }

  // ========== UTILIDADES ==========

  /// Limpar dados de teste (apenas desenvolvimento)
  static Future<void> clearTestData(String userId) async {
    try {
      if (!userId.contains('test_')) {
        throw Exception('Método apenas para dados de teste');
      }

      AppLogger.warning('🧹 Limpando dados de teste para: $userId');

      // Limpar resultados
      final results = await _db
          .collection(_gameResultsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in results.docs) {
        await doc.reference.delete();
      }

      // Limpar estatísticas
      await _db.collection(_gameStatsCollection).doc(userId).delete();

      AppLogger.info('✅ Dados de teste limpos');
    } catch (e) {
      AppLogger.error('❌ Erro ao limpar dados de teste', error: e);
      rethrow;
    }
  }

  /// Verificar integridade dos dados
  static Future<Map<String, dynamic>> checkDataIntegrity(String userId) async {
    try {
      final stats = await getUserStats(userId);
      final results = await _db
          .collection(_gameResultsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final integrity = {
        'hasStats': stats != null,
        'totalResults': results.docs.length,
        'gamesInStats': stats?['totalGames'] ?? 0,
        'isConsistent': (stats?['totalGames'] ?? 0) <= results.docs.length,
      };

      AppLogger.debug('🔍 Integridade dos dados', data: integrity);
      return integrity;
    } catch (e) {
      AppLogger.error('❌ Erro ao verificar integridade', error: e);
      return {'error': e.toString()};
    }
  }
}