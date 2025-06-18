// lib/features/home/providers/home_provider.dart
// Provider para gerenciamento da tela home - Fase 3

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/level_calculator.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Estado da tela home
class HomeState {
  final UserModel? user;
  final Map<String, dynamic> userStats;
  final List<String> featuredMissions;
  final Map<String, dynamic> quickActions;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const HomeState({
    this.user,
    this.userStats = const {},
    this.featuredMissions = const [],
    this.quickActions = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  HomeState copyWith({
    UserModel? user,
    Map<String, dynamic>? userStats,
    List<String>? featuredMissions,
    Map<String, dynamic>? quickActions,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return HomeState(
      user: user ?? this.user,
      userStats: userStats ?? this.userStats,
      featuredMissions: featuredMissions ?? this.featuredMissions,
      quickActions: quickActions ?? this.quickActions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Obter nível atual do usuário
  int get userLevel => user?.level ?? 1;

  /// Obter XP atual do usuário
  int get userXP => user?.xp ?? 0;

  /// Obter coins do usuário
  int get userCoins => user?.coins ?? 0;

  /// Obter gems do usuário
  int get userGems => user?.gems ?? 0;

  /// Obter progresso no nível atual (0.0 - 1.0)
  double get levelProgress => userStats['levelProgress'] ?? 0.0;

  /// Obter XP necessário para próximo nível
  int get xpToNextLevel => userStats['xpToNextLevel'] ?? 0;

  /// Obter título do usuário
  String get userTitle => userStats['title'] ?? 'Novato';

  /// Verificar se pode subir de nível
  bool get canLevelUp => xpToNextLevel <= 0 && userLevel < 100;
}

/// Provider principal da home
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref);
});

/// Notifier para gerenciar estado da home
class HomeNotifier extends StateNotifier<HomeState> {
  final Ref _ref;

  HomeNotifier(this._ref) : super(const HomeState()) {
    _initialize();
  }

  /// Inicializar provider
  Future<void> _initialize() async {
    // Escutar mudanças no auth provider
    _ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated && next.user != null) {
        _updateUser(next.user!);
      } else {
        clear();
      }
    });

