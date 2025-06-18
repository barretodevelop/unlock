// lib/features/missions/providers/missions_provider.dart
// Provider para gerenciamento de missões - Fase 3

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/features/missions/services/missions_service.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
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

  const MissionsState({
    this.dailyMissions = const [],
    this.weeklyMissions = const [],
    this.collaborativeMissions = const [],
    this.progresses = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  MissionsState copyWith({
    List<MissionModel>? dailyMissions,
    List<MissionModel>? weeklyMissions,
    List<MissionModel>? collaborativeMissions,
    Map<String, UserMissionProgress>? progresses,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
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

  MissionsNotifier(this._ref) : super(const MissionsState()) {
    _initialize();
  }

  /// Inicializar provider
  Future<void> _initialize() async {
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated && authState.user != null) {
      await loadUserMissions(authState.user!);
    }
  }

  /// Carregar missões do usuário
  Future<void> loadUserMissions(UserModel user) async {
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

      state = state.copyWith(
        dailyMissions: dailyMissions,
        weeklyMissions: weeklyMissions,
        collaborativeMissions: collaborativeMissions,
        progresses: progresses,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('✅ Missões carregadas: ${state.allMissions.length} total');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao carregar missões', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar missões: $e',
      );
    }
  }

  /// Gerar novas missões diárias
  Future<void> generateDailyMissions(UserModel user) async {
    try {
      AppLogger.debug('🔄 Gerando novas missões diárias para ${user.uid}');

      final newMissions = await _service.generateDailyMissions(user);

      state = state.copyWith(
        dailyMissions: newMissions,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('✅ Novas missões diárias geradas: ${newMissions.length}');
    } catch (e) {
      AppLogger.error('❌ Erro ao gerar missões diárias', error: e);
    }
  }

  /// Gerar novas missões semanais
  Future<void> generateWeeklyMissions(UserModel user) async {
    try {
      AppLogger.debug('🔄 Gerando novas missões semanais para ${user.uid}');

      final newMissions = await _service.generateWeeklyMissions(user);

      state = state.copyWith(
        weeklyMissions: newMissions,
        lastUpdated: DateTime.now(),
      );

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
      final updatedProgresses = Map<String, UserMissionProgress>.from(
        state.progresses,
      );
      updatedProgresses[missionId] = newProgress;

      state = state.copyWith(
        progresses: updatedProgresses,
        lastUpdated: DateTime.now(),
      );

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
    try {
      final user = _ref.read(authProvider).user;
      if (user == null) return;

      AppLogger.debug('✅ Completando missão $missionId');

      final currentProgress = state.progresses[missionId];
      if (currentProgress == null) return;

      final completedProgress = currentProgress.complete();

      await _service.updateMissionProgress(user.uid, completedProgress);

      final updatedProgresses = Map<String, UserMissionProgress>.from(
        state.progresses,
      );
      updatedProgresses[missionId] = completedProgress;

      state = state.copyWith(
        progresses: updatedProgresses,
        lastUpdated: DateTime.now(),
      );

      await _onMissionCompleted(missionId, user);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao completar missão', error: e);
    }
  }

  /// Callback quando missão é completada
  Future<void> _onMissionCompleted(String missionId, UserModel user) async {
    try {
      final mission = state.allMissions.firstWhere((m) => m.id == missionId);

      AppLogger.info('🎉 Missão completada: ${mission.title}');

      // Dar recompensas através do rewards provider
      await _ref
          .read(rewardsProvider.notifier)
          .grantMissionRewards(mission, user);

      // Analytics
      // await AnalyticsService.trackMissionCompleted(mission, user);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao processar conclusão da missão', error: e);
    }
  }

  /// Verificar se precisa gerar novas missões
  Future<void> checkForNewMissions(UserModel user) async {
    try {
      // Verificar missões diárias
      if (await _service.shouldGenerateNewDailyMissions(user.uid)) {
        await generateDailyMissions(user);
      }

      // Verificar missões semanais
      if (await _service.shouldGenerateNewWeeklyMissions(user.uid)) {
        await generateWeeklyMissions(user);
      }

      // Remover missões expiradas
      await _removeExpiredMissions();
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao verificar novas missões', error: e);
    }
  }

  /// Remover missões expiradas do estado
  Future<void> _removeExpiredMissions() async {
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

    state = state.copyWith(
      dailyMissions: activeDailyMissions,
      weeklyMissions: activeWeeklyMissions,
      collaborativeMissions: activeCollaborativeMissions,
    );
  }

  /// Recarregar todas as missões
  Future<void> refresh() async {
    final user = _ref.read(authProvider).user;
    if (user != null) {
      await loadUserMissions(user);
    }
  }

  /// Limpar estado (logout)
  void clear() {
    state = const MissionsState();
  }
}

// ================================================================================================
// PROVIDERS DERIVADOS
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

// // Placeholder para rewards provider (será implementado a seguir)
// final rewardsProvider = StateNotifierProvider<RewardsNotifier, RewardsState>((
//   ref,
// ) {
//   throw UnimplementedError(
//     'RewardsProvider será implementado no próximo artefato',
//   );
// });

// class RewardsNotifier extends StateNotifier<RewardsState> {
//   RewardsNotifier() : super(const RewardsState());

//   Future<void> grantMissionRewards(MissionModel mission, UserModel user) async {
//     // Implementação será feita no próximo artefato
//   }

//   Future<void> refresh() async {}
// }

// class RewardsState {
//   const RewardsState();
// }
