// lib/features/rankings/providers/ranking_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/rankings/services/ranking_service.dart';
import 'package:unlock/models/ranking_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

// ========== STREAM PROVIDERS ==========

/// Provider para dados de ranking baseado na query
final rankingDataProvider =
    StreamProvider.family<List<RankingEntry>, RankingQuery>((ref, query) {
      AppLogger.debug('🏅 Buscando ranking: ${query.toString()}');
      return RankingService.getRankings(query);
    });

/// Provider para ranking específico do usuário
final userRankingProvider = FutureProvider.family<UserRankingStats?, String>((
  ref,
  userId,
) {
  AppLogger.debug('🏅 Buscando ranking do usuário: $userId');
  return RankingService.getUserRankingStats(userId);
});

/// Provider para posição específica do usuário em uma categoria
final userPositionProvider = FutureProvider.family<int?, RankingQuery>((
  ref,
  query,
) {
  final user = ref.watch(authProvider.select((state) => state.user));
  if (user == null) return Future.value(null);

  AppLogger.debug('🏅 Buscando posição do usuário: ${user.uid}');
  return RankingService.getUserPosition(user.uid, query);
});

/// Provider para top 3 de uma categoria
final topThreeProvider =
    FutureProvider.family<List<RankingEntry>, RankingQuery>((ref, query) {
      final limitedQuery = RankingQuery(
        category: query.category,
        scope: query.scope,
        period: query.period,
        limit: 3,
        groupId: query.groupId,
        userIds: query.userIds,
      );

      return RankingService.getRankings(limitedQuery).first;
    });

// ========== STATE PROVIDERS ==========

/// Estado do sistema de ranking
class RankingState {
  final RankingCategory selectedCategory;
  final RankingScopeType selectedScope;
  final RankingPeriod selectedPeriod;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdate;

  const RankingState({
    this.selectedCategory = RankingCategory.xp,
    this.selectedScope = RankingScopeType.global,
    this.selectedPeriod = RankingPeriod.allTime,
    this.isLoading = false,
    this.error,
    this.lastUpdate,
  });

  RankingState copyWith({
    RankingCategory? selectedCategory,
    RankingScopeType? selectedScope,
    RankingPeriod? selectedPeriod,
    bool? isLoading,
    String? error,
    DateTime? lastUpdate,
  }) {
    return RankingState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedScope: selectedScope ?? this.selectedScope,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  /// Query atual baseada no estado
  RankingQuery get currentQuery => RankingQuery(
    category: selectedCategory,
    scope: selectedScope,
    period: selectedPeriod,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RankingState &&
        other.selectedCategory == selectedCategory &&
        other.selectedScope == selectedScope &&
        other.selectedPeriod == selectedPeriod &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
    selectedCategory,
    selectedScope,
    selectedPeriod,
    isLoading,
    error,
  );

  @override
  String toString() {
    return 'RankingState(category: ${selectedCategory.id}, scope: ${selectedScope.id}, period: ${selectedPeriod.id})';
  }
}

/// Provider principal do estado de ranking
final rankingProvider = StateNotifierProvider<RankingNotifier, RankingState>(
  (ref) => RankingNotifier(ref),
);

/// Notifier para gerenciar estado dos rankings
class RankingNotifier extends StateNotifier<RankingState> {
  final Ref _ref;
  Timer? _refreshTimer;

  RankingNotifier(this._ref) : super(const RankingState()) {
    AppLogger.info('🏅 RankingNotifier: Inicializado');
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    AppLogger.info('🧹 RankingNotifier: Disposed');
    super.dispose();
  }