    // Se já tem usuário autenticado, inicializar
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated && authState.user != null) {
      _updateUser(authState.user!);
    }
  }

  /// Atualizar dados do usuário
  void _updateUser(UserModel user) {
    try {
      AppLogger.debug('🏠 Atualizando dados da home para usuário ${user.uid}');

      // Calcular estatísticas do usuário
      final stats = _calculateUserStats(user);

      // Obter missões em destaque
      final featuredMissions = _getFeaturedMissions();

      // Obter ações rápidas disponíveis
      final quickActions = _getQuickActions(user);

      state = state.copyWith(
        user: user,
        userStats: stats,
        featuredMissions: featuredMissions,
        quickActions: quickActions,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('✅ Dados da home atualizados');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao atualizar dados da home', error: e);
      state = state.copyWith(error: 'Erro ao carregar dados: $e');
    }
  }

  /// Calcular estatísticas do usuário
  Map<String, dynamic> _calculateUserStats(UserModel user) {
    final currentLevel = LevelCalculator.calculateLevel(user.xp);
    final levelProgress = LevelCalculator.calculateLevelProgress(user.xp);
    final xpToNext = LevelCalculator.calculateXPToNextLevel(user.xp);
    final title = LevelCalculator.getUserTitle(currentLevel);
    final overallProgress = LevelCalculator.calculateOverallProgress(user.xp);

    return {
      'level': currentLevel,
      'levelProgress': levelProgress,
      'xpToNextLevel': xpToNext,
      'title': title,
      'overallProgress': overallProgress,
      'formattedXP': LevelCalculator.formatXP(user.xp),
      'progressDescription': LevelCalculator.getProgressDescription(user.xp),
    };
  }

  /// Obter missões em destaque (3 principais)
  List<String> _getFeaturedMissions() {
    final missionsState = _ref.read(missionsProvider);
    final activeMissions = missionsState.activeMissions;

    // Priorizar missões por critérios:
    // 1. Missões próximas do prazo
    // 2. Missões com maior recompensa
    // 3. Missões não iniciadas
    activeMissions.sort((a, b) {
      // Critério 1: Tempo restante
      final aHours = a.hoursRemaining;
      final bHours = b.hoursRemaining;
      if (aHours != bHours) {
        return aHours.compareTo(bHours);
      }

      // Critério 2: Valor total da recompensa
      final aReward = a.totalRewardPoints;
      final bReward = b.totalRewardPoints;
      if (aReward != bReward) {
        return bReward.compareTo(aReward); // Maior recompensa primeiro
      }

      // Critério 3: Progresso (menos progresso primeiro)
      final aProgress = missionsState.getMissionProgress(a.id);
      final bProgress = missionsState.getMissionProgress(b.id);
      return aProgress.compareTo(bProgress);
    });

    // Retornar os IDs das 3 primeiras missões
    return activeMissions.take(3).map((m) => m.id).toList();
  }

  /// Obter ações rápidas disponíveis baseadas no estado do usuário
  Map<String, dynamic> _getQuickActions(UserModel user) {
    final actions = <String, dynamic>{};

    // Ação: Localizar Conexões (sempre disponível)
    actions['find_connections'] = {
      'title': 'Localizar Conexões',
      'description': 'Encontre pessoas com interesses similares',
      'icon': '🔍',
      'enabled': true,
      'route': '/matching',
    };

    // Ação: Completar Perfil (se perfil incompleto)
    if (_isProfileIncomplete(user)) {
      actions['complete_profile'] = {
        'title': 'Completar Perfil',
        'description': 'Adicione mais informações ao seu perfil',
        'icon': '👤',
        'enabled': true,
        'route': '/profile/edit',
      };
    }

    // Ação: Coletar Recompensas (se há pendentes)
    final hasPendingRewards = _ref.read(hasPendingRewardsProvider);
    if (hasPendingRewards) {
      final pendingCount = _ref.read(pendingRewardsProvider).length;
      actions['claim_rewards'] = {
        'title': 'Coletar Recompensas',
        'description': '$pendingCount recompensas pendentes',
        'icon': '🎁',
        'enabled': true,
        'action': 'claim_rewards',
        'badge': pendingCount,
      };
    }

    // Ação: Loja (se tem coins/gems)
    if (user.coins > 0 || user.gems > 0) {
      actions['visit_shop'] = {
        'title': 'Visitar Loja',
        'description': 'Personalize seu perfil',
        'icon': '🛒',
        'enabled': true,
        'route': '/shop',
      };
    }

    return actions;
  }

  /// Verificar se o perfil está incompleto
  bool _isProfileIncomplete(UserModel user) {
    // Verificar se falta alguma informação importante
    final hasAvatar = user.avatarId?.isNotEmpty == true;
    final hasCodinome = user.codinome?.isNotEmpty == true;
    final hasInterests = user.interesses.length >= 3;
    final hasGoal = user.relationshipGoal?.isNotEmpty == true;

    return !(hasAvatar && hasCodinome && hasInterests && hasGoal);
  }

  /// Executar ação rápida
  Future<void> executeQuickAction(String actionId) async {
    try {
      AppLogger.debug('⚡ Executando ação rápida: $actionId');

      switch (actionId) {
        case 'claim_rewards':
          await _ref.read(rewardsProvider.notifier).claimAllRewards();
          break;
        case 'refresh_missions':
          await _ref.read(missionsProvider.notifier).refresh();
          break;
        default:
          AppLogger.warning('⚠️ Ação rápida não reconhecida: $actionId');
      }

      // Atualizar dados após ação
      final user = state.user;
      if (user != null) {
        _updateUser(user);
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao executar ação rápida', error: e);
    }
  }

  /// Atualizar dashboard (refresh manual)
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Recarregar dados dos providers dependentes
      await _ref.read(missionsProvider.notifier).refresh();
      await _ref.read(rewardsProvider.notifier).refresh();

      // Atualizar dados locais
      final user = _ref.read(authProvider).user;
      if (user != null) {
        _updateUser(user);
      }

      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao atualizar dashboard', error: e);
      state = state.copyWith(isLoading: false, error: 'Erro ao atualizar: $e');
    }
  }

  /// Simular ganho de XP (para testes)
  Future<void> simulateXPGain(int amount) async {
    final user = state.user;
    if (user == null) return;

    try {
      AppLogger.debug('🧪 Simulando ganho de XP: +$amount');

      // Verificar se vai subir de nível
      final oldLevel = LevelCalculator.calculateLevel(user.xp);
      final newXP = user.xp + amount;
      final newLevel = LevelCalculator.calculateLevel(newXP);

      // Simular atualização do usuário
      final updatedUser = user.copyWith(xp: newXP, level: newLevel);
      _updateUser(updatedUser);

      // Se subiu de nível, conceder recompensas
      if (newLevel > oldLevel) {
        await _ref
            .read(rewardsProvider.notifier)
            .grantLevelUpRewards(newLevel, updatedUser);
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao simular ganho de XP', error: e);
    }
  }

  /// Limpar estado (logout)
  void clear() {
    state = const HomeState();
  }
}

// ================================================================================================
// PROVIDERS DERIVADOS
// ================================================================================================

/// Provider para estatísticas do usuário na home
final homeUserStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(homeProvider).userStats;
});

/// Provider para missões em destaque
final featuredMissionsProvider = Provider<List<String>>((ref) {
  return ref.watch(homeProvider).featuredMissions;
});

/// Provider para ações rápidas
final quickActionsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(homeProvider).quickActions;
});

/// Provider para informações de nível do usuário
final userLevelInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final homeState = ref.watch(homeProvider);

  return {
    'level': homeState.userLevel,
    'xp': homeState.userXP,
    'progress': homeState.levelProgress,
    'xpToNext': homeState.xpToNextLevel,
    'title': homeState.userTitle,
    'canLevelUp': homeState.canLevelUp,
  };
});

/// Provider para economia do usuário
final userEconomyProvider = Provider<Map<String, int>>((ref) {
  final homeState = ref.watch(homeProvider);

  return {
    'coins': homeState.userCoins,
    'gems': homeState.userGems,
    'xp': homeState.userXP,
    'level': homeState.userLevel,
  };
});

/// Provider para verificar se há atualizações na home
final homeHasUpdatesProvider = Provider<bool>((ref) {
  final homeState = ref.watch(homeProvider);
  final hasPendingRewards = ref.watch(hasPendingRewardsProvider);
  final activeMissions = ref.watch(activeMissionsProvider);

  // Considera que há atualizações se:
  // - Há recompensas pendentes
  // - Há missões ativas não completadas
  // - Dados foram atualizados recentemente (< 5 min)
  final hasRecentUpdate =
      homeState.lastUpdated != null &&
      DateTime.now().difference(homeState.lastUpdated!).inMinutes < 5;

  return hasPendingRewards || activeMissions.isNotEmpty || hasRecentUpdate;
});
