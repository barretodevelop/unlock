// lib/features/rewards/providers/rewards_provider.dart
// Provider para gerenciamento de recompensas - Fase 3 (Atualizado com Firestore e Missões)

import 'package:cloud_firestore/cloud_firestore.dart'; // Adicionado: Importação para FieldValue
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/gamification_constants.dart'; // Importar GamificationConstants
import 'package:unlock/core/utils/level_calculator.dart'; // Importado
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/missions/models/mission.dart'; // Correção: de MissionModel para Mission
import 'package:unlock/features/rewards/models/reward_model.dart'; // Importado RewardModel
import 'package:unlock/features/rewards/services/rewards_service.dart';
import 'package:unlock/models/game_model.dart'; // Importar GameModel
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
  late final RewardsService _service; // Injetado via Riverpod

  RewardsNotifier(this._ref) : super(const RewardsState()) {
    // Injeta RewardsService usando o provider dedicado
    _service = _ref.read(rewardsServiceProvider);
    _initialize();

    // Ouvir mudanças no AuthProvider para detectar level ups
    _ref.listen<AuthState>(authProvider, (previous, next) {
      final prevUser = previous?.user;
      final nextUser = next.user;

      if (prevUser != null &&
          nextUser != null &&
          nextUser.uid == prevUser.uid) {
        if (nextUser.level > prevUser.level) {
          AppLogger.info(
            '🎉 Usuário ${nextUser.uid} subiu para o nível ${nextUser.level}! (Detectado pelo RewardsNotifier)',
          );
          grantLevelUpRewards(nextUser.level, nextUser);
        }
      }
    });
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
      // Adicionado stackTrace ao log
      AppLogger.error('❌ Erro ao carregar recompensas', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar recompensas: $e',
      );
    }
  }

  /// Conceder recompensas de missão
  /// Este método é chamado quando uma missão é CONCLUÍDA, mas ainda não RESGATADA.
  /// Ele cria os objetos RewardModel e os registra como PENDENTES no Firestore.
  Future<void> grantMissionRewards(Mission mission, UserModel user) async {
    try {
      AppLogger.debug('🎁 Concedendo recompensas da missão: ${mission.title}');

      final rewards = <RewardModel>[];

      // Criar recompensas baseadas na estrutura MissionReward da missão
      if (mission.reward.xp > 0) {
        // Correção: Usar mission.reward.xp
        rewards.add(
          RewardModel.xp(
            id: '${mission.id}_xp_${DateTime.now().millisecondsSinceEpoch}',
            amount: mission.reward.xp, // Correção: Usar mission.reward.xp
            source: RewardSource.mission,
            description: '+${mission.reward.xp} XP de ${mission.title}',
            metadata: {'missionId': mission.id},
          ),
        );
      }

      if (mission.reward.coins > 0) {
        // Correção: Usar mission.reward.coins
        rewards.add(
          RewardModel.coins(
            id: '${mission.id}_coins_${DateTime.now().millisecondsSinceEpoch}',
            amount: mission.reward.coins, // Correção: Usar mission.reward.coins
            source: RewardSource.mission,
            description: '+${mission.reward.coins} Coins de ${mission.title}',
            metadata: {'missionId': mission.id},
          ),
        );
      }

      if (mission.reward.gems > 0) {
        // Correção: Usar mission.reward.gems
        rewards.add(
          RewardModel.gems(
            id: '${mission.id}_gems_${DateTime.now().millisecondsSinceEpoch}',
            amount: mission.reward.gems, // Correção: Usar mission.reward.gems
            source: RewardSource.mission,
            description: '+${mission.reward.gems} Gems de ${mission.title}',
            metadata: {'missionId': mission.id},
          ),
        );
      }

      // Salvar recompensas no Firestore como pendentes
      await _service.grantRewards(user.uid, rewards);

      // Atualizar estado local do provedor de recompensas
      final updatedPending = [...state.pendingRewards, ...rewards];
      state = state.copyWith(
        pendingRewards: updatedPending,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('✅ Recompensas concedidas: ${rewards.length} itens');
    } catch (e, stackTrace) {
      // Adicionado stackTrace ao log
      AppLogger.error('❌ Erro ao conceder recompensas da missão', error: e);
    }
  }

  /// Conceder recompensas de level up
  Future<void> grantLevelUpRewards(int newLevel, UserModel user) async {
    try {
      AppLogger.debug('🆙 Concedendo recompensas de level up: nível $newLevel');

      final levelRewards = LevelCalculator.getLevelUpRewards(newLevel);
      if (levelRewards == null) {
        AppLogger.info(
          '⚠️ Nenhuma recompensa definida para o nível $newLevel.',
        );
        return;
      }

      final rewards = <RewardModel>[];

      // XP bonus (se aplicável)
      if (levelRewards['xp'] != null && levelRewards['xp']! > 0) {
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
      if (levelRewards['coins'] != null && levelRewards['coins']! > 0) {
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
      if (levelRewards['gems'] != null && levelRewards['gems']! > 0) {
        rewards.add(
          RewardModel.gems(
            id: 'levelup_${newLevel}_gems_${DateTime.now().millisecondsSinceEpoch}',
            amount: levelRewards['gems']!,
            source: RewardSource.levelUp,
            description: 'Bônus de Gems por atingir nível $newLevel',
          ),
        );
      }

      // Título novo (sempre adicionado se houver um título para o nível)
      final newTitle = LevelCalculator.getUserTitle(newLevel);
      // Correção: Acessa levelTitles diretamente de GamificationConstants
      if (newTitle != 'Viajante' ||
          GamificationConstants.levelTitles.containsKey(newLevel)) {
        rewards.add(
          RewardModel.title(
            id: 'levelup_${newLevel}_title_${DateTime.now().millisecondsSinceEpoch}',
            titleId: 'level_$newLevel',
            source: RewardSource.levelUp,
            description: 'Novo título desbloqueado: $newTitle',
            metadata: {'titleName': newTitle, 'level': newLevel},
          ),
        );
      }

      if (rewards.isEmpty) {
        AppLogger.info('⚠️ Nenhuma recompensa gerada para o nível $newLevel.');
        return;
      }

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
      // Adicionado stackTrace ao log
      AppLogger.error('❌ Erro ao conceder recompensas de level up', error: e);
    }
  }

  /// Conceder recompensas de login diário
  Future<void> grantDailyLoginRewards(int streakDays, UserModel user) async {
    try {
      AppLogger.debug(
        '📅 Concedendo recompensas de login diário: $streakDays dias',
      );

      final bonusCoins = LevelCalculator.calculateDailyLoginBonus(streakDays);
      if (bonusCoins <= 0) {
        AppLogger.info(
          '⚠️ Bônus de login diário não concedido (0 ou menos coins).',
        );
        return;
      }

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
      // Adicionado stackTrace ao log
      AppLogger.error(
        '❌ Erro ao conceder recompensas de login diário',
        error: e,
      );
    }
  }

  /// Concede e aplica imediatamente as recompensas de um mini-game ao usuário.
  ///
  /// Este método é chamado quando um mini-game é CONCLUÍDO. Ele atualiza
  /// diretamente os stats (XP, coins, gems) do usuário no Firestore e no estado
  /// local do app, e então registra a transação como uma recompensa já resgatada
  /// no histórico do usuário.
  Future<void> grantGameRewards(
    GameModel game,
    UserModel user, {
    int xpAmount = 0,
    bool hasWon = false,
    int coinsAmount = 0,
    int gemsAmount = 0,
  }) async {
    try {
      AppLogger.debug(
        '🎮 Concedendo e aplicando recompensas do jogo: ${game.name}',
      );

      if (xpAmount <= 0 && coinsAmount <= 0 && gemsAmount <= 0) {
        AppLogger.info(
          '⚠️ Nenhuma recompensa a ser concedida para o jogo ${game.name}.',
        );
        return;
      }

      // 1. Atualizar os stats do usuário no Firestore de forma atômica
      final userUpdates = <String, dynamic>{};
      if (xpAmount > 0) userUpdates['xp'] = FieldValue.increment(xpAmount);
      if (coinsAmount > 0)
        userUpdates['coins'] = FieldValue.increment(coinsAmount);
      if (gemsAmount > 0)
        userUpdates['gems'] = FieldValue.increment(gemsAmount);

      await _service.updateUserStats(user.uid, userUpdates);
      AppLogger.info(
        '✅ Stats do usuário atualizados no Firestore: $userUpdates',
      );

      // 2. Atualizar o estado local do usuário no AuthProvider para UI imediata
      _ref
          .read(authProvider.notifier)
          .addRewardsToCurrentUser(xpAmount, coinsAmount, gemsAmount);
      AppLogger.info('✅ UserModel local atualizado no AuthProvider.');

      // 3. Registrar as recompensas como já resgatadas para o histórico
      final now = DateTime.now();
      final rewardsToRecord = <RewardModel>[];

      if (xpAmount > 0) {
        rewardsToRecord.add(
          RewardModel.xp(
            id: 'game_${game.id}_xp_${now.millisecondsSinceEpoch}',
            amount: xpAmount,
            source: RewardSource.minigame, // Usar RewardSource.minigame
            description: '+$xpAmount XP de ${game.name}',
            metadata: {'gameId': game.id},
          ).claim(), // .claim() marca como resgatada
        );
      }
      if (coinsAmount > 0) {
        rewardsToRecord.add(
          RewardModel.coins(
            id: 'game_${game.id}_coins_${now.millisecondsSinceEpoch}',
            amount: coinsAmount,
            source: RewardSource.minigame,
            description: '+$coinsAmount Coins de ${game.name}',
            metadata: {'gameId': game.id},
          ).claim(),
        );
      }
      if (gemsAmount > 0) {
        rewardsToRecord.add(
          RewardModel.gems(
            id: 'game_${game.id}_gems_${now.millisecondsSinceEpoch}',
            amount: gemsAmount,
            source: RewardSource.minigame,
            description: '+$gemsAmount Gems de ${game.name}',
            metadata: {'gameId': game.id},
          ).claim(),
        );
      }

      // O método grantRewards do service salva os rewards na subcollection.
      // Como eles já estão marcados como 'claimed', eles irão para o histórico.
      await _service.grantRewards(user.uid, rewardsToRecord);
      AppLogger.info(
        '✅ Recompensas do jogo registradas no histórico: ${rewardsToRecord.length} itens',
      );

      // Atualizar o estado local do RewardsProvider (opcional, mas bom para consistência)
      final updatedClaimed = [...state.claimedRewards, ...rewardsToRecord];
      state = state.copyWith(
        claimedRewards: updatedClaimed,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao conceder e aplicar recompensas do jogo',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Coletar uma recompensa específica
  Future<void> claimReward(String rewardId) async {
    try {
      final user = _ref.read(authProvider).user;
      if (user == null) {
        AppLogger.warning(
          '⚠️ Tentativa de coletar recompensa sem usuário logado.',
        );
        return;
      }

      AppLogger.debug('🎁 Coletando recompensa: $rewardId');

      // Encontrar recompensa
      final rewardIndex = state.pendingRewards.indexWhere(
        (r) => r.id == rewardId,
      );
      if (rewardIndex == -1) {
        AppLogger.warning(
          '⚠️ Recompensa $rewardId não encontrada entre as pendentes.',
        );
        return;
      }

      final reward = state.pendingRewards[rewardIndex];
      // Marca a recompensa como coletada localmente
      final claimedReward = reward.claim();

      // Atualizar no Firestore
      await _service.claimReward(user.uid, claimedReward);

      // Aplicar efeitos econômicos da recompensa
      Map<String, dynamic> userUpdates = {};
      int xpGained = 0;
      int coinsGained = 0;
      int gemsGained = 0;

      if (reward.type == RewardType.xp && reward.amount > 0) {
        userUpdates['xp'] = FieldValue.increment(reward.amount);
        xpGained = reward.amount;
      }
      if (reward.type == RewardType.coins && reward.amount > 0) {
        userUpdates['coins'] = FieldValue.increment(reward.amount);
        coinsGained = reward.amount;
      }
      if (reward.type == RewardType.gems && reward.amount > 0) {
        userUpdates['gems'] = FieldValue.increment(reward.amount);
        gemsGained = reward.amount;
      }

      if (userUpdates.isNotEmpty) {
        await _service.updateUserStats(user.uid, userUpdates);
        _ref
            .read(authProvider.notifier)
            .addRewardsToCurrentUser(xpGained, coinsGained, gemsGained);
      }

      // Se houver recompensas de tipo diferente (achievement, item, title, boost)
      // A lógica para estas deve ser tratada aqui ou por serviços dedicados.
      // Por simplicidade, vamos chamar métodos mockados para os tipos não-econômicos.
      if (reward.type == RewardType.achievement &&
          reward.achievementId != null) {
        await _unlockAchievement(user, reward.achievementId!);
      } else if (reward.type == RewardType.item && reward.itemId != null) {
        await _unlockItem(user, reward.itemId!);
      } else if (reward.type == RewardType.title && reward.titleId != null) {
        await _unlockTitle(user, reward.titleId!);
      } else if (reward.type == RewardType.boost) {
        await _applyBoost(user, reward);
      }

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
      // Adicionado stackTrace ao log
      AppLogger.error(
        '❌ Erro ao coletar recompensa',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Calcula o bônus de moedas para o login diário.
  /// Este método é um wrapper para a lógica em LevelCalculator/GamificationConstants.
  int calculateDailyLoginBonus(int streakDays) {
    return LevelCalculator.calculateDailyLoginBonus(streakDays);
  }

  /// Registra uma recompensa de moeda que foi concedida e coletada diretamente.
  /// Usado para bônus de login diário que não passam pelo fluxo de "pendente".
  Future<void> recordDirectlyClaimedCoinReward({
    required String userId,
    required int amount,
    required RewardSource source,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (amount <= 0) return;

    final now = DateTime.now();
    final reward = RewardModel.coins(
      id: '${source.value}_${now.millisecondsSinceEpoch}_${userId.substring(0, 5)}', // ID único
      amount: amount,
      source: source,
      description: description ?? 'Recompensa direta de ${source.displayName}',
      metadata: metadata ?? {},
    ).claim(); // .claim() marca como resgatada e define createdAt/claimedAt

    try {
      await _service.recordClaimedReward(
        userId,
        reward,
      ); // Novo método no RewardsService
      // Atualizar estado local (claimedRewards e totalEarned)
      final updatedClaimed = [...state.claimedRewards, reward];
      state = state.copyWith(
        claimedRewards: updatedClaimed,
        lastUpdated: now,
        totalEarned: await _service.getTotalEarned(userId),
      ); // Recalcula totalEarned
      AppLogger.info(
        '✅ Recompensa direta registrada: ${reward.formattedAmount}',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao registrar recompensa direta',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Resgata todas as recompensas pendentes associadas a uma missionId específica.
  /// Chamado pelo MissionsNotifier quando uma missão é marcada como resgatada pelo usuário.
  Future<void> claimRewardsForCompletedMission(
    String missionId,
    String userId,
  ) async {
    try {
      AppLogger.debug(
        '🎁 Tentando resgatar recompensas para a missão concluída: $missionId para o usuário $userId',
      );

      // Filtra as recompensas pendentes que correspondem à missionId e são do tipo missão.
      // É importante verificar a source para não resgatar acidentalmente outras recompensas com metadata similar.
      final rewardsToClaim = state.pendingRewards
          .where(
            (r) =>
                r.metadata['missionId'] == missionId &&
                r.source == RewardSource.mission,
          )
          .toList();

      if (rewardsToClaim.isEmpty) {
        AppLogger.info(
          '🤔 Nenhuma recompensa pendente encontrada para a missão $missionId ou já foram resgatadas.',
        );
        return;
      }

      AppLogger.info(
        '✨ Resgatando ${rewardsToClaim.length} recompensas pendentes para a missão $missionId.',
      );
      for (final reward in rewardsToClaim) {
        // O método claimReward já lida com a atualização do estado, persistência e aplicação dos efeitos.
        await claimReward(reward.id);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao resgatar recompensas para a missão $missionId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Coletar todas as recompensas pendentes
  Future<void> claimAllRewards() async {
    try {
      final user = _ref.read(authProvider).user;
      if (user == null) {
        AppLogger.warning(
          '⚠️ Tentativa de coletar todas as recompensas sem usuário logado.',
        );
        return;
      }

      if (state.pendingRewards.isEmpty) {
        AppLogger.info('ℹ️ Nenhuma recompensa pendente para coletar.');
        return;
      }

      AppLogger.debug(
        '🎁 Coletando todas as recompensas: ${state.pendingRewards.length}',
      );

      final claimedRewardsBatch = <RewardModel>[];

      Map<String, dynamic> totalUserUpdates = {};
      int totalXPGained = 0;
      int totalCoinsGained = 0;
      int totalGemsGained = 0;

      for (final reward in state.pendingRewards) {
        final claimedReward = reward
            .claim(); // Marca a recompensa como coletada localmente
        await _service.claimReward(
          user.uid,
          claimedReward,
        ); // Atualiza no Firestore

        // Acumula efeitos econômicos
        if (claimedReward.type == RewardType.xp && claimedReward.amount > 0) {
          totalXPGained += claimedReward.amount;
        }
        if (claimedReward.type == RewardType.coins &&
            claimedReward.amount > 0) {
          totalCoinsGained += claimedReward.amount;
        }
        if (claimedReward.type == RewardType.gems && claimedReward.amount > 0) {
          totalGemsGained += claimedReward.amount;
        }

        // Lógica para tipos não-econômicos (conquistas, itens, títulos, boosts)
        if (claimedReward.type == RewardType.achievement &&
            claimedReward.achievementId != null) {
          await _unlockAchievement(user, claimedReward.achievementId!);
        } else if (claimedReward.type == RewardType.item &&
            claimedReward.itemId != null) {
          await _unlockItem(user, claimedReward.itemId!);
        } else if (claimedReward.type == RewardType.title &&
            claimedReward.titleId != null) {
          await _unlockTitle(user, claimedReward.titleId!);
        } else if (claimedReward.type == RewardType.boost) {
          await _applyBoost(user, claimedReward);
        }

        claimedRewardsBatch.add(claimedReward);
      }

      // Construir o mapa totalUserUpdates APÓS o loop com os totais acumulados
      if (totalXPGained > 0) {
        totalUserUpdates['xp'] = FieldValue.increment(totalXPGained);
      }
      if (totalCoinsGained > 0) {
        totalUserUpdates['coins'] = FieldValue.increment(totalCoinsGained);
      }
      if (totalGemsGained > 0) {
        totalUserUpdates['gems'] = FieldValue.increment(totalGemsGained);
      }

      // Aplicar todas as atualizações econômicas de uma vez
      if (totalUserUpdates.isNotEmpty) {
        await _service.updateUserStats(user.uid, totalUserUpdates);
        _ref
            .read(authProvider.notifier)
            .addRewardsToCurrentUser(
              totalXPGained,
              totalCoinsGained,
              totalGemsGained,
            );
      }

      // Atualizar estado local após processar todas as recompensas
      final updatedClaimed = [...state.claimedRewards, ...claimedRewardsBatch];
      state = state.copyWith(
        pendingRewards: [], // Limpa todas as pendentes
        claimedRewards: updatedClaimed,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info(
        '✅ Todas as recompensas coletadas: ${claimedRewardsBatch.length}',
      );
    } catch (e, stackTrace) {
      // Adicionado stackTrace ao log
      AppLogger.error(
        '❌ Erro ao coletar todas as recompensas',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Desbloquear conquista (lógica futura)
  Future<void> _unlockAchievement(UserModel user, String achievementId) async {
    // Implementação futura - adicionar conquista ao perfil do usuário
    // Ex: _userAchievementsService.addAchievement(user.uid, achievementId);
    AppLogger.info(
      '🏆 Conquista desbloqueada: $achievementId para ${user.uid}',
    );
    // Pode disparar um pop-up de notificação de conquista aqui
  }

  /// Desbloquear item (lógica futura)
  Future<void> _unlockItem(UserModel user, String itemId) async {
    // Implementação futura - adicionar item ao inventário
    // Ex: _userInventoryService.addItem(user.uid, itemId);
    AppLogger.info('🎁 Item desbloqueado: $itemId para ${user.uid}');
  }

  /// Desbloquear título (lógica futura)
  Future<void> _unlockTitle(UserModel user, String titleId) async {
    // Implementação futura - adicionar título disponível
    // Ex: _userProfileService.addTitle(user.uid, titleId);
    AppLogger.info('🏅 Título desbloqueado: $titleId para ${user.uid}');
  }

  /// Aplicar boost (lógica futura)
  Future<void> _applyBoost(UserModel user, RewardModel reward) async {
    // Implementação futura - aplicar boost temporário
    // Ex: _boostService.activateBoost(user.uid, reward.id, reward.amount);
    AppLogger.info('🚀 Boost ${reward.id} aplicado para ${user.uid}');
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
