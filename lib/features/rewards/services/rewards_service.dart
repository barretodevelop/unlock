// lib/features/rewards/services/rewards_service.dart
// Serviço para operações de recompensas no Firestore - Fase 3

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/constants/gamification_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/rewards/models/reward_model.dart';

/// Serviço para gerenciar recompensas no Firestore
class RewardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================================================================================================
  // COLEÇÕES DO FIRESTORE
  // ================================================================================================

  /// Subcoleção de recompensas do usuário
  CollectionReference _userRewardsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('rewards');

  /// Documento do usuário para atualizar stats
  DocumentReference _userDocument(String userId) =>
      _firestore.collection('users').doc(userId);

  /// Coleção de estatísticas de economia global
  CollectionReference get _economyStatsCollection =>
      _firestore.collection('economy_stats');

  // ================================================================================================
  // OPERAÇÕES DE LEITURA
  // ================================================================================================

  /// Obter recompensas pendentes do usuário
  Future<List<RewardModel>> getPendingRewards(String userId) async {
    try {
      AppLogger.debug('🎁 Buscando recompensas pendentes para usuário $userId');

      final query = await _userRewardsCollection(userId)
          .where('isClaimed', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(50) // Limitar para performance
          .get();

      final rewards = query.docs
          .map(
            (doc) => RewardModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      AppLogger.info('✅ Encontradas ${rewards.length} recompensas pendentes');
      return rewards;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao buscar recompensas pendentes', error: e);
      return [];
    }
  }

  /// Obter recompensas já coletadas do usuário
  Future<List<RewardModel>> getClaimedRewards(
    String userId, {
    int limit = 100,
  }) async {
    try {
      AppLogger.debug('📋 Buscando recompensas coletadas para usuário $userId');

      final query = await _userRewardsCollection(userId)
          .where('isClaimed', isEqualTo: true)
          .orderBy('claimedAt', descending: true)
          .limit(limit)
          .get();

      final rewards = query.docs
          .map(
            (doc) => RewardModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      AppLogger.info('✅ Encontradas ${rewards.length} recompensas coletadas');
      return rewards;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao buscar recompensas coletadas', error: e);
      return [];
    }
  }

  /// Obter total ganho por tipo de recompensa
  Future<Map<String, int>> getTotalEarned(String userId) async {
    try {
      AppLogger.debug('📊 Calculando total ganho para usuário $userId');

      final query = await _userRewardsCollection(
        userId,
      ).where('isClaimed', isEqualTo: true).get();

      final totals = <String, int>{
        'xp': 0,
        'coins': 0,
        'gems': 0,
        'achievements': 0,
        'items': 0,
        'titles': 0,
      };

      for (final doc in query.docs) {
        final reward = RewardModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });

        switch (reward.type) {
          case RewardType.xp:
            totals['xp'] = (totals['xp'] ?? 0) + reward.amount;
            break;
          case RewardType.coins:
            totals['coins'] = (totals['coins'] ?? 0) + reward.amount;
            break;
          case RewardType.gems:
            totals['gems'] = (totals['gems'] ?? 0) + reward.amount;
            break;
          case RewardType.achievement:
            totals['achievements'] = (totals['achievements'] ?? 0) + 1;
            break;
          case RewardType.item:
            totals['items'] = (totals['items'] ?? 0) + 1;
            break;
          case RewardType.title:
            totals['titles'] = (totals['titles'] ?? 0) + 1;
            break;
          case RewardType.boost:
            // Boosts não são contabilizados no total
            break;
        }
      }

      AppLogger.info('✅ Total calculado: ${totals.toString()}');
      return totals;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao calcular total ganho', error: e);
      return {};
    }
  }

  /// Obter histórico de recompensas por período
  Future<List<RewardModel>> getRewardsHistory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      AppLogger.debug(
        '📅 Buscando histórico de recompensas de $startDate até $endDate',
      );

      final query = await _userRewardsCollection(userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('createdAt', descending: true)
          .get();

      final rewards = query.docs
          .map(
            (doc) => RewardModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      return rewards;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao buscar histórico de recompensas', error: e);
      return [];
    }
  }

  // ================================================================================================
  // OPERAÇÕES DE ESCRITA
  // ================================================================================================

  /// Conceder recompensas ao usuário
  Future<void> grantRewards(String userId, List<RewardModel> rewards) async {
    try {
      AppLogger.debug(
        '🎁 Concedendo ${rewards.length} recompensas para usuário $userId',
      );

      if (rewards.isEmpty) return;

      final batch = _firestore.batch();

      // Adicionar cada recompensa à subcoleção
      for (final reward in rewards) {
        final docRef = _userRewardsCollection(userId).doc(reward.id);
        batch.set(docRef, reward.toJson());
      }

      await batch.commit();

      // Atualizar estatísticas de economia
      await _updateEconomyStats(rewards);

      AppLogger.info('✅ ${rewards.length} recompensas concedidas com sucesso');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao conceder recompensas', error: e);
      rethrow;
    }
  }

  /// Coletar uma recompensa específica
  Future<void> claimReward(String userId, RewardModel reward) async {
    try {
      AppLogger.debug(
        '🎁 Coletando recompensa ${reward.id} para usuário $userId',
      );

      // Atualizar recompensa como coletada
      await _userRewardsCollection(
        userId,
      ).doc(reward.id).update(reward.toJson());

      AppLogger.info('✅ Recompensa ${reward.id} coletada');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao coletar recompensa', error: e);
      rethrow;
    }
  }

  /// Atualizar estatísticas do usuário (XP, coins, gems)
  Future<void> updateUserStats(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      AppLogger.debug('📊 Atualizando stats do usuário $userId: $updates');

      // Adicionar timestamp da atualização
      final updateData = {
        ...updates,
        'lastStatsUpdate': FieldValue.serverTimestamp(),
      };

      await _userDocument(userId).update(updateData);

      AppLogger.info('✅ Stats do usuário atualizadas');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao atualizar stats do usuário', error: e);
      rethrow;
    }
  }

  /// Conceder recompensa de login diário
  Future<void> grantDailyLoginReward(String userId, int streakDays) async {
    try {
      final bonusCoins = GamificationConstants.getLoginStreakBonus(streakDays);
      if (bonusCoins <= 0) return;

      final reward = RewardModel.coins(
        id: 'daily_login_${DateTime.now().millisecondsSinceEpoch}',
        amount: bonusCoins,
        source: RewardSource.dailyLogin,
        description: 'Bônus de login diário ($streakDays dias seguidos)',
        metadata: {'streakDays': streakDays},
      );

      await grantRewards(userId, [reward]);

      AppLogger.info(
        '✅ Recompensa de login diário concedida: +$bonusCoins coins',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao conceder recompensa de login diário',
        error: e,
      );
    }
  }

  /// Conceder recompensas em lote (para eventos especiais)
  Future<void> grantBatchRewards(String userId, RewardBundle bundle) async {
    try {
      AppLogger.debug('📦 Concedendo bundle de recompensas: ${bundle.title}');

      await grantRewards(userId, bundle.rewards);

      // Salvar informações do bundle
      await _userRewardsCollection(userId).doc('bundle_${bundle.id}').set({
        'type': 'bundle',
        'bundleId': bundle.id,
        'title': bundle.title,
        'description': bundle.description,
        'source': bundle.source.value,
        'createdAt': bundle.createdAt.toIso8601String(),
        'totalRewards': bundle.rewards.length,
        'totalXP': bundle.totalXP,
        'totalCoins': bundle.totalCoins,
        'totalGems': bundle.totalGems,
      });

      AppLogger.info(
        '✅ Bundle de recompensas concedido: ${bundle.rewards.length} itens',
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao conceder bundle de recompensas', error: e);
    }
  }

  // ================================================================================================
  // VALIDAÇÕES E VERIFICAÇÕES
  // ================================================================================================

  /// Verificar se usuário pode receber recompensa
  Future<bool> canReceiveReward(
    String userId,
    RewardType type,
    int amount,
  ) async {
    try {
      // Verificar limites diários/semanais
      switch (type) {
        case RewardType.xp:
          final dailyXP = await _getDailyXPGained(userId);
          return dailyXP + amount <= GamificationConstants.maxDailyXP;

        case RewardType.coins:
          final dailyCoins = await _getDailyCoinsGained(userId);
          return dailyCoins + amount <= GamificationConstants.maxDailyCoins;

        case RewardType.gems:
          final weeklyGems = await _getWeeklyGemsGained(userId);
          return weeklyGems + amount <= GamificationConstants.maxWeeklyGems;

        default:
          return true; // Outros tipos não têm limites
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao verificar se pode receber recompensa',
        error: e,
      );
      return false;
    }
  }

  Future<int> _sumRewards({
    required String userId,
    required RewardType type,
    required DateTime from,
    required DateTime to,
  }) async {
    final rewards = await getRewardsHistory(userId, from, to);

    final amounts = await Future.wait<int>(
      rewards
          .where((r) => r.type == type && r.isClaimed)
          .map((r) async => r.amount),
    );

    return amounts.fold<int>(0, (sum, value) => sum + value);
  }

  Future<int> _getDailyXPGained(String userId) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return _sumRewards(
      userId: userId,
      type: RewardType.xp,
      from: start,
      to: today,
    );
  }

  Future<int> _getDailyCoinsGained(String userId) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return _sumRewards(
      userId: userId,
      type: RewardType.coins,
      from: start,
      to: today,
    );
  }

  Future<int> _getWeeklyGemsGained(String userId) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(start.year, start.month, start.day);
    return _sumRewards(
      userId: userId,
      type: RewardType.gems,
      from: startOfWeek,
      to: now,
    );
  }

  // ================================================================================================
  // ESTATÍSTICAS E ANÁLISES
  // ================================================================================================

  /// Atualizar estatísticas globais de economia
  Future<void> _updateEconomyStats(List<RewardModel> rewards) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final statsDoc = _economyStatsCollection.doc(dateKey);

      // Calcular totais por tipo
      final totals = <String, int>{};
      for (final reward in rewards) {
        final key = reward.type.value;
        totals[key] = (totals[key] ?? 0) + reward.amount;
      }

      // Atualizar usando increment para evitar conflitos
      final updates = <String, dynamic>{};
      for (final entry in totals.entries) {
        updates['${entry.key}_granted'] = FieldValue.increment(entry.value);
        updates['${entry.key}_count'] = FieldValue.increment(1);
      }

      await statsDoc.set(updates, SetOptions(merge: true));
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao atualizar estatísticas de economia', error: e);
      // Não relançar erro para não afetar operação principal
    }
  }

  /// Obter estatísticas de recompensas do usuário
  Future<Map<String, dynamic>> getUserRewardStats(String userId) async {
    try {
      final pendingRewards = await getPendingRewards(userId);
      final totalEarned = await getTotalEarned(userId);

      // Estatísticas da última semana
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final weeklyRewards = await getRewardsHistory(
        userId,
        lastWeek,
        DateTime.now(),
      );

      final weeklyStats = <String, int>{};
      for (final reward in weeklyRewards.where((r) => r.isClaimed)) {
        final key = reward.type.value;
        weeklyStats[key] = (weeklyStats[key] ?? 0) + reward.amount;
      }

      return {
        'pending': {
          'count': pendingRewards.length,
          'xp': pendingRewards
              .where((r) => r.type == RewardType.xp)
              .fold(0, (sum, r) => sum + r.amount),
          'coins': pendingRewards
              .where((r) => r.type == RewardType.coins)
              .fold(0, (sum, r) => sum + r.amount),
          'gems': pendingRewards
              .where((r) => r.type == RewardType.gems)
              .fold(0, (sum, r) => sum + r.amount),
        },
        'totalEarned': totalEarned,
        'weeklyStats': weeklyStats,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao obter estatísticas de recompensas', error: e);
      return {};
    }
  }

  /// Limpar recompensas antigas
  Future<void> cleanupOldRewards(String userId, {int daysToKeep = 90}) async {
    try {
      AppLogger.debug('🧹 Limpando recompensas antigas para usuário $userId');

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final query = await _userRewardsCollection(userId)
          .where('isClaimed', isEqualTo: true)
          .where('claimedAt', isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = _firestore.batch();

      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      AppLogger.info('✅ ${query.docs.length} recompensas antigas removidas');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao limpar recompensas antigas', error: e);
    }
  }
}
