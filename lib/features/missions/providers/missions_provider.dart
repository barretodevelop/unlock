// lib/features/missions/providers/missions_provider.dart
// Provider para gerenciamento de missões - Fase 3 (CORRIGIDO)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/features/missions/services/missions_service.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Estado das missões do usuário
class MissionsState {
  final List<MissionModel> dailyMissions;
  final List<MissionModel> weeklyMissions;
  final List<MissionModel> collaborativeMissions;
  final Map<String, UserMissionProgress> progresses;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final bool isInitialized; // ✅ NOVO: Flag de inicialização

  const MissionsState({
    this.dailyMissions = const [],
    this.weeklyMissions = const [],
    this.collaborativeMissions = const [],
    this.progresses = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.isInitialized = false, // ✅ NOVO
  });

  MissionsState copyWith({
    List<MissionModel>? dailyMissions,
    List<MissionModel>? weeklyMissions,
    List<MissionModel>? collaborativeMissions,
    Map<String, UserMissionProgress>? progresses,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    bool? isInitialized, // ✅ NOVO
  }) {
    return MissionsState(
      dailyMissions: dailyMissions ?? this.dailyMissions,
      weeklyMissions: weeklyMissions ?? this.weeklyMissions,
      collaborativeMissions:
          collaborativeMissions ?? this.collaborativeMissions,
      progresses: progresses ?? this.progresses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isInitialized: isInitialized ?? this.isInitialized, // ✅ NOVO
    );
  }

  /// Obter todas as missões
  List<MissionModel> get allMissions => [
    ...dailyMissions,
    ...weeklyMissions,
    ...collaborativeMissions,
  ];

  /// Obter missões ativas (não expiradas)
  List<MissionModel> get activeMissions => allMissions
      .where((mission) => mission.isActive && !mission.isExpired)
      .toList();

  /// Obter missões completadas
  List<MissionModel> get completedMissions => allMissions
      .where((mission) => progresses[mission.id]?.isCompleted == true)
      .toList();

  /// Obter progresso de uma missão específica
  UserMissionProgress? getProgress(String missionId) => progresses[missionId];

  /// Verificar se uma missão está completa
  bool isMissionCompleted(String missionId) =>
      progresses[missionId]?.isCompleted == true;

  /// Obter percentual de progresso de uma missão
  double getMissionProgress(String missionId) =>
      progresses[missionId]?.progressPercentage ?? 0.0;

  /// Contar missões completadas hoje
  int get dailyMissionsCompleted =>
      dailyMissions.where((m) => isMissionCompleted(m.id)).length;

  /// Contar missões completadas esta semana
  int get weeklyMissionsCompleted =>
      weeklyMissions.where((m) => isMissionCompleted(m.id)).length;
}

/// Provider principal de missões
final missionsProvider = StateNotifierProvider<MissionsNotifier, MissionsState>(
  (ref) {
    return MissionsNotifier(ref);
  },
);

/// Notifier para gerenciar estado das missões
class MissionsNotifier extends StateNotifier<MissionsState> {
  final Ref _ref;
  final MissionsService _service = MissionsService();
  bool _disposed = false; // ✅ NOVO: Flag de dispose

  MissionsNotifier(this._ref) : super(const MissionsState()) {
    _initializeWithAutoGeneration(); // ✅ CORREÇÃO: Auto-inicialização
  }

  // ================================================================================================
  // ✅ CORREÇÃO CRÍTICA: AUTO-INICIALIZAÇÃO
  // ================================================================================================

  /// Inicializar provider com geração automática de missões
  Future<void> _initializeWithAutoGeneration() async {
    if (_disposed) return;

    try {
      AppLogger.debug('🚀 Inicializando MissionsProvider...');

      // Escutar mudanças no auth provider para auto-inicialização
      _ref.listen(authProvider, (previous, next) async {
        if (_disposed) return;

        // ✅ TRIGGER: Usuario fez login
        if (next.isAuthenticated &&
            next.user != null &&
            previous?.isAuthenticated != true) {
          AppLogger.info(
            '👤 Usuario logado detectado - iniciando sistema de missões',
          );
          await _handleUserLogin(next.user!);
        }

        // ✅ TRIGGER: Usuario fez logout
        if (!next.isAuthenticated && previous?.isAuthenticated == true) {
          AppLogger.info('👋 Usuario deslogado - limpando missões');
          _handleUserLogout();
        }
      });

      // ✅ INICIALIZAÇÃO IMEDIATA: Se já tem usuário logado
      final authState = _ref.read(authProvider);
      if (authState.isAuthenticated && authState.user != null) {
        AppLogger.info('🔄 Usuario já logado - carregando missões existentes');
        await _handleUserLogin(authState.user!);
      }
    } catch (e) {
      AppLogger.error('❌ Erro na inicialização do MissionsProvider', error: e);
      if (!_disposed) {
        state = state.copyWith(
          error: 'Erro na inicialização: $e',
          isLoading: false,
        );
      }
    }
  }

