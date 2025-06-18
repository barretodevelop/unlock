// lib/features/rewards/providers/rewards_provider.dart
// Provider para gerenciamento de recompensas - Fase 3

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/level_calculator.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/features/rewards/models/reward_model.dart';
import 'package:unlock/features/rewards/services/rewards_service.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Estado das recompensas do usuário
class RewardsState {
  final List<RewardModel> pendingRewards;
  final List<RewardModel> claimedRewards;
  final Map<String, int> totalEarned; // xp, coins, gems
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const RewardsState({
    this.pendingRewards = const [],
    this.claimedRewards = const [],
    this.totalEarned = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  RewardsState copyWith({
    List<RewardModel>? pendingRewards,
    List<RewardModel>? claimedRewards,
    Map<String, int>? totalEarned,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return RewardsState(
      pendingRewards: pendingRewards ?? this.pendingRewards,
      claimedRewards: claimedRewards ?? this.claimedRewards,
      totalEarned: totalEarned ?? this.totalEarned,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Todas as recompensas
  List<RewardModel> get allRewards => [...pendingRewards, ...claimedRewards];

  /// Contar recompensas pendentes por tipo
  int getPendingCount(RewardType type) =>
      pendingRewards.where((r) => r.type == type).length;

  /// Calcular valor total pendente por tipo
  int getPendingValue(RewardType type) => pendingRewards
      .where((r) => r.type == type)
      .fold(0, (sum, r) => sum + r.amount);

  /// Verificar se há recompensas pendentes
  bool get hasPendingRewards => pendingRewards.isNotEmpty;
}

/// Provider principal de recompensas
final rewardsProvider = StateNotifierProvider<RewardsNotifier, RewardsState>((
  ref,
) {
  return RewardsNotifier(ref);
});

/// Notifier para gerenciar estado das recompensas
class RewardsNotifier extends StateNotifier<RewardsState> {
  final Ref _ref;
  final RewardsService _service = RewardsService();

  RewardsNotifier(this._ref) : super(const RewardsState()) {
    _initialize();
  }

  /// Inicializar provider
  Future<void> _initialize() async {
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated && authState.user != null) {
      await loadUserRewards(authState.user!.uid);
    }
  }

  /// Carregar recompensas do usuário
  Future<void> loadUserRewards(String userId) async {
    try {
      AppLogger.debug('🏆 Carregando recompensas para usuário $userId');

      state = state.copyWith(isLoading: true, error: null);

      final pendingRewards = await _service.getPendingRewards(userId);
      final claimedRewards = await _service.getClaimedRewards(userId);
      final totalEarned = await _service.getTotalEarned(userId);

      state = state.copyWith(
        pendingRewards: pendingRewards,
        claimedRewards: claimedRewards,
        totalEarned: totalEarned,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info(
        '✅ Recompensas carregadas: ${pendingRewards.length} pendentes',
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao carregar recompensas', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar recompensas: $e',
      );
    }
  }

  /// Conceder recompensas de missão
  Future<void> grantMissionRewards(MissionModel mission, UserModel user) async {
    try {
      AppLogger.debug('🎁 Concedendo recompensas da missão: ${mission.title}');

      final rewards = <RewardModel>[];

      // Criar recompensas baseadas na missão
      if (mission.xpReward > 0) {
        rewards.add(
          RewardModel.xp(
            id: '${mission.id}_xp_${DateTime.now().millisecondsSinceEpoch}',
            amount: mission.xpReward,
            source: RewardSource.mission,
            description: '+${mission.xpReward} XP de ${mission.title}',
            metadata: {'missionId': mission.id},
          ),
        );
      }

      if (mission.coinsReward > 0) {
        rewards.add(
          RewardModel.coins(
            id: '${mission.id}_coins_${DateTime.now().millisecondsSinceEpoch}',
            amount: mission.coinsReward,
            source: RewardSource.mission,
            description: '+${mission.coinsReward} Coins de ${mission.title}',
            metadata: {'missionId': mission.id},
          ),
        );
      }

      if (mission.gemsReward > 0) {
        rewards.add(
          RewardModel.gems(
            id: '${mission.id}_gems_${DateTime.now().millisecondsSinceEpoch}',
            amount: mission.gemsReward,
            source: RewardSource.mission,
            description: '+${mission.gemsReward} Gems de ${mission.title}',
            metadata: {'missionId': mission.id},
          ),
        );
      }

      // Salvar recompensas
      await _service.grantRewards(user.uid, rewards);

      // Atualizar estado local
      final updatedPending = [...state.pendingRewards, ...rewards];
      state = state.copyWith(
        pendingRewards: updatedPending,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('✅ Recompensas concedidas: ${rewards.length} itens');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao conceder recompensas da missão',
        error :e ,
      );
    }
  }

  /// Conceder recompensas de level up
  Future<void> grantLevelUpRewards(int newLevel, UserModel user) async {
    try {
      AppLogger.debug('🆙 Concedendo recompensas de level up: nível $newLevel');

      final levelRewards = LevelCalculator.getLevelUpRewards(newLevel);
      if (levelRewards == null) return;

      final rewards = <RewardModel>[];

      // XP bonus (se aplicável)
      if (levelRewards['xp'] != null) {
        rewards.add(
          RewardModel.xp(
            id: 'levelup_${newLevel}_xp_${DateTime.now().millisecondsSinceEpoch}',
            amount: levelRewards['xp']!,
            source: RewardSource.levelUp,
            description: 'Bônus de XP por atingir nível $newLevel',
          ),
        );
      }

      // Coins bonus
      if (levelRewards['coins'] != null) {
        rewards.add(
          RewardModel.coins(
            id: 'levelup_${newLevel}_coins_${DateTime.now().millisecondsSinceEpoch}',
            amount: levelRewards['coins']!,
            source: RewardSource.levelUp,
            description: 'Bônus de Coins por atingir nível $newLevel',
          ),
        );
      }

      // Gems bonus
      if (levelRewards['gems'] != null) {
        rewards.add(
          RewardModel.gems(
            id: 'levelup_${newLevel}_gems_${DateTime.now().millisecondsSinceEpoch}',
            amount: levelRewards['gems']!,
            source: RewardSource.levelUp,
            description: 'Bônus de Gems por atingir nível $newLevel',
          ),
        );
      }

      // Título novo
      final newTitle = LevelCalculator.getUserTitle(newLevel);
      rewards.add(
        RewardModel.title(
          id: 'levelup_${newLevel}_title_${DateTime.now().millisecondsSinceEpoch}',
          titleId: 'level_$newLevel',
          source: RewardSource.levelUp,
          description: 'Novo título desbloqueado: $newTitle',
          metadata: {'titleName': newTitle, 'level': newLevel},
        ),
      );

      await _service.grantRewards(user.uid, rewards);

      final updatedPending = [...state.pendingRewards, ...rewards];
      state = state.copyWith(
        pendingRewards: updatedPending,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info(
        '✅ Recompensas de level up concedidas para nível $newLevel',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao conceder recompensas de level up',
        error :e 
      );
    }
  }

  /// Conceder recompensas de login diário
  Future<void> grantDailyLoginRewards(int streakDays, UserModel user) async {
    try {
      AppLogger.debug(
        '📅 Concedendo recompensas de login diário: $streakDays dias',
      );

      final bonusCoins = LevelCalculator.calculateDailyLoginBonus(streakDays);
      if (bonusCoins <= 0) return;

      final reward = RewardModel.coins(
        id: 'daily_login_${DateTime.now().millisecondsSinceEpoch}',
        amount: bonusCoins,
        source: RewardSource.dailyLogin,
        description: 'Bônus de login diário ($streakDays dias seguidos)',
        metadata: {'streakDays': streakDays},
      );

      await _service.grantRewards(user.uid, [reward]);

      final updatedPending = [...state.pendingRewards, reward];
      state = state.copyWith(
        pendingRewards: updatedPending,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info(
        '✅ Recompensa de login diário concedida: +$bonusCoins coins',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao conceder recompensas de login diário',
        error:e ,
      );
    }
  }

  /// Coletar uma recompensa específica
  Future<void> claimReward(String rewardId) async {
    try {
      final user = _ref.read(authProvider).user;
      if (user == null) return;

      AppLogger.debug('🎁 Coletando recompensa: $rewardId');

      // Encontrar recompensa
      final rewardIndex = state.pendingRewards.indexWhere(
        (r) => r.id == rewardId,
      );
      if (rewardIndex == -1) return;

      final reward = state.pendingRewards[rewardIndex];
      final claimedReward = reward.claim();

      // Atualizar no Firestore
      await _service.claimReward(user.uid, claimedReward);

      // Aplicar recompensa ao usuário
      await _applyRewardToUser(claimedReward, user);

      // Atualizar estado local
      final updatedPending = List<RewardModel>.from(state.pendingRewards)
        ..removeAt(rewardIndex);
      final updatedClaimed = [...state.claimedRewards, claimedReward];

      state = state.copyWith(
        pendingRewards: updatedPending,
        claimedRewards: updatedClaimed,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('✅ Recompensa coletada: ${reward.formattedAmount}');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao coletar recompensa', error: e);
    }
  }

  /// Coletar todas as recompensas pendentes
  Future<void> claimAllRewards() async {
    try {
      final user = _ref.read(authProvider).user;
      if (user == null) return;

      if (state.pendingRewards.isEmpty) return;

      AppLogger.debug(
        '🎁 Coletando todas as recompensas: ${state.pendingRewards.length}',
      );

      final claimedRewards = <RewardModel>[];

      for (final reward in state.pendingRewards) {
        final claimedReward = reward.claim();
        await _service.claimReward(user.uid, claimedReward);
        await _applyRewardToUser(claimedReward, user);
        claimedRewards.add(claimedReward);
      }

      // Atualizar estado
      final updatedClaimed = [...state.claimedRewards, ...claimedRewards];
      state = state.copyWith(
        pendingRewards: [],
        claimedRewards: updatedClaimed,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info(
        '✅ Todas as recompensas coletadas: ${claimedRewards.length}',
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao coletar todas as recompensas', error: e);
    }
  }

  /// Aplicar recompensa aos dados do usuário
  Future<void> _applyRewardToUser(RewardModel reward, UserModel user) async {
    try {
      switch (reward.type) {
        case RewardType.xp:
          await _updateUserXP(user, reward.amount);
          break;
        case RewardType.coins:
          await _updateUserCoins(user, reward.amount);
          break;
        case RewardType.gems:
          await _updateUserGems(user, reward.amount);
          break;
        case RewardType.achievement:
          await _unlockAchievement(user, reward.achievementId!);
          break;
        case RewardType.item:
          await _unlockItem(user, reward.itemId!);
          break;
        case RewardType.title:
          await _unlockTitle(user, reward.titleId!);
          break;
        case RewardType.boost:
          await _applyBoost(user, reward);
          break;
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao aplicar recompensa ao usuário', error: e);
    }
  }

  /// Atualizar XP do usuário (com verificação de level up)
  Future<void> _updateUserXP(UserModel user, int xpAmount) async {
    final oldXP = user.xp;
    final newXP = oldXP + xpAmount;

    // Verificar se subiu de nível
    final hasLeveledUp = LevelCalculator.hasLeveledUp(oldXP, newXP);
    final newLevel = LevelCalculator.calculateLevel(newXP);

    // Atualizar usuário no Firestore
    await _service.updateUserStats(user.uid, {
      'xp': newXP,
      'level': newLevel,
      'lastXPGain': DateTime.now().toIso8601String(),
    });

    // Se subiu de nível, conceder recompensas especiais
    if (hasLeveledUp) {
      await grantLevelUpRewards(newLevel, user);
    }
  }

  /// Atualizar coins do usuário
  Future<void> _updateUserCoins(UserModel user, int coinsAmount) async {
    final newCoins = user.coins + coinsAmount;

    await _service.updateUserStats(user.uid, {
      'coins': newCoins,
      'lastCoinsGain': DateTime.now().toIso8601String(),
    });
  }

  /// Atualizar gems do usuário
  Future<void> _updateUserGems(UserModel user, int gemsAmount) async {
    final newGems = user.gems + gemsAmount;

    await _service.updateUserStats(user.uid, {
      'gems': newGems,
      'lastGemsGain': DateTime.now().toIso8601String(),
    });
  }

  /// Desbloquear conquista
  Future<void> _unlockAchievement(UserModel user, String achievementId) async {
    // Implementação futura - adicionar conquista ao perfil do usuário
    AppLogger.info('🏆 Conquista desbloqueada: $achievementId');
  }

  /// Desbloquear item
  Future<void> _unlockItem(UserModel user, String itemId) async {
    // Implementação futura - adicionar item ao inventário
    AppLogger.info('🎁 Item desbloqueado: $itemId');
  }

  /// Desbloquear título
  Future<void> _unlockTitle(UserModel user, String titleId) async {
    // Implementação futura - adicionar título disponível
    AppLogger.info('🏅 Título desbloqueado: $titleId');
  }

  /// Aplicar boost
  Future<void> _applyBoost(UserModel user, RewardModel reward) async {
    // Implementação futura - aplicar boost temporário
    AppLogger.info('🚀 Boost aplicado');
  }

  /// Recarregar recompensas
  Future<void> refresh() async {
    final user = _ref.read(authProvider).user;
    if (user != null) {
      await loadUserRewards(user.uid);
    }
  }

  /// Limpar estado (logout)
  void clear() {
    state = const RewardsState();
  }
}

// ================================================================================================
// PROVIDERS DERIVADOS
// ================================================================================================

/// Provider para recompensas pendentes
final pendingRewardsProvider = Provider<List<RewardModel>>((ref) {
  return ref.watch(rewardsProvider).pendingRewards;
});

/// Provider para verificar se há recompensas pendentes
final hasPendingRewardsProvider = Provider<bool>((ref) {
  return ref.watch(rewardsProvider).hasPendingRewards;
});

/// Provider para contagem de recompensas pendentes por tipo
final pendingRewardsCountProvider = Provider.family<int, RewardType>((
  ref,
  type,
) {
  return ref.watch(rewardsProvider).getPendingCount(type);
});

/// Provider para valor total pendente por tipo
final pendingRewardsValueProvider = Provider.family<int, RewardType>((
  ref,
  type,
) {
  return ref.watch(rewardsProvider).getPendingValue(type);
});
