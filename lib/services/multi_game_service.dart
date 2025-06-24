// lib/services/multi_game_service.dart
// Extensão do GameService para suportar múltiplos jogos simultâneos

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/models/message_model.dart';
import 'package:unlock/services/game_service.dart';

/// Extensão do GameService para suporte a múltiplos jogos simultâneos
class MultiGameService extends GameService {
  static const int maxActiveGames = 3;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Verifica se o usuário pode criar um novo jogo
  Future<bool> canCreateNewGame(String userId) async {
    try {
      final activeGamesCount = await getActiveGamesCount(userId);
      final canCreate = activeGamesCount < maxActiveGames;
      
      AppLogger.info('🎮 Verificação de criação de jogo', data: {
        'userId': userId,
        'activeGames': activeGamesCount,
        'maxGames': maxActiveGames,
        'canCreate': canCreate,
      });

      return canCreate;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao verificar se pode criar jogo', 
        error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Retorna o número de jogos ativos do usuário
  Future<int> getActiveGamesCount(String userId) async {
    try {
      final snapshot = await _db
          .collection(FirestoreCollections.game_rooms)
          .where('playerIds', arrayContains: userId)
          .where('status', whereIn: [
            GameStatus.pending.name,
            GameStatus.active.name,
          ])
          .get();

      return snapshot.docs.length;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao contar jogos ativos', 
        error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Stream de todos os jogos ativos do usuário
  Stream<List<GameRoomModel>> getActiveGamesStream(String userId) {
    return _db
        .collection(FirestoreCollections.game_rooms)
        .where('playerIds', arrayContains: userId)
        .where('status', whereIn: [
          GameStatus.pending.name,
          GameStatus.active.name,
        ])
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <GameRoomModel>[];
      }
      
      return snapshot.docs
          .map((doc) => GameRoomModel.fromJson(doc.id, doc.data()))
          .toList();
    }).handleError((error, stackTrace) {
      AppLogger.error('❌ Erro no stream de jogos ativos', 
        error: error, stackTrace: stackTrace);
      return <GameRoomModel>[];
    });
  }

  /// Busca jogos com base no status e tipo
  Future<List<GameRoomModel>> getGamesByStatus(
    String userId, 
    List<GameStatus> statuses,
  ) async {
    try {
      final statusNames = statuses.map((s) => s.name).toList();
      
      final snapshot = await _db
          .collection(FirestoreCollections.game_rooms)
          .where('playerIds', arrayContains: userId)
          .where('status', whereIn: statusNames)
          .orderBy('updatedAt', descending: true)
          .limit(20) // Limite para performance
          .get();

      return snapshot.docs
          .map((doc) => GameRoomModel.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao buscar jogos por status', 
        error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Cria convite verificando limite de jogos
  @override
  Future<String?> sendGameInvite({
    required String inviterId,
    required String inviteeId,
  }) async {
    try {
      // Verifica se o convidante pode criar novo jogo
      if (!await canCreateNewGame(inviterId)) {
        AppLogger.warning('🚫 Usuário $inviterId atingiu limite de jogos ativos');
        throw GameLimitException('Você já tem o número máximo de jogos ativos ($maxActiveGames)');
      }

      // Verifica se o convidado pode aceitar novo jogo
      if (!await canCreateNewGame(inviteeId)) {
        AppLogger.warning('🚫 Usuário $inviteeId atingiu limite de jogos ativos');
        throw GameLimitException('Este usuário já tem muitos jogos ativos');
      }

      // Verifica se já existe um jogo entre estes usuários
      final existingGameId = await findGameRoomByPlayers(inviterId, inviteeId);
      if (existingGameId != null) {
        AppLogger.warning('⚠️ Jogo já existe entre usuários', data: {
          'gameId': existingGameId,
          'inviter': inviterId,
          'invitee': inviteeId,
        });
        throw GameAlreadyExistsException('Já existe um jogo entre vocês');
      }

      // Cria o jogo usando o método pai
      final gameId = await super.sendGameInvite(
        inviterId: inviterId,
        inviteeId: inviteeId,
      );

      if (gameId != null) {
        AppLogger.info('✅ Novo jogo criado no sistema multi-game', data: {
          'gameId': gameId,
          'inviter': inviterId,
          'invitee': inviteeId,
        });
      }

      return gameId;
    } catch (e, stackTrace) {
      if (e is GameLimitException || e is GameAlreadyExistsException) {
        rethrow;
      }
      
      AppLogger.error('❌ Erro ao criar convite multi-game', 
        error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Busca jogo por players considerando status ativos
  @override
  Future<String?> findGameRoomByPlayers(String uid1, String uid2) async {
    try {
      // Primeiro, busca jogos ativos entre os usuários
      final activeQuery = await _db
          .collection(FirestoreCollections.game_rooms)
          .where('playerIds', whereIn: [
            [uid1, uid2],
            [uid2, uid1],
          ])
          .where('status', whereIn: [
            GameStatus.pending.name,
            GameStatus.active.name,
          ])
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (activeQuery.docs.isNotEmpty) {
        return activeQuery.docs.first.id;
      }

      // Se não há jogos ativos, busca o mais recente (qualquer status)
      final recentQuery = await _db
          .collection(FirestoreCollections.game_rooms)
          .where('playerIds', whereIn: [
            [uid1, uid2],
            [uid2, uid1],
          ])
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (recentQuery.docs.isNotEmpty) {
        return recentQuery.docs.first.id;
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao buscar jogo por players', 
        error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Atualiza prioridade do jogo (último acessado fica no topo)
  Future<void> updateGamePriority(String gameRoomId, String userId) async {
    try {
      await _db
          .collection(FirestoreCollections.game_rooms)
          .doc(gameRoomId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastAccessedBy': userId,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.debug('📌 Prioridade do jogo atualizada', data: {
        'gameId': gameRoomId,
        'userId': userId,
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao atualizar prioridade do jogo', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Arquiva um jogo (remove da lista ativa sem deletar)
  Future<void> archiveGame(String gameRoomId) async {
    try {
      await _db
          .collection(FirestoreCollections.game_rooms)
          .doc(gameRoomId)
          .update({
        'status': GameStatus.archived.name,
        'archivedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('📁 Jogo arquivado', data: {'gameId': gameRoomId});
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao arquivar jogo', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Reativa um jogo arquivado
  Future<void> unarchiveGame(String gameRoomId) async {
    try {
      await _db
          .collection(FirestoreCollections.game_rooms)
          .doc(gameRoomId)
          .update({
        'status': GameStatus.active.name,
        'archivedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('📤 Jogo reativado', data: {'gameId': gameRoomId});
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao reativar jogo', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Finaliza um jogo e atualiza estatísticas
  Future<void> finishGame(
    String gameRoomId, {
    GameStatus finalStatus = GameStatus.completed,
  }) async {
    try {
      await _db
          .collection(FirestoreCollections.game_rooms)
          .doc(gameRoomId)
          .update({
        'status': finalStatus.name,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('🏁 Jogo finalizado', data: {
        'gameId': gameRoomId,
        'status': finalStatus.name,
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao finalizar jogo', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Busca estatísticas de jogos do usuário
  Future<MultiGameStats> getUserGameStats(String userId) async {
    try {
      // Jogos por status
      final allGamesQuery = await _db
          .collection(FirestoreCollections.game_rooms)
          .where('playerIds', arrayContains: userId)
          .get();

      final games = allGamesQuery.docs
          .map((doc) => GameRoomModel.fromJson(doc.id, doc.data()))
          .toList();

      final stats = MultiGameStats.fromGames(games, userId);
      
      AppLogger.debug('📊 Estatísticas calculadas', data: stats.toJson());
      
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao buscar estatísticas', 
        error: e, stackTrace: stackTrace);
      return MultiGameStats.empty();
    }
  }

  /// Limpa jogos antigos (manutenção)
  Future<void> cleanupOldGames({
    int daysOld = 30,
    List<GameStatus> statusesToClean = const [
      GameStatus.declined,
      GameStatus.abandoned,
      GameStatus.completed,
    ],
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final statusNames = statusesToClean.map((s) => s.name).toList();

      final oldGamesQuery = await _db
          .collection(FirestoreCollections.game_rooms)
          .where('status', whereIn: statusNames)
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(100) // Processa em lotes
          .get();

      final batch = _db.batch();
      for (final doc in oldGamesQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      AppLogger.info('🧹 Limpeza de jogos antigos concluída', data: {
        'deletedCount': oldGamesQuery.docs.length,
        'cutoffDate': cutoffDate.toIso8601String(),
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro na limpeza de jogos', 
        error: e, stackTrace: stackTrace);
    }
  }
}

/// Extensões para status de jogos
extension GameStatusExtension on GameStatus {
  static GameStatus archived = GameStatus.values.length > 5 
      ? GameStatus.values[5] 
      : GameStatus.completed; // Fallback se não existir

  bool get isActive => this == GameStatus.pending || this == GameStatus.active;
  bool get isFinished => this == GameStatus.completed || 
                        this == GameStatus.declined || 
                        this == GameStatus.abandoned;
}

/// Estatísticas de múltiplos jogos
class MultiGameStats {
  final int totalGames;
  final int activeGames;
  final int pendingGames;
  final int completedGames;
  final int abandonedGames;
  final int declinedGames;
  final double completionRate;
  final double acceptanceRate;
  final DateTime? lastGameDate;
  final int gamesThisWeek;
  final int gamesThisMonth;

  const MultiGameStats({
    this.totalGames = 0,
    this.activeGames = 0,
    this.pendingGames = 0,
    this.completedGames = 0,
    this.abandonedGames = 0,
    this.declinedGames = 0,
    this.completionRate = 0.0,
    this.acceptanceRate = 0.0,
    this.lastGameDate,
    this.gamesThisWeek = 0,
    this.gamesThisMonth = 0,
  });

  factory MultiGameStats.fromGames(List<GameRoomModel> games, String userId) {
    if (games.isEmpty) return MultiGameStats.empty();

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    var active = 0, pending = 0, completed = 0, abandoned = 0, declined = 0;
    var gamesThisWeek = 0, gamesThisMonth = 0;
    DateTime? lastGame;

    for (final game in games) {
      switch (GameStatus.values.firstWhere((s) => s.name == game.status)) {
        case GameStatus.active:
          active++;
          break;
        case GameStatus.pending:
          pending++;
          break;
        case GameStatus.completed:
          completed++;
          break;
        case GameStatus.abandoned:
          abandoned++;
          break;
        case GameStatus.declined:
          declined++;
          break;
      }

      // Conta jogos recentes
      if (game.updatedAt.isAfter(weekAgo)) gamesThisWeek++;
      if (game.updatedAt.isAfter(monthAgo)) gamesThisMonth++;

      // Última data de jogo
      if (lastGame == null || game.updatedAt.isAfter(lastGame)) {
        lastGame = game.updatedAt;
      }
    }

    final totalGames = games.length;
    final finishedGames = completed + abandoned + declined;
    final completionRate = finishedGames > 0 ? (completed / finishedGames) : 0.0;
    final acceptanceRate = (pending + declined) > 0 
        ? (pending / (pending + declined)) 
        : 0.0;

    return MultiGameStats(
      totalGames: totalGames,
      activeGames: active,
      pendingGames: pending,
      completedGames: completed,
      abandonedGames: abandoned,
      declinedGames: declined,
      completionRate: completionRate,
      acceptanceRate: acceptanceRate,
      lastGameDate: lastGame,
      gamesThisWeek: gamesThisWeek,
      gamesThisMonth: gamesThisMonth,
    );
  }

  factory MultiGameStats.empty() => const MultiGameStats();

  Map<String, dynamic> toJson() {
    return {
      'totalGames': totalGames,
      'activeGames': activeGames,
      'pendingGames': pendingGames,
      'completedGames': completedGames,
      'abandonedGames': abandonedGames,
      'declinedGames': declinedGames,
      'completionRate': completionRate,
      'acceptanceRate': acceptanceRate,
      'lastGameDate': lastGameDate?.toIso8601String(),
      'gamesThisWeek': gamesThisWeek,
      'gamesThisMonth': gamesThisMonth,
    };
  }
}

/// Exceções específicas para múltiplos jogos
class GameLimitException implements Exception {
  final String message;
  GameLimitException(this.message);
  
  @override
  String toString() => 'GameLimitException: $message';
}

class GameAlreadyExistsException implements Exception {
  final String message;
  GameAlreadyExistsException(this.message);
  
  @override
  String toString() => 'GameAlreadyExistsException: $message';
}