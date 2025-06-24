// lib/features/rankings/services/ranking_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/ranking_model.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

/// Serviço para gerenciar rankings e classificações
class RankingService {
  static final _db = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';
  static const String _rankingsCollection = 'rankings';
  static const String _rankingStatsCollection = 'ranking_stats';

  // ========== BUSCA DE RANKINGS ==========

  /// Buscar rankings baseado na query
  static Stream<List<RankingEntry>> getRankings(RankingQuery query) {
    AppLogger.info(
      '🏅 Buscando rankings',
      data: {
        'category': query.category.id,
        'scope': query.scope.id,
        'period': query.period.id,
        'limit': query.limit,
      },
    );

    try {
      switch (query.scope) {
        case RankingScopeType.global:
          return _getGlobalRankings(query);
        case RankingScopeType.groups:
          return _getGroupRankings(query);
        case RankingScopeType.friends:
          return _getFriendsRankings(query);
        case RankingScopeType.weekly:
          return _getWeeklyRankings(query);
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar rankings: $e');
      return Stream.error(e);
    }
  }

  /// Rankings globais
  static Stream<List<RankingEntry>> _getGlobalRankings(RankingQuery query) {
    Query<Map<String, dynamic>> baseQuery = _db
        .collection(_usersCollection)
        .where('onboardingCompleted', isEqualTo: true);

    // Aplicar filtros de período se necessário
    if (query.period != RankingPeriod.allTime) {
      final startDate = query.period.getStartDate();
      baseQuery = baseQuery.where(
        'lastActivity',
        isGreaterThanOrEqualTo: startDate,
      );
    }

    // Ordenar por categoria e limitar
    baseQuery = _addCategoryOrderAndLimit(baseQuery, query);

    return baseQuery.snapshots().map((snapshot) {
      return _processRankingSnapshot(snapshot, query.category);
    });
  }

  /// Rankings de grupos
  static Stream<List<RankingEntry>> _getGroupRankings(RankingQuery query) {
    // TODO: Implementar quando tiver sistema de amizades/grupos
    // Por ora, retorna ranking global
    AppLogger.warning('🏅 Group rankings não implementado, usando global');
    return _getGlobalRankings(query);
  }

  /// Rankings de amigos
  static Stream<List<RankingEntry>> _getFriendsRankings(RankingQuery query) {
    // TODO: Implementar quando tiver sistema de amizades
    // Por ora, retorna lista vazia
    AppLogger.warning('🏅 Friends rankings não implementado');
    return Stream.value([]);
  }

  /// Rankings semanais
  static Stream<List<RankingEntry>> _getWeeklyRankings(RankingQuery query) {
    final weekStart = DateTime.now().subtract(Duration(days: 7));

    return _db
        .collection(_usersCollection)
        .where('onboardingCompleted', isEqualTo: true)
        .where('lastActivity', isGreaterThanOrEqualTo: weekStart)
        .orderBy('lastActivity', descending: true)
        .limit(query.limit)
        .snapshots()
        .map((snapshot) {
          return _processRankingSnapshot(snapshot, query.category);
        });
  }

  /// Adicionar ordenação por categoria e limite
  static Query<Map<String, dynamic>> _addCategoryOrderAndLimit(
    Query<Map<String, dynamic>> query,
    RankingQuery rankingQuery,
  ) {
    final category = rankingQuery.category;

    switch (category) {
      case RankingCategory.xp:
        return query.orderBy('xp', descending: true).limit(rankingQuery.limit);
      case RankingCategory.coins:
        return query
            .orderBy('coins', descending: true)
            .limit(rankingQuery.limit);
      case RankingCategory.gems:
        return query
            .orderBy('gems', descending: true)
            .limit(rankingQuery.limit);
      case RankingCategory.level:
        return query
            .orderBy('level', descending: true)
            .limit(rankingQuery.limit);
      case RankingCategory.streak:
        return query
            .orderBy('loginStreak', descending: true)
            .limit(rankingQuery.limit);
      case RankingCategory.challenges:
      case RankingCategory.groups:
      case RankingCategory.submissions:
        // Para stats complexas, ordenar por createdAt e filtrar depois
        return query
            .orderBy('createdAt', descending: true)
            .limit(rankingQuery.limit * 2);
    }
  }

  /// Processar snapshot do Firestore em lista de rankings
  static List<RankingEntry> _processRankingSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    RankingCategory category,
  ) {
    final entries = snapshot.docs.map((doc) {
      final data = doc.data();
      return RankingEntry.fromFirestore(data, category, 0);
    }).toList();

    // Ordenar por valor da categoria (necessário para stats complexas)
    entries.sort((a, b) => b.value.compareTo(a.value));

    // Atribuir posições
    for (int i = 0; i < entries.length; i++) {
      entries[i] = entries[i].copyWith(position: i + 1);
    }

    AppLogger.debug('🏅 Rankings processados: ${entries.length} entradas');
    return entries;
  }

