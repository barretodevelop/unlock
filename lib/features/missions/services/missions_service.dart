// lib/features/missions/services/missions_service.dart
// Serviço para operações de missões no Firestore - Fase 3 (CORRIGIDO)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/core/utils/mission_generator.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/models/user_model.dart';

/// Serviço para gerenciar missões no Firestore
class MissionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================================================================================================
  // COLEÇÕES DO FIRESTORE
  // ================================================================================================

  /// Coleção de missões globais (templates)
  CollectionReference get _missionsCollection =>
      _firestore.collection('missions');

  /// Subcoleção de missões do usuário
  CollectionReference _userMissionsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('missions');

  /// Subcoleção de progresso das missões
  CollectionReference _userMissionProgressCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('mission_progress');

  // ================================================================================================
  // OPERAÇÕES DE LEITURA
  // ================================================================================================

  /// Obter missões diárias do usuário
  Future<List<MissionModel>> getUserDailyMissions(String userId) async {
    try {
      AppLogger.debug('📖 Buscando missões diárias para usuário $userId');

      final query = await _userMissionsCollection(userId)
          .where('type', isEqualTo: 'daily')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final missions = query.docs
          .map(
            (doc) => MissionModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .where((mission) => !mission.isExpired)
          .toList();

      AppLogger.info('✅ Encontradas ${missions.length} missões diárias');
      return missions;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao buscar missões diárias', error: e);
      return [];
    }
  }

  /// Obter missões semanais do usuário
  Future<List<MissionModel>> getUserWeeklyMissions(String userId) async {
    try {
      AppLogger.debug('📖 Buscando missões semanais para usuário $userId');

      final query = await _userMissionsCollection(userId)
          .where('type', isEqualTo: 'weekly')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final missions = query.docs
          .map(
            (doc) => MissionModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .where((mission) => !mission.isExpired)
          .toList();

      AppLogger.info('✅ Encontradas ${missions.length} missões semanais');
      return missions;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao buscar missões semanais', error: e);
      return [];
    }
  }

  /// Obter missões colaborativas do usuário
  Future<List<MissionModel>> getUserCollaborativeMissions(String userId) async {
    try {
      AppLogger.debug('📖 Buscando missões colaborativas para usuário $userId');

      final query = await _userMissionsCollection(userId)
          .where('type', isEqualTo: 'collaborative')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final missions = query.docs
          .map(
            (doc) => MissionModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .where((mission) => !mission.isExpired)
          .toList();

      AppLogger.info('✅ Encontradas ${missions.length} missões colaborativas');
      return missions;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao buscar missões colaborativas', error: e);
      return [];
    }
  }

  /// Obter progresso das missões do usuário
  Future<Map<String, UserMissionProgress>> getUserMissionProgresses(
    String userId,
    List<String> missionIds,
  ) async {
    try {
      AppLogger.debug('📊 Buscando progresso das missões para usuário $userId');

      if (missionIds.isEmpty) return {};

      final progresses = <String, UserMissionProgress>{};

      // Buscar progresso em lotes para evitar limite do Firestore
      const batchSize = 10;
      for (int i = 0; i < missionIds.length; i += batchSize) {
        final batch = missionIds.skip(i).take(batchSize).toList();

        final query = await _userMissionProgressCollection(
          userId,
        ).where('missionId', whereIn: batch).get();

        for (final doc in query.docs) {
          final progress = UserMissionProgress.fromJson({
            ...doc.data() as Map<String, dynamic>,
          });
          progresses[progress.missionId] = progress;
        }
      }

      // Criar progresso inicial para missões sem progresso
      for (final missionId in missionIds) {
        if (!progresses.containsKey(missionId)) {
          progresses[missionId] = UserMissionProgress(
            missionId: missionId,
            userId: userId,
            targetProgress: 1, // Será atualizado quando a missão for carregada
            startedAt: DateTime.now(),
          );
        }
      }

      AppLogger.info('✅ Progresso carregado para ${progresses.length} missões');
      return progresses;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao buscar progresso das missões', error: e);
      return {};
    }
  }

  // ================================================================================================
  // ✅ CORREÇÃO CRÍTICA: VERIFICAÇÕES DE GERAÇÃO AUTOMÁTICA
  // ================================================================================================

  /// Verificar se deve gerar novas missões diárias
  Future<bool> shouldGenerateNewDailyMissions(String userId) async {
    try {
      AppLogger.debug(
        '🔍 Verificando necessidade de missões diárias para $userId',
      );

      // Verificar se já tem missões diárias ativas hoje
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = await _userMissionsCollection(userId)
          .where('type', isEqualTo: 'daily')
          .where('isActive', isEqualTo: true)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
          )
          .where('createdAt', isLessThan: endOfDay.toIso8601String())
          .get();

      final hasActiveDailyMissions = query.docs.isNotEmpty;
      final shouldGenerate = !hasActiveDailyMissions;

      AppLogger.debug(
        shouldGenerate
            ? '✨ Deve gerar missões diárias (nenhuma ativa hoje)'
            : '✅ Já possui missões diárias ativas hoje',
      );

      return shouldGenerate;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao verificar necessidade de missões diárias',
        error: e,
      );
      // Em caso de erro, gerar por segurança
      return true;
    }
  }

  /// Verificar se deve gerar novas missões semanais
  Future<bool> shouldGenerateNewWeeklyMissions(String userId) async {
    try {
      AppLogger.debug(
        '🔍 Verificando necessidade de missões semanais para $userId',
      );

      // Verificar se já tem missões semanais ativas esta semana
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      final query = await _userMissionsCollection(userId)
          .where('type', isEqualTo: 'weekly')
          .where('isActive', isEqualTo: true)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: startOfWeekDay.toIso8601String(),
          )
          .get();

      final hasActiveWeeklyMissions = query.docs.isNotEmpty;
      final shouldGenerate = !hasActiveWeeklyMissions;

      AppLogger.debug(
        shouldGenerate
            ? '✨ Deve gerar missões semanais (nenhuma ativa esta semana)'
            : '✅ Já possui missões semanais ativas esta semana',
      );

      return shouldGenerate;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao verificar necessidade de missões semanais',
        error: e,
      );
      // Em caso de erro, gerar por segurança
      return true;
    }
  }

  // ================================================================================================
  // GERAÇÃO DE MISSÕES (métodos existentes melhorados)
  // ================================================================================================

  /// Gerar novas missões diárias para o usuário
  Future<List<MissionModel>> generateDailyMissions(UserModel user) async {
    try {
      AppLogger.debug('🎯 Gerando missões diárias para usuário ${user.uid}');

      // ✅ VERIFICAÇÃO: Não gerar se já tem missões válidas
      if (!await shouldGenerateNewDailyMissions(user.uid)) {
        AppLogger.info(
          '⏭️ Pulando geração - já possui missões diárias válidas',
        );
        return getUserDailyMissions(user.uid);
      }

      // Obter requisitos do usuário
      final userRequirements = await _getUserRequirements(user);

      // Obter missões completadas recentemente para evitar repetição
      final recentMissions = await _getRecentCompletedMissions(
        user.uid,
        days: 7,
      );

      // Gerar missões usando o gerador
      final missions = MissionGenerator.generateDailyMissions(
        user,
        userRequirements: userRequirements,
        completedMissionIds: recentMissions,
      );

      // ✅ FALLBACK: Se gerador falhou, criar missões básicas
      if (missions.isEmpty) {
        AppLogger.warning('⚠️ Gerador não retornou missões - criando fallback');
        final fallbackMissions = _createFallbackDailyMissions(user);
        await _saveMissionsToFirestore(user.uid, fallbackMissions);
        await _createInitialProgress(user.uid, fallbackMissions);
        return fallbackMissions;
      }

      // Salvar missões no Firestore
      await _saveMissionsToFirestore(user.uid, missions);

      // Criar progresso inicial para as missões
      await _createInitialProgress(user.uid, missions);

      AppLogger.info('✅ ${missions.length} missões diárias geradas e salvas');
      return missions;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao gerar missões diárias', error: e);

      // ✅ FALLBACK EM CASO DE ERRO
      try {
        AppLogger.info('🔄 Tentando fallback para missões diárias');
        final fallbackMissions = _createFallbackDailyMissions(user);
        await _saveMissionsToFirestore(user.uid, fallbackMissions);
        await _createInitialProgress(user.uid, fallbackMissions);
        return fallbackMissions;
      } catch (fallbackError) {
        AppLogger.error('❌ Fallback também falhou', error: fallbackError);
        return [];
      }
    }
  }

  /// Gerar novas missões semanais para o usuário
  Future<List<MissionModel>> generateWeeklyMissions(UserModel user) async {
    try {
      AppLogger.debug('🎯 Gerando missões semanais para usuário ${user.uid}');

      // ✅ VERIFICAÇÃO: Não gerar se já tem missões válidas
      if (!await shouldGenerateNewWeeklyMissions(user.uid)) {
        AppLogger.info(
          '⏭️ Pulando geração - já possui missões semanais válidas',
        );
        return getUserWeeklyMissions(user.uid);
      }

      final userRequirements = await _getUserRequirements(user);
      final recentMissions = await _getRecentCompletedMissions(
        user.uid,
        days: 30,
      );

      final missions = MissionGenerator.generateWeeklyMissions(
        user,
        userRequirements: userRequirements,
        completedMissionIds: recentMissions,
      );

      // ✅ FALLBACK: Se gerador falhou, criar missões básicas
      if (missions.isEmpty) {
        AppLogger.warning(
          '⚠️ Gerador não retornou missões semanais - criando fallback',
        );
        final fallbackMissions = _createFallbackWeeklyMissions(user);
        await _saveMissionsToFirestore(user.uid, fallbackMissions);
        await _createInitialProgress(user.uid, fallbackMissions);
        return fallbackMissions;
      }

      await _saveMissionsToFirestore(user.uid, missions);
      await _createInitialProgress(user.uid, missions);

      AppLogger.info('✅ ${missions.length} missões semanais geradas e salvas');
      return missions;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao gerar missões semanais', error: e);

      // ✅ FALLBACK EM CASO DE ERRO
      try {
        AppLogger.info('🔄 Tentando fallback para missões semanais');
        final fallbackMissions = _createFallbackWeeklyMissions(user);
        await _saveMissionsToFirestore(user.uid, fallbackMissions);
        await _createInitialProgress(user.uid, fallbackMissions);
        return fallbackMissions;
      } catch (fallbackError) {
        AppLogger.error(
          '❌ Fallback semanal também falhou',
          error: fallbackError,
        );
        return [];
      }
    }
  }

  // ================================================================================================
  // ✅ NOVOS MÉTODOS: FALLBACK MISSIONS
  // ================================================================================================

  /// Criar missões diárias de fallback (caso gerador principal falhe)
  List<MissionModel> _createFallbackDailyMissions(UserModel user) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    return [
      MissionModel(
        id: 'daily_fallback_${now.millisecondsSinceEpoch}_1',
        title: 'Primeiro Login',
        description: 'Faça seu login diário para ganhar recompensas',
        type: MissionType.daily,
        category: MissionCategory.social,
        xpReward: 25,
        coinsReward: 10,
        gemsReward: 0,
        targetValue: 1,
        difficulty: 1,
        createdAt: now,
        expiresAt: tomorrow,
        requirements: [],
        isActive: true,
      ),
      MissionModel(
        id: 'daily_fallback_${now.millisecondsSinceEpoch}_2',
        title: 'Explorar Perfis',
        description: 'Visualize 3 perfis de outros usuários',
        type: MissionType.daily,
        category: MissionCategory.exploration,
        xpReward: 30,
        coinsReward: 15,
        gemsReward: 1,
        targetValue: 3,
        difficulty: 2,
        createdAt: now,
        expiresAt: tomorrow,
        requirements: [],
        isActive: true,
      ),
      MissionModel(
        id: 'daily_fallback_${now.millisecondsSinceEpoch}_3',
        title: 'Atualizar Perfil',
        description: 'Complete ou atualize informações do seu perfil',
        type: MissionType.daily,
        category: MissionCategory.profile,
        xpReward: 40,
        coinsReward: 20,
        gemsReward: 2,
        targetValue: 1,
        difficulty: 1,
        createdAt: now,
        expiresAt: tomorrow,
        requirements: [],
        isActive: true,
      ),
    ];
  }

  /// Criar missões semanais de fallback
  List<MissionModel> _createFallbackWeeklyMissions(UserModel user) {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return [
      MissionModel(
        id: 'weekly_fallback_${now.millisecondsSinceEpoch}_1',
        title: 'Fazer Nova Conexão',
        description: 'Conecte-se com pelo menos 1 pessoa nova esta semana',
        type: MissionType.weekly,
        category: MissionCategory.social,
        xpReward: 100,
        coinsReward: 50,
        gemsReward: 5,
        targetValue: 1,
        difficulty: 3,
        createdAt: now,
        expiresAt: nextWeek,
        requirements: [],
        isActive: true,
      ),
      MissionModel(
        id: 'weekly_fallback_${now.millisecondsSinceEpoch}_2',
        title: 'Sessão de Minijogos',
        description: 'Complete 5 minijogos de compatibilidade',
        type: MissionType.weekly,
        category: MissionCategory.gamification,
        xpReward: 150,
        coinsReward: 75,
        gemsReward: 8,
        targetValue: 5,
        difficulty: 4,
        createdAt: now,
        expiresAt: nextWeek,
        requirements: ['has_unlocked_minigames'],
        isActive: true,
      ),
    ];
  }

  // ================================================================================================
  // OPERAÇÕES DE ESCRITA (métodos existentes mantidos)
  // ================================================================================================

  /// Salvar missões no Firestore
  Future<void> _saveMissionsToFirestore(
    String userId,
    List<MissionModel> missions,
  ) async {
    if (missions.isEmpty) return;

    final batch = _firestore.batch();

    for (final mission in missions) {
      final docRef = _userMissionsCollection(userId).doc(mission.id);
      batch.set(docRef, mission.toJson());
    }

    await batch.commit();
    AppLogger.debug('💾 ${missions.length} missões salvas no Firestore');
  }

  /// Criar progresso inicial para as missões
  Future<void> _createInitialProgress(
    String userId,
    List<MissionModel> missions,
  ) async {
    if (missions.isEmpty) return;

    final batch = _firestore.batch();

    for (final mission in missions) {
      final progress = UserMissionProgress(
        missionId: mission.id,
        userId: userId,
        targetProgress: mission.targetValue,
        startedAt: DateTime.now(),
      );

      final docRef = _userMissionProgressCollection(userId).doc(mission.id);
      batch.set(docRef, progress.toJson());
    }

    await batch.commit();
    AppLogger.debug(
      '📊 Progresso inicial criado para ${missions.length} missões',
    );
  }

  /// Atualizar progresso de uma missão
  Future<void> updateMissionProgress(
    String userId,
    UserMissionProgress progress,
  ) async {
    try {
      final docRef = _userMissionProgressCollection(
        userId,
      ).doc(progress.missionId);
      await docRef.set(progress.toJson(), SetOptions(merge: true));

      AppLogger.debug('📈 Progresso atualizado: ${progress.missionId}');
    } catch (e) {
      AppLogger.error('❌ Erro ao atualizar progresso', error: e);
      rethrow;
    }
  }

  /// Limpar missões expiradas
  Future<void> cleanupExpiredMissions(String userId) async {
    try {
      AppLogger.debug('🧹 Limpando missões expiradas para usuário $userId');

      final now = DateTime.now();
      final query = await _userMissionsCollection(
        userId,
      ).where('expiresAt', isLessThan: now.toIso8601String()).get();

      if (query.docs.isEmpty) {
        AppLogger.debug('✅ Nenhuma missão expirada encontrada');
        return;
      }

      final batch = _firestore.batch();

      for (final doc in query.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      await batch.commit();

      AppLogger.info('✅ ${query.docs.length} missões expiradas desativadas');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao limpar missões expiradas', error: e);
    }
  }

  /// Obter estatísticas de missões do usuário
  Future<Map<String, int>> getUserMissionStats(String userId) async {
    try {
      // Contar missões por status
      final allProgressQuery = await _userMissionProgressCollection(
        userId,
      ).get();

      int totalMissions = 0;
      int completedMissions = 0;
      int activeMissions = 0;

      for (final doc in allProgressQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalMissions++;

        if (data['isCompleted'] == true) {
          completedMissions++;
        } else {
          activeMissions++;
        }
      }

      return {
        'total': totalMissions,
        'completed': completedMissions,
        'active': activeMissions,
        'completionRate': totalMissions > 0
            ? ((completedMissions / totalMissions) * 100).round()
            : 0,
      };
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao obter estatísticas de missões', error: e);
      return {};
    }
  }

  // ================================================================================================
  // MÉTODOS AUXILIARES (mantidos inalterados)
  // ================================================================================================

  /// Obter requisitos do usuário para geração de missões
  Future<Map<String, bool>> _getUserRequirements(UserModel user) async {
    return {
      'has_incomplete_profile': user.needsOnboarding,
      'has_viewed_profiles': true, // Implementar baseado em analytics
      'has_connections': true, // Implementar baseado em conexões
      'has_unlocked_minigames': user.level >= 5,
      'has_shop_access': user.level >= 3,
      'has_active_connection': true, // Implementar
      'has_multiple_connections': true, // Implementar
    };
  }

  /// Obter missões completadas recentemente
  Future<List<String>> _getRecentCompletedMissions(
    String userId, {
    int days = 7,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final query = await _userMissionProgressCollection(userId)
          .where('isCompleted', isEqualTo: true)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: cutoffDate.toIso8601String(),
          )
          .get();

      return query.docs
          .map(
            (doc) =>
                (doc.data()! as Map<String, dynamic>)['missionId'] as String? ??
                '',
          )
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao buscar missões completadas recentemente',
        error: e,
      );
      return [];
    }
  }
}