  /// Lidar com login do usuário
  Future<void> _handleUserLogin(UserModel user) async {
    if (_disposed) return;

    try {
      AppLogger.debug('🎯 Processando login do usuário ${user.uid}');

      state = state.copyWith(isLoading: true, error: null);

      // 1. Carregar missões existentes
      await loadUserMissions(user);

      // 2. Verificar e gerar novas missões se necessário
      await _ensureUserHasMissions(user);

      // 3. Marcar como inicializado
      if (!_disposed) {
        state = state.copyWith(
          isInitialized: true,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
      }

      AppLogger.info('✅ Sistema de missões inicializado para ${user.uid}');
    } catch (e) {
      AppLogger.error('❌ Erro ao processar login do usuário', error: e);
      if (!_disposed) {
        state = state.copyWith(
          error: 'Erro ao carregar missões: $e',
          isLoading: false,
        );
      }
    }
  }

  /// Lidar com logout do usuário
  void _handleUserLogout() {
    if (_disposed) return;

    AppLogger.debug('🧹 Limpando estado das missões (logout)');
    state = const MissionsState(); // Reset completo
  }

  /// Garantir que o usuário tem missões disponíveis
  Future<void> _ensureUserHasMissions(UserModel user) async {
    if (_disposed) return;

    try {
      bool needsGeneration = false;
      String generationType = '';

      // ✅ VERIFICAR MISSÕES DIÁRIAS
      if (state.dailyMissions.isEmpty ||
          await _service.shouldGenerateNewDailyMissions(user.uid)) {
        AppLogger.info('📅 Gerando novas missões diárias para ${user.uid}');
        await generateDailyMissions(user);
        needsGeneration = true;
        generationType += 'diárias ';
      }

      // ✅ VERIFICAR MISSÕES SEMANAIS
      if (state.weeklyMissions.isEmpty ||
          await _service.shouldGenerateNewWeeklyMissions(user.uid)) {
        AppLogger.info('📊 Gerando novas missões semanais para ${user.uid}');
        await generateWeeklyMissions(user);
        needsGeneration = true;
        generationType += 'semanais ';
      }

      if (needsGeneration) {
        AppLogger.info('✨ Missões $generationType geradas automaticamente');
      } else {
        AppLogger.debug('✅ Usuario já possui missões válidas');
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao garantir missões do usuário', error: e);
    }
  }

  // ================================================================================================
  // MÉTODOS EXISTENTES (mantidos inalterados)
  // ================================================================================================

  /// Carregar missões do usuário
  Future<void> loadUserMissions(UserModel user) async {
    if (_disposed) return;

    try {
      AppLogger.debug('🎯 Carregando missões para usuário ${user.uid}');

      state = state.copyWith(isLoading: true, error: null);

      // Carregar missões de cada tipo
      final dailyMissions = await _service.getUserDailyMissions(user.uid);
      final weeklyMissions = await _service.getUserWeeklyMissions(user.uid);
      final collaborativeMissions = await _service.getUserCollaborativeMissions(
        user.uid,
      );

      // Carregar progresso das missões
      final allMissionIds = [
        ...dailyMissions.map((m) => m.id),
        ...weeklyMissions.map((m) => m.id),
        ...collaborativeMissions.map((m) => m.id),
      ];

      final progresses = await _service.getUserMissionProgresses(
        user.uid,
        allMissionIds,
      );

      if (!_disposed) {
        state = state.copyWith(
          dailyMissions: dailyMissions,
          weeklyMissions: weeklyMissions,
          collaborativeMissions: collaborativeMissions,
          progresses: progresses,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
      }

      AppLogger.info('✅ Missões carregadas: ${state.allMissions.length} total');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao carregar missões', error: e);
      if (!_disposed) {
        state = state.copyWith(
          isLoading: false,
          error: 'Erro ao carregar missões: $e',
        );
      }
    }
  }

  /// Gerar novas missões diárias
  Future<void> generateDailyMissions(UserModel user) async {
    if (_disposed) return;

    try {
      AppLogger.debug('🔄 Gerando novas missões diárias para ${user.uid}');

      final newMissions = await _service.generateDailyMissions(user);

      if (!_disposed) {
        state = state.copyWith(
          dailyMissions: newMissions,
          lastUpdated: DateTime.now(),
        );
      }

      AppLogger.info('✅ Novas missões diárias geradas: ${newMissions.length}');
    } catch (e) {
      AppLogger.error('❌ Erro ao gerar missões diárias', error: e);
    }
  }

  /// Gerar novas missões semanais
  Future<void> generateWeeklyMissions(UserModel user) async {
    if (_disposed) return;

    try {
      AppLogger.debug('🔄 Gerando novas missões semanais para ${user.uid}');

      final newMissions = await _service.generateWeeklyMissions(user);

      if (!_disposed) {
        state = state.copyWith(
          weeklyMissions: newMissions,
          lastUpdated: DateTime.now(),
        );
      }

      AppLogger.info('✅ Novas missões semanais geradas: ${newMissions.length}');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao gerar missões semanais', error: e);
    }
  }

  /// Atualizar progresso de uma missão
  Future<void> updateMissionProgress(
    String missionId,
    int additionalProgress, {
    Map<String, dynamic>? metadata,
  }) async {
    if (_disposed) return;

    try {
      final user = _ref.read(authProvider).user;
      if (user == null) return;

      AppLogger.debug(
        '📈 Atualizando progresso da missão $missionId (+$additionalProgress)',
      );

      // Obter progresso atual
      final currentProgress = state.progresses[missionId];
      if (currentProgress == null) {
        AppLogger.warning('⚠️ Progresso não encontrado para missão $missionId');
        return;
      }

      // Calcular novo progresso
      final newProgress = currentProgress.updateProgress(additionalProgress);

      // Atualizar no Firestore
      await _service.updateMissionProgress(user.uid, newProgress);

      // Atualizar estado local
      if (!_disposed) {
        final updatedProgresses = Map<String, UserMissionProgress>.from(
          state.progresses,
        );
        updatedProgresses[missionId] = newProgress;

        state = state.copyWith(
          progresses: updatedProgresses,
          lastUpdated: DateTime.now(),
        );
      }

      // Se missão foi completada, notificar
      if (newProgress.isCompleted && !currentProgress.isCompleted) {
        await _onMissionCompleted(missionId, user);
      }

      AppLogger.info(
        '✅ Progresso atualizado: ${newProgress.currentProgress}/${newProgress.targetProgress}',
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao atualizar progresso da missão', error: e);
    }
  }

  /// Completar missão manualmente
  Future<void> completeMission(String missionId) async {
    if (_disposed) return;

    try {
      final user = _ref.read(authProvider).user;
      if (user == null) return;

      AppLogger.debug('✅ Completando missão $missionId');

      final currentProgress = state.progresses[missionId];
      if (currentProgress == null) return;

      final completedProgress = currentProgress.complete();

      await _service.updateMissionProgress(user.uid, completedProgress);

      if (!_disposed) {
        final updatedProgresses = Map<String, UserMissionProgress>.from(
          state.progresses,
        );
        updatedProgresses[missionId] = completedProgress;

        state = state.copyWith(
          progresses: updatedProgresses,
          lastUpdated: DateTime.now(),
        );
      }

      await _onMissionCompleted(missionId, user);

      AppLogger.info('🎉 Missão $missionId completada!');
    } catch (e) {
      AppLogger.error('❌ Erro ao completar missão', error: e);
    }
  }

  /// Callback para missão completada
  Future<void> _onMissionCompleted(String missionId, UserModel user) async {
    if (_disposed) return;

    try {
      // Encontrar a missão completada
      final mission = state.allMissions
          .where((m) => m.id == missionId)
          .firstOrNull;

      if (mission == null) {
        AppLogger.warning('⚠️ Missão completada não encontrada: $missionId');
        return;
      }

      AppLogger.info('🎉 Missão completada: ${mission.title}');

      // Conceder recompensas através do RewardsProvider
      // (se existir - implementado na próxima iteração)
      // final rewardsNotifier = _ref.read(rewardsProvider.notifier);
      // await rewardsNotifier.grantMissionRewards(mission, user);
    } catch (e) {
      AppLogger.error('❌ Erro ao processar missão completada', error: e);
    }
  }

  /// Limpar missões expiradas
  Future<void> cleanupExpiredMissions() async {
    if (_disposed) return;

    try {
      final user = _ref.read(authProvider).user;
      if (user == null) return;

      AppLogger.debug('🧹 Limpando missões expiradas');

      await _service.cleanupExpiredMissions(user.uid);

      // Filtrar missões expiradas do estado local
      final now = DateTime.now();
      final activeDailyMissions = state.dailyMissions
          .where((m) => m.expiresAt.isAfter(now))
          .toList();
      final activeWeeklyMissions = state.weeklyMissions
          .where((m) => m.expiresAt.isAfter(now))
          .toList();
      final activeCollaborativeMissions = state.collaborativeMissions
          .where((m) => m.expiresAt.isAfter(now))
          .toList();

      if (!_disposed) {
        state = state.copyWith(
          dailyMissions: activeDailyMissions,
          weeklyMissions: activeWeeklyMissions,
          collaborativeMissions: activeCollaborativeMissions,
        );
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao limpar missões expiradas', error: e);
    }
  }

  /// Recarregar todas as missões
  Future<void> refresh() async {
    if (_disposed) return;

    final user = _ref.read(authProvider).user;
    if (user != null) {
      await loadUserMissions(user);
      await _ensureUserHasMissions(
        user,
      ); // ✅ NOVO: Garantir missões após refresh
    }
  }

  /// Limpar estado (logout)
  void clear() {
    if (_disposed) return;
    state = const MissionsState();
  }

  @override
  void dispose() {
    _disposed = true; // ✅ NOVO: Prevenir operações após dispose
    super.dispose();
  }
}

// ================================================================================================
// PROVIDERS DERIVADOS (mantidos inalterados)
// ================================================================================================

/// Provider para missões diárias
final dailyMissionsProvider = Provider<List<MissionModel>>((ref) {
  return ref.watch(missionsProvider).dailyMissions;
});

/// Provider para missões semanais
final weeklyMissionsProvider = Provider<List<MissionModel>>((ref) {
  return ref.watch(missionsProvider).weeklyMissions;
});

/// Provider para missões ativas
final activeMissionsProvider = Provider<List<MissionModel>>((ref) {
  return ref.watch(missionsProvider).activeMissions;
});

/// Provider para missões completadas hoje
final completedDailyMissionsProvider = Provider<List<MissionModel>>((ref) {
  final missionsState = ref.watch(missionsProvider);
  return missionsState.dailyMissions
      .where((m) => missionsState.isMissionCompleted(m.id))
      .toList();
});

/// Provider para estatísticas de missões
final missionStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final missionsState = ref.watch(missionsProvider);

  return {
    'totalMissions': missionsState.allMissions.length,
    'completedMissions': missionsState.completedMissions.length,
    'dailyCompleted': missionsState.dailyMissionsCompleted,
    'weeklyCompleted': missionsState.weeklyMissionsCompleted,
    'completionRate': missionsState.allMissions.isEmpty
        ? 0.0
        : missionsState.completedMissions.length /
              missionsState.allMissions.length,
  };
});

/// Provider para verificar se uma missão específica está completa
final missionCompletedProvider = Provider.family<bool, String>((
  ref,
  missionId,
) {
  return ref.watch(missionsProvider).isMissionCompleted(missionId);
});

/// Provider para progresso de uma missão específica
final missionProgressProvider = Provider.family<double, String>((
  ref,
  missionId,
) {
  return ref.watch(missionsProvider).getMissionProgress(missionId);
});

/// ✅ NOVO: Provider para verificar se está inicializado
final missionsInitializedProvider = Provider<bool>((ref) {
  return ref.watch(missionsProvider).isInitialized;
});

/// ✅ NOVO: Provider para missões em destaque (primeiras 3 ativas)
final featuredMissionsProvider = Provider<List<MissionModel>>((ref) {
  final activeMissions = ref.watch(activeMissionsProvider);
  return activeMissions.take(3).toList();
});