  // ========== BUSCA DE POSIÇÃO ESPECÍFICA ==========

  /// Obter posição específica do usuário
  static Future<int?> getUserPosition(String userId, RankingQuery query) async {
    try {
      AppLogger.debug('🏅 Buscando posição do usuário: $userId');

      // Buscar dados do usuário
      final userDoc = await _db.collection(_usersCollection).doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final userValue = query.category.getValueFromUser(userData);

      // Contar quantos usuários têm valor maior
      Query<Map<String, dynamic>> countQuery = _db
          .collection(_usersCollection)
          .where('onboardingCompleted', isEqualTo: true);

      // Aplicar filtro baseado na categoria
      countQuery = _addValueFilter(countQuery, query.category, userValue);

      final countSnapshot = await countQuery.count().get();
      final position = countSnapshot.count! + 1;

      AppLogger.debug('🏅 Posição do usuário $userId: $position');

      // Track analytics
      await _trackRankingEvent('user_position_checked', {
        'user_id': userId,
        'category': query.category.id,
        'position': position,
        'value': userValue,
      });

      return position;
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar posição do usuário: $e');
      return null;
    }
  }

  /// Adicionar filtro de valor para contar posições
  static Query<Map<String, dynamic>> _addValueFilter(
    Query<Map<String, dynamic>> query,
    RankingCategory category,
    int userValue,
  ) {
    switch (category) {
      case RankingCategory.xp:
        return query.where('xp', isGreaterThan: userValue);
      case RankingCategory.coins:
        return query.where('coins', isGreaterThan: userValue);
      case RankingCategory.gems:
        return query.where('gems', isGreaterThan: userValue);
      case RankingCategory.level:
        return query.where('level', isGreaterThan: userValue);
      case RankingCategory.streak:
        return query.where('loginStreak', isGreaterThan: userValue);
      case RankingCategory.challenges:
      case RankingCategory.groups:
      case RankingCategory.submissions:
        // Para stats complexas, buscar todos e contar depois
        return query;
    }
  }

  // ========== ESTATÍSTICAS DE RANKING ==========

  /// Obter estatísticas completas de ranking do usuário
  static Future<UserRankingStats?> getUserRankingStats(String userId) async {
    try {
      AppLogger.debug('🏅 Buscando stats de ranking: $userId');

      final doc = await _db
          .collection(_rankingStatsCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        // Gerar stats se não existir
        return await _generateUserRankingStats(userId);
      }

      return UserRankingStats.fromJson(doc.data()!);
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar ranking stats: $e');
      return null;
    }
  }

