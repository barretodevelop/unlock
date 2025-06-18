// lib/core/services/gamification_service.dart
// Serviço central de gamificação - Fase 3

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/constants/gamification_constants.dart';
import 'package:unlock/core/utils/level_calculator.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/rewards/services/rewards_service.dart';
import 'package:unlock/models/user_model.dart';

/// Serviço central para todas as operações de gamificação
class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RewardsService _rewardsService = RewardsService();

  // ================================================================================================
  // OPERAÇÕES DE XP E NÍVEIS
  // ================================================================================================

  /// Conceder XP ao usuário e verificar level up
  Future<Map<String, dynamic>> grantXP(
    UserModel user,
    int xpAmount, {
    String? source,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug('⚡ Concedendo $xpAmount XP para usuário ${user.uid}');

      // Verificar limite diário
      if (!await _canGainXPToday(user.uid, xpAmount)) {
        AppLogger.warning('⚠️ Limite diário de XP atingido para usuário ${user.uid}');
        return {
          'success': false,
          'reason': 'daily_limit_reached',
          'message': 'Limite diário de XP atingido',
        };
      }

      // Aplicar multiplicadores
      final finalXP = await _applyXPMultipliers(user, xpAmount);
      
      // Calcular novo nível
      final oldXP = user.xp;
      final newXP = oldXP + finalXP;
      final oldLevel = LevelCalculator.calculateLevel(oldXP);
      final newLevel = LevelCalculator.calculateLevel(newXP);
      
      // Atualizar usuário no Firestore
      await _updateUserXP(user.uid, newXP, newLevel);

      // Verificar se subiu de nível
      final leveledUp = newLevel > oldLevel;
      final result = {
        'success': true,
        'oldXP': oldXP,
        'newXP': newXP,
        'xpGained': finalXP,
        'oldLevel': oldLevel,
        'newLevel': newLevel,
        'leveledUp': leveledUp,
        'multiplierApplied': finalXP != xpAmount,
      };

      // Se subiu de nível, conceder recompensas
      if (leveledUp) {
        await _handleLevelUp(user.uid, newLevel, oldLevel);
        result['levelUpRewards'] = (await _getLevelUpRewardsInfo(newLevel))!;
      }

      // Registrar ganho de XP para analytics
      await _recordXPGain(user.uid, finalXP, source, description, metadata);

      AppLogger.info('✅ XP concedido: +$finalXP XP (nível $oldLevel → $newLevel)');
      return result;

    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao conceder XP', error:e );
      return {
        'success': false,
        'reason': 'error',
        'message': 'Erro interno: $e',
      };
    }
  }

  /// Conceder coins ao usuário
  Future<Map<String, dynamic>> grantCoins(
    UserModel user,
    int coinsAmount, {
    String? source,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug('🪙 Concedendo $coinsAmount coins para usuário ${user.uid}');

      // Verificar limite diário
      if (!await _canGainCoinsToday(user.uid, coinsAmount)) {
        AppLogger.warning('⚠️ Limite diário de coins atingido para usuário ${user.uid}');
        return {
          'success': false,
          'reason': 'daily_limit_reached',
          'message': 'Limite diário de coins atingido',
        };
      }

      // Aplicar multiplicador de nível
      final finalCoins = LevelCalculator.applyLevelMultiplierToCoins(coinsAmount, user.level);
      
      // Atualizar usuário no Firestore
      final newCoins = user.coins + finalCoins;
      await _updateUserCoins(user.uid, newCoins);

      // Registrar ganho
      await _recordCoinsGain(user.uid, finalCoins, source, description, metadata);

      AppLogger.info('✅ Coins concedidos: +$finalCoins coins (total: $newCoins)');
      
      return {
        'success': true,
        'oldCoins': user.coins,
        'newCoins': newCoins,
        'coinsGained': finalCoins,
        'multiplierApplied': finalCoins != coinsAmount,
      };

    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao conceder coins', error:e );
      return {
        'success': false,
        'reason': 'error',
        'message': 'Erro interno: $e',
      };
    }
  }

  /// Conceder gems ao usuário
  Future<Map<String, dynamic>> grantGems(
    UserModel user,
    int gemsAmount, {
    String? source,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug('💎 Concedendo $gemsAmount gems para usuário ${user.uid}');

      // Verificar limite semanal
      if (!await _canGainGemsThisWeek(user.uid, gemsAmount)) {
        AppLogger.warning('⚠️ Limite semanal de gems atingido para usuário ${user.uid}');
        return {
          'success': false,
          'reason': 'weekly_limit_reached',
          'message': 'Limite semanal de gems atingido',
        };
      }

      // Atualizar usuário no Firestore
      final newGems = user.gems + gemsAmount;
      await _updateUserGems(user.uid, newGems);

      // Registrar ganho
      await _recordGemsGain(user.uid, gemsAmount, source, description, metadata);

      AppLogger.info('✅ Gems concedidas: +$gemsAmount gems (total: $newGems)');
      
      return {
        'success': true,
        'oldGems': user.gems,
        'newGems': newGems,
        'gemsGained': gemsAmount,
      };

    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao conceder gems', error:e );
      return {
        'success': false,
        'reason': 'error',
        'message': 'Erro interno: $e',
      };
    }
  }

  // ================================================================================================
  // SISTEMA DE LOGIN E STREAKS
  // ================================================================================================

  /// Processar login diário e conceder recompensas
  Future<Map<String, dynamic>> processDailyLogin(UserModel user) async {
    try {
      AppLogger.debug('📅 Processando login diário para usuário ${user.uid}');

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      // Obter dados de streak do usuário
      final userData = await _getUserDocument(user.uid);
      final lastLoginDate = userData?['lastLoginDate'] != null 
          ? DateTime.tryParse(userData!['lastLoginDate'])
          : null;
      
      int currentStreak = userData?['loginStreak'] ?? 0;
      bool alreadyLoggedToday = false;

      // Verificar se já fez login hoje
      if (lastLoginDate != null) {
        final lastLoginDay = DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
        final todayDay = DateTime(today.year, today.month, today.day);
        
        if (lastLoginDay.isAtSameMomentAs(todayDay)) {
          alreadyLoggedToday = true;
        } else {
          // Verificar se manteve a sequência (login ontem)
          final yesterdayDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
          
          if (lastLoginDay.isAtSameMomentAs(yesterdayDay)) {
            currentStreak += 1; // Manteve sequência
          } else {
            currentStreak = 1; // Quebrou sequência, reinicia
          }
        }
      } else {
        currentStreak = 1; // Primeiro login
      }

      // Atualizar dados de login
      await _updateLoginData(user.uid, today, currentStreak);

      final result = {
        'alreadyLoggedToday': alreadyLoggedToday,
        'streak': currentStreak,
        'bonusGiven': false,
        'bonusAmount': 0,
      };

      // Conceder bônus se não logou hoje
      if (!alreadyLoggedToday) {
        final bonusCoins = LevelCalculator.calculateDailyLoginBonus(currentStreak);
        
        if (bonusCoins > 0) {
          await grantCoins(
            user,
            bonusCoins,
            source: 'daily_login',
            description: 'Bônus de login diário ($currentStreak dias)',
            metadata: {'streak': currentStreak},
          );
          
          result['bonusGiven'] = true;
          result['bonusAmount'] = bonusCoins;
        }
      }

      AppLogger.info('✅ Login processado: sequência de $currentStreak dias');
      return result;

    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao processar login diário', error:e );
      return {
        'alreadyLoggedToday': false,
        'streak': 1,
        'bonusGiven': false,
        'bonusAmount': 0,
        'error': e.toString(),
      };
    }
  }

  // ================================================================================================
  // MÉTODOS AUXILIARES PRIVADOS
  // ================================================================================================

  /// Verificar se pode ganhar XP hoje
  Future<bool> _canGainXPToday(String userId, int amount) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('xp_gains')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .get();

      final todayXP = query.docs.fold<int>(0, (sum, doc) {
        final data = doc.data();
        return sum + (data['amount'] as int? ?? 0);
      });

      return todayXP + amount <= GamificationConstants.maxDailyXP;

    } catch (e) {
      AppLogger.error('❌ Erro ao verificar limite diário de XP',error: e);
      return true; // Em caso de erro, permitir
    }
  }

  /// Verificar se pode ganhar coins hoje
  Future<bool> _canGainCoinsToday(String userId, int amount) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('coins_gains')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .get();

      final todayCoins = query.docs.fold<int>(0, (sum, doc) {
        final data = doc.data();
        return sum + (data['amount'] as int? ?? 0);
      });

      return todayCoins + amount <= GamificationConstants.maxDailyCoins;

    } catch (e) {
      AppLogger.error('❌ Erro ao verificar limite diário de coins',error:e);
      return true;
    }
  }

  /// Verificar se pode ganhar gems esta semana
  Future<bool> _canGainGemsThisWeek(String userId, int amount) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('gems_gains')
          .where('timestamp', isGreaterThanOrEqualTo: startOfWeekDay)
          .get();

      final weeklyGems = query.docs.fold<int>(0, (sum, doc) {
        final data = doc.data();
        return sum + (data['amount'] as int? ?? 0);
      });

      return weeklyGems + amount <= GamificationConstants.maxWeeklyGems;

    } catch (e) {
      AppLogger.error('❌ Erro ao verificar limite semanal de gems',error: e);
      return true;
    }
  }

  /// Aplicar multiplicadores de XP
  Future<int> _applyXPMultipliers(UserModel user, int baseXP) async {
    try {
      double multiplier = 1.0;

      // Obter streak de login
      final userData = await _getUserDocument(user.uid);
      final loginStreak = userData?['loginStreak'] ?? 0;

      // Aplicar multiplicador de streak
      for (final entry in GamificationConstants.loginStreakXPMultiplier.entries) {
        if (loginStreak >= entry.key) {
          multiplier = entry.value;
        }
      }

      return (baseXP * multiplier).round();

    } catch (e) {
      AppLogger.error('❌ Erro ao aplicar multiplicadores de XP',error: e);
      return baseXP; // Retornar valor base em caso de erro
    }
  }

  /// Processar level up
  Future<void> _handleLevelUp(String userId, int newLevel, int oldLevel) async {
    try {
      AppLogger.info('🎉 Usuário $userId subiu de nível: $oldLevel → $newLevel');

      // Conceder recompensas de level up através do RewardsService
      // (implementação será chamada pelo rewards_provider)

      // Registrar evento de level up
      await _recordLevelUp(userId, newLevel, oldLevel);

      // Verificar conquistas relacionadas a nível
      await _checkLevelAchievements(userId, newLevel);

    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao processar level up', error:e );
    }
  }

  /// Atualizar XP do usuário
  Future<void> _updateUserXP(String userId, int newXP, int newLevel) async {
    await _firestore.collection('users').doc(userId).update({
      'xp': newXP,
      'level': newLevel,
      'lastXPUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Atualizar coins do usuário
  Future<void> _updateUserCoins(String userId, int newCoins) async {
    await _firestore.collection('users').doc(userId).update({
      'coins': newCoins,
      'lastCoinsUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Atualizar gems do usuário
  Future<void> _updateUserGems(String userId, int newGems) async {
    await _firestore.collection('users').doc(userId).update({
      'gems': newGems,
      'lastGemsUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Atualizar dados de login
  Future<void> _updateLoginData(String userId, DateTime loginDate, int streak) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLoginDate': loginDate.toIso8601String(),
      'loginStreak': streak,
      'totalLogins': FieldValue.increment(1),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  /// Obter documento do usuário
  Future<Map<String, dynamic>?> _getUserDocument(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      AppLogger.error('❌ Erro ao obter documento do usuário', error: e);
      return null;
    }
  }

  /// Registrar ganho de XP para analytics
  Future<void> _recordXPGain(
    String userId,
    int amount,
    String? source,
    String? description,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('xp_gains')
          .add({
            'amount': amount,
            'source': source,
            'description': description,
            'metadata': metadata ?? {},
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.error('❌ Erro ao registrar ganho de XP', error: e);
    }
  }

  /// Registrar ganho de coins
  Future<void> _recordCoinsGain(
    String userId,
    int amount,
    String? source,
    String? description,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('coins_gains')
          .add({
            'amount': amount,
            'source': source,
            'description': description,
            'metadata': metadata ?? {},
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.error('❌ Erro ao registrar ganho de coins', error:e);
    }
  }

  /// Registrar ganho de gems
  Future<void> _recordGemsGain(
    String userId,
    int amount,
    String? source,
    String? description,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('gems_gains')
          .add({
            'amount': amount,
            'source': source,
            'description': description,
            'metadata': metadata ?? {},
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.error('❌ Erro ao registrar ganho de gems', error :e);
    }
  }

  /// Registrar level up
  Future<void> _recordLevelUp(String userId, int newLevel, int oldLevel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('level_ups')
          .add({
            'oldLevel': oldLevel,
            'newLevel': newLevel,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.error('❌ Erro ao registrar level up', error:e);
    }
  }

  /// Verificar conquistas relacionadas a nível
  Future<void> _checkLevelAchievements(String userId, int level) async {
    // Implementação futura para verificar e desbloquear conquistas
    // baseadas no nível atingido
  }

  /// Obter informações das recompensas de level up
  Future<Map<String, dynamic>?> _getLevelUpRewardsInfo(int level) async {
    final rewards = LevelCalculator.getLevelUpRewards(level);
    if (rewards == null) return null;
    
    return {
      'level': level,
      'rewards': rewards,
      'title': LevelCalculator.getUserTitle(level),
    };
  }

  // ================================================================================================
  // MÉTODOS PÚBLICOS UTILITÁRIOS
  // ================================================================================================

  /// Obter estatísticas de gamificação do usuário
  Future<Map<String, dynamic>> getUserGamificationStats(String userId) async {
    try {
      final userData = await _getUserDocument(userId);
      if (userData == null) return {};

      final xp = userData['xp'] ?? 0;
      final level = LevelCalculator.calculateLevel(xp);
      final progress = LevelCalculator.calculateLevelProgress(xp);
      final xpToNext = LevelCalculator.calculateXPToNextLevel(xp);

      return {
        'level': level,
        'xp': xp,
        'levelProgress': progress,
        'xpToNextLevel': xpToNext,
        'title': LevelCalculator.getUserTitle(level),
        'coins': userData['coins'] ?? 0,
        'gems': userData['gems'] ?? 0,
        'loginStreak': userData['loginStreak'] ?? 0,
        'totalLogins': userData['totalLogins'] ?? 0,
      };

    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao obter stats de gamificação', error:e );
      return {};
    }
  }

  /// Validar integridade do sistema de gamificação
  Future<bool> validateGamificationSystem() async {
    try {
      // Verificar se as fórmulas de nível estão funcionando
      final systemValid = LevelCalculator.validateLevelSystem();
      
      AppLogger.info(systemValid 
          ? '✅ Sistema de gamificação validado'
          : '❌ Sistema de gamificação com problemas');
      
      return systemValid;

    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao validar sistema de gamificação', error:e );
      return false;
    }
  }
}