  /// Iniciar refresh periódico (a cada 5 minutos)
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => refreshCurrentRankings(),
    );
  }

  /// Atualizar categoria selecionada
  void updateCategory(RankingCategory category) {
    if (state.selectedCategory == category) return;

    AppLogger.debug('🏅 Categoria atualizada: ${category.id}');
    state = state.copyWith(
      selectedCategory: category,
      lastUpdate: DateTime.now(),
    );

    // Invalidar providers relacionados
    _invalidateProviders();
  }

  /// Atualizar escopo selecionado
  void updateScope(RankingScopeType scope) {
    if (state.selectedScope == scope) return;

    AppLogger.debug('🏅 Escopo atualizado: ${scope.id}');
    state = state.copyWith(selectedScope: scope, lastUpdate: DateTime.now());

    _invalidateProviders();
  }

  /// Atualizar período selecionado
  void updatePeriod(RankingPeriod period) {
    if (state.selectedPeriod == period) return;

    AppLogger.debug('🏅 Período atualizado: ${period.id}');
    state = state.copyWith(selectedPeriod: period, lastUpdate: DateTime.now());

    _invalidateProviders();
  }

  /// Atualizar múltiplos parâmetros de uma vez
  void updateQuery({
    RankingCategory? category,
    RankingScopeType? scope,
    RankingPeriod? period,
  }) {
    bool hasChanges = false;

    if (category != null && category != state.selectedCategory)
      hasChanges = true;
    if (scope != null && scope != state.selectedScope) hasChanges = true;
    if (period != null && period != state.selectedPeriod) hasChanges = true;

    if (!hasChanges) return;

    AppLogger.debug('🏅 Query atualizada em lote');
    state = state.copyWith(
      selectedCategory: category,
      selectedScope: scope,
      selectedPeriod: period,
      lastUpdate: DateTime.now(),
    );

    _invalidateProviders();
  }

  /// Refresh manual dos rankings atuais
  Future<void> refreshCurrentRankings() async {
    if (state.isLoading) return;

    AppLogger.info('🔄 Refreshing rankings');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Invalidar providers para forçar reload
      _invalidateProviders();

      // Simular delay para UX
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(isLoading: false, lastUpdate: DateTime.now());

      AppLogger.info('✅ Rankings atualizados com sucesso');
    } catch (error) {
      AppLogger.error('❌ Erro ao atualizar rankings: $error');
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  /// Invalidar providers relacionados
  void _invalidateProviders() {
    _ref.invalidate(rankingDataProvider);
    _ref.invalidate(userPositionProvider);
    _ref.invalidate(topThreeProvider);
  }

  /// Limpar erro
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Reset para estado inicial
  void reset() {
    AppLogger.debug('🏅 Reset ranking state');
    state = const RankingState();
    _invalidateProviders();
  }
}

// ========== COMPUTED PROVIDERS ==========

/// Provider que combina dados para exibição na tela
final rankingDisplayProvider =
    Provider.family<AsyncValue<RankingDisplayData>, RankingQuery>((ref, query) {
      final rankingsAsync = ref.watch(rankingDataProvider(query));
      final userAsync = ref.watch(authProvider.select((state) => state.user));

      return rankingsAsync.when(
        data: (rankings) {
          final user = userAsync;
          final userEntry = user != null
              ? rankings.firstWhere(
                  (entry) => entry.userId == user.uid,
                  orElse: () => RankingEntry(
                    userId: user.uid,
                    username: user.username,
                    displayName: user.displayName,
                    avatar: user.avatar,
                    value: query.category.getValueFromUser({
                      'xp': user.xp,
                      'coins': user.coins,
                      'gems': user.gems,
                      'level': user.level,
                      'loginStreak': user.loginStreak,
                      'stats': {}, // TODO: Adicionar stats do user model
                    }),
                    position: rankings.length + 1,
                    lastUpdated: DateTime.now(),
                  ),
                )
              : null;

          return AsyncValue.data(
            RankingDisplayData(
              rankings: rankings,
              userEntry: userEntry,
              totalUsers: rankings.length,
              lastUpdate: DateTime.now(),
            ),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });

/// Dados combinados para exibição
class RankingDisplayData {
  final List<RankingEntry> rankings;
  final RankingEntry? userEntry;
  final int totalUsers;
  final DateTime lastUpdate;

  const RankingDisplayData({
    required this.rankings,
    required this.userEntry,
    required this.totalUsers,
    required this.lastUpdate,
  });

  /// Top 3 rankings
  List<RankingEntry> get topThree => rankings.take(3).toList();

  /// Rankings restantes (4º em diante)
  List<RankingEntry> get remainingRankings =>
      rankings.length > 3 ? rankings.skip(3).toList() : [];

  /// Posição do usuário
  int? get userPosition => userEntry?.position;

  /// Se o usuário está no top 3
  bool get userInTopThree => userPosition != null && userPosition! <= 3;
}

// ========== CACHE PROVIDERS ==========

/// Provider para cache de rankings recentes
final rankingCacheProvider = Provider<RankingCache>((ref) {
  return RankingCache();
});

/// Sistema simples de cache para rankings
class RankingCache {
  final Map<String, CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 2);

  /// Obter dados do cache
  List<RankingEntry>? get(RankingQuery query) {
    final key = _getCacheKey(query);
    final entry = _cache[key];

    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > _cacheDuration) {
      _cache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// Armazenar no cache
  void put(RankingQuery query, List<RankingEntry> data) {
    final key = _getCacheKey(query);
    _cache[key] = CacheEntry(data: data, timestamp: DateTime.now());

    // Limpar cache antigo
    _cleanOldEntries();
  }

  /// Limpar todo o cache
  void clear() {
    _cache.clear();
  }

  /// Gerar chave do cache
  String _getCacheKey(RankingQuery query) {
    return '${query.category.id}_${query.scope.id}_${query.period.id}';
  }

  /// Limpar entradas antigas
  void _cleanOldEntries() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) {
      return now.difference(entry.timestamp) > _cacheDuration;
    });
  }
}

/// Entrada do cache
class CacheEntry {
  final List<RankingEntry> data;
  final DateTime timestamp;

  const CacheEntry({required this.data, required this.timestamp});
}