  /// Gerar estatísticas de ranking para o usuário
  static Future<UserRankingStats?> _generateUserRankingStats(
    String userId,
  ) async {
    try {
      AppLogger.debug('🏅 Gerando ranking stats para: $userId');

      final stats = <RankingCategory, int>{};

      // Calcular posição para cada categoria
      for (final category in RankingCategory.values) {
        final query = RankingQuery(
          category: category,
          scope: RankingScopeType.global,
          period: RankingPeriod.allTime,
        );

        final position = await getUserPosition(userId, query);
        if (position != null) {
          stats[category] = position;
        }
      }

      final userStats = UserRankingStats(
        userId: userId,
        globalRanks: stats,
        groupRanks: {}, // TODO: Implementar
        friendRanks: {}, // TODO: Implementar
        weeklyRanks: {}, // TODO: Implementar
        lastUpdated: DateTime.now(),
      );

      // Salvar no Firestore
      await _db
          .collection(_rankingStatsCollection)
          .doc(userId)
          .set(userStats.toJson());

      return userStats;
    } catch (e) {
      AppLogger.error('❌ Erro ao gerar ranking stats: $e');
      return null;
    }
  }

  // ========== ATUALIZAÇÃO DE RANKINGS ==========

  /// Atualizar ranking do usuário quando dados mudam
  static Future<void> updateUserRanking(String userId) async {
    try {
      AppLogger.debug('🏅 Atualizando ranking do usuário: $userId');

      // Invalidar cache de stats
      await _db.collection(_rankingStatsCollection).doc(userId).delete();

      // Gerar novas stats
      await _generateUserRankingStats(userId);

      AppLogger.info('✅ Ranking atualizado para usuário: $userId');
    } catch (e) {
      AppLogger.error('❌ Erro ao atualizar ranking: $e');
    }
  }

  /// Recalcular todos os rankings (operação administrativa)
  static Future<void> recalculateAllRankings() async {
    try {
      AppLogger.info('🏅 Recalculando todos os rankings');

      // Limpar cache de rankings
      final batch = _db.batch();
      final statsCollection = _db.collection(_rankingStatsCollection);

      final snapshot = await statsCollection.get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      AppLogger.info('✅ Cache de rankings limpo');

      // Track analytics
      await _trackRankingEvent('rankings_recalculated', {
        'total_users': snapshot.docs.length,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('❌ Erro ao recalcular rankings: $e');
    }
  }

  // ========== UTILITÁRIOS ==========

  /// Obter resumo dos rankings
  static Future<Map<String, dynamic>> getRankingSummary() async {
    try {
      final usersCount = await _db
          .collection(_usersCollection)
          .where('onboardingCompleted', isEqualTo: true)
          .count()
          .get();

      return {
        'total_users': usersCount.count,
        'last_updated': DateTime.now().toIso8601String(),
        'categories': RankingCategory.values.length,
        'scopes': RankingScopeType.values.length,
      };
    } catch (e) {
      AppLogger.error('❌ Erro ao obter resumo de rankings: $e');
      return {};
    }
  }

  /// Verificar se usuário pode aparecer nos rankings
  static Future<bool> isUserRankingEligible(String userId) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      return data['onboardingCompleted'] == true;
    } catch (e) {
      AppLogger.error('❌ Erro ao verificar elegibilidade: $e');
      return false;
    }
  }

  // ========== ANALYTICS ==========

  /// Track eventos de ranking
  static Future<void> _trackRankingEvent(
    String eventName,
    Map<String, dynamic> data,
  ) async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          'ranking_$eventName',
          parameters: data,
          category: EventCategory.user,
        );
      }
    } catch (e) {
      AppLogger.debug('Erro ao enviar analytics de ranking: $e');
    }
  }

  /// Track visualização de ranking
  static Future<void> trackRankingView(RankingQuery query) async {
    await _trackRankingEvent('view', {
      'category': query.category.id,
      'scope': query.scope.id,
      'period': query.period.id,
    });
  }

  /// Track interação com ranking
  static Future<void> trackRankingInteraction(
    String action,
    RankingEntry entry,
  ) async {
    await _trackRankingEvent('interaction', {
      'action': action,
      'target_user_id': entry.userId,
      'position': entry.position,
      'value': entry.value,
    });
  }
}